
local Gateway = require("./Gateway")
local Rest = require("./Rest")
local CommandHandler = require("./CommandHandler")
local Utils = require("./Utils")

local Client = {}
Client.__index = Client

function Client.new(options)
    local self = setmetatable({}, Client)
    self.token = options.token
    self.applicationId = options.applicationId
    
    self.gateway = Gateway.new(self.token)
    self.rest = Rest.new(self.token, self.applicationId)
    self.commands = CommandHandler.new(self.rest)
    
    self.user = nil
    self.events = {}
    
    self.gateway:on("READY", function(data)
        self.user = data.user
        print("[READY] Logged in as", data.user.username)
        self:emit("ready")
        
        task.spawn(function()
            wait(2)
            self.commands:registerAll()
        end)
    end)
    
    self.gateway:on("INTERACTION_CREATE", function(data)
        self.commands:handleInteraction(data)
    end)
    
    self.gateway:on("MESSAGE_CREATE", function(data)
        if data.author.bot then return end
        self:emit("messageCreate", data)
    end)
    
    return self
end

function Client:on(eventName, callback)
    if not self.events[eventName] then
        self.events[eventName] = {}
    end
    table.insert(self.events[eventName], callback)
end

function Client:emit(eventName, ...)
    if self.events[eventName] then
        for _, callback in ipairs(self.events[eventName]) do
            task.spawn(callback, ...)
        end
    end
end

function Client:login()
    self.gateway:connect()
end

return Client
