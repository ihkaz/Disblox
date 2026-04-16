local CommandHandler = require("./CommandHandler")
local Gateway = require("./Gateway")
local Rest = require("./Rest")
local Runtime = require("./Runtime")
local Utils = require("./Utils")

local Client = {}
Client.__index = Client

local function userTag(user)
    if not user then
        return "unknown"
    end

    if user.discriminator and user.discriminator ~= "0" then
        return ("%s#%s"):format(tostring(user.username), tostring(user.discriminator))
    end

    return tostring(user.username)
end

function Client.new(options)
    Utils.assertTable(options, "options")
    Utils.assertNonEmptyString(options.token, "options.token")
    Utils.assertNonEmptyString(options.applicationId, "options.applicationId")

    if options.intents ~= nil then
        Utils.assertNumber(options.intents, "options.intents")
    end

    local self = setmetatable({}, Client)
    self.token = options.token
    self.applicationId = options.applicationId
    self.intents = options.intents
    self.events = {}
    self.user = nil
    self.ready = false
    self.rest = Rest.new(options.token, options.applicationId)
    self.commands = CommandHandler.new(self.rest)
    self.gateway = Gateway.new(options.token, options.intents)

    self.gateway:on("READY", function(data)
        self.ready = true
        self.user = data.user
        print(("[CLIENT] Ready as %s (%s)"):format(userTag(self.user), tostring(self.user and self.user.id)))
        self:emit("ready", data)

        Runtime.spawn(function()
            Runtime.wait(2)
            self.commands:registerAll()
        end)
    end)

    self.gateway:on("RESUMED", function(data)
        self.ready = true
        self:emit("resumed", data)
    end)

    self.gateway:on("INTERACTION_CREATE", function(data)
        self:emit("interactionCreate", data)
        self.commands:handleInteraction(data)
    end)

    self.gateway:on("MESSAGE_CREATE", function(data)
        if data.author and data.author.bot then
            return
        end

        self:emit("messageCreate", data)
    end)

    self.gateway:on("disconnect", function(code, reason)
        self.ready = false
        self:emit("disconnect", code, reason)
    end)

    self.gateway:on("reconnect", function()
        self.ready = false
        self:emit("reconnect")
    end)

    self.gateway:on("error", function(err)
        self:emit("error", err)
    end)

    return self
end

function Client:on(eventName, callback)
    Utils.assertNonEmptyString(eventName, "eventName")
    Utils.assertFunction(callback, "callback")

    if not self.events[eventName] then
        self.events[eventName] = {}
    end

    table.insert(self.events[eventName], callback)
    return self
end

function Client:emit(eventName, ...)
    Utils.assertNonEmptyString(eventName, "eventName")

    local callbacks = self.events[eventName]
    if not callbacks then
        return
    end

    local args = { ... }
    local argCount = select("#", ...)

    for _, callback in ipairs(callbacks) do
        Runtime.spawn(function()
            callback(Runtime.unpack(args, 1, argCount))
        end)
    end
end

function Client:login()
    self.gateway:connect()
    return self
end

function Client:destroy()
    self.gateway:close()
    self.ready = false
end

return Client
