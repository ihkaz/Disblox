local __BUNDLER_FILES__={cache={}::any}do do local function __modImpl()

local Utils = {}

local EPHEMERAL_MESSAGE_FLAG = 64
local IS_COMPONENTS_V2_MESSAGE_FLAG = 32768

local function getEnvironment()
    local success, environment = pcall(function()
        return getfenv(0)
    end)

    if success and type(environment) == "table" then
        return environment
    end

    return _G
end

local function getHttpService()
    local environment = getEnvironment()
    local gameInstance = environment.game

    if not gameInstance or not gameInstance.GetService then
        error("HttpService is unavailable: global game:GetService is missing", 3)
    end

    return gameInstance:GetService("HttpService")
end

function Utils.assertType(value, expectedType, name)
    if type(value) ~= expectedType then
        error(("%s must be a %s, got %s"):format(name, expectedType, type(value)), 3)
    end
end

function Utils.assertTable(value, name)
    Utils.assertType(value, "table", name)
end

function Utils.assertFunction(value, name)
    Utils.assertType(value, "function", name)
end

function Utils.assertNumber(value, name)
    Utils.assertType(value, "number", name)
end

function Utils.assertBoolean(value, name)
    Utils.assertType(value, "boolean", name)
end

function Utils.assertNonEmptyString(value, name)
    Utils.assertType(value, "string", name)

    if value == "" then
        error(("%s must not be empty"):format(name), 3)
    end
end

function Utils.deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}

    for key, item in pairs(value) do
        result[key] = Utils.deepCopy(item)
    end

    return result
end

function Utils.arrayCopy(values)
    local result = {}

    for index, value in ipairs(values) do
        result[index] = Utils.deepCopy(value)
    end

    return result
end

function Utils.jsonEncode(data)
    local success, result = pcall(function()
        return getHttpService():JSONEncode(data)
    end)

    if not success then
        error(("Failed to encode JSON: %s"):format(tostring(result)), 2)
    end

    return result
end

function Utils.jsonDecode(value)
    Utils.assertNonEmptyString(value, "value")

    local success, result = pcall(function()
        return getHttpService():JSONDecode(value)
    end)

    if not success then
        error(("Failed to decode JSON: %s"):format(tostring(result)), 2)
    end

    return result
end

function Utils.hasFlag(flags, flag)
    Utils.assertNumber(flags, "flags")
    Utils.assertNumber(flag, "flag")

    return flags % (flag * 2) >= flag
end

function Utils.addFlag(flags, flag)
    Utils.assertNumber(flags, "flags")
    Utils.assertNumber(flag, "flag")

    if Utils.hasFlag(flags, flag) then
        return flags
    end

    return flags + flag
end

function Utils.resolveMessageFlags(flags, ephemeral)
    local resolvedFlags = flags or 0
    Utils.assertNumber(resolvedFlags, "flags")

    if ephemeral then
        resolvedFlags = Utils.addFlag(resolvedFlags, EPHEMERAL_MESSAGE_FLAG)
    end

    if resolvedFlags == 0 then
        return nil
    end

    return resolvedFlags
end

function Utils.toJSONValue(value, name)
    if type(value) == "table" and value.toJSON then
        Utils.assertFunction(value.toJSON, name .. ".toJSON")
        return value:toJSON()
    end

    return value
end

function Utils.normalizeMessageOptions(options)
    if type(options) == "string" then
        return {
            content = options,
            ephemeral = false,
            embeds = nil,
            components = nil,
            flags = nil
        }
    end

    Utils.assertTable(options, "options")
    local data = Utils.toJSONValue(options, "options")
    Utils.assertTable(data, "options")

    if data.content or data.embeds or data.components or data.ephemeral ~= nil or data.flags ~= nil then
        return {
            content = data.content,
            ephemeral = data.ephemeral == true,
            embeds = data.embeds,
            components = data.components,
            flags = data.flags
        }
    end

    return {
        content = nil,
        ephemeral = false,
        embeds = { data },
        components = nil,
        flags = nil
    }
end

function Utils.normalizeEditOptions(options)
    if type(options) == "string" then
        return {
            content = options,
            embeds = nil,
            components = nil,
            flags = nil
        }
    end

    Utils.assertTable(options, "options")
    local data = Utils.toJSONValue(options, "options")
    Utils.assertTable(data, "options")

    if data.content or data.embeds or data.components or data.flags ~= nil then
        return {
            content = data.content,
            embeds = data.embeds,
            components = data.components,
            flags = data.flags
        }
    end

    return {
        content = nil,
        embeds = { data },
        components = nil,
        flags = nil
    }
end

function Utils.makeEmbed(options)
    Utils.assertTable(options, "options")

    return {
        title = options.title,
        description = options.description,
        color = options.color or Utils.Colors.Blurple,
        fields = options.fields or {},
        thumbnail = options.thumbnail,
        image = options.image,
        footer = options.footer,
        author = options.author,
        timestamp = options.timestamp or os.date("!%Y-%m-%dT%H:%M:%S"),
        url = options.url
    }
end

function Utils.makeButton(options)
    Utils.assertTable(options, "options")

    local button = {
        type = 2,
        style = options.style or Utils.ButtonStyle.Primary,
        label = options.label,
        custom_id = options.customId,
        emoji = options.emoji,
        url = options.url,
        disabled = options.disabled or false
    }

    if button.url then
        button.custom_id = nil
        button.style = Utils.ButtonStyle.Link
    end

    return button
end

function Utils.makeActionRow(components)
    Utils.assertTable(components, "components")

    return {
        type = 1,
        components = components
    }
end

function Utils.snowflakeToTimestamp(snowflake)
    local numericSnowflake = tonumber(snowflake)

    if not numericSnowflake then
        error(("snowflake must be numeric, got %s"):format(tostring(snowflake)), 2)
    end

    return math.floor(numericSnowflake / 4194304 + 1420070400000) / 1000
end

Utils.ButtonStyle = {
    Primary = 1,
    Secondary = 2,
    Success = 3,
    Danger = 4,
    Link = 5
}

Utils.Colors = {
    Blurple = 0x5865F2,
    Green = 0x57F287,
    Yellow = 0xFEE75C,
    Fuchsia = 0xEB459E,
    Red = 0xED4245,
    White = 0xFFFFFF,
    Black = 0x000000,
    Orange = 0xFF8C00,
    Purple = 0x9B59B6,
    Pink = 0xFF69B4,
    Gold = 0xFFD700
}

Utils.MessageFlags = {
    Ephemeral = EPHEMERAL_MESSAGE_FLAG,
    IsComponentsV2 = IS_COMPONENTS_V2_MESSAGE_FLAG
}

return Utils
end function __BUNDLER_FILES__.a():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.a if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.a=v end return v.c end end do local function __modImpl()


local Utils = __BUNDLER_FILES__.a()

local Runtime = {}

local function getEnvironment()
    local success, environment = pcall(function()
        return getfenv(0)
    end)

    if success and type(environment) == "table" then
        return environment
    end

    return _G
end

local function getValue(container, key)
    if type(container) ~= "table" and type(container) ~= "userdata" then
        return nil
    end

    local success, value = pcall(function()
        return container[key]
    end)

    if success then
        return value
    end

    return nil
end

local function callMethod(target, methodName, ...)
    local method = getValue(target, methodName)

    if type(method) ~= "function" then
        error(("Method %s is not available"):format(methodName), 3)
    end

    return method(target, ...)
end

local function assertObject(value, name)
    local valueType = type(value)

    if valueType ~= "table" and valueType ~= "userdata" then
        error(("%s must be a table or userdata, got %s"):format(name, valueType), 3)
    end
end

function Runtime.resolveRequest()
    local environment = getEnvironment()
    local http = getValue(environment, "http")
    local syn = getValue(environment, "syn")

    local candidates = {
        getValue(environment, "request"),
        getValue(environment, "http_request"),
        getValue(http, "request"),
        getValue(syn, "request")
    }

    for _, candidate in ipairs(candidates) do
        if type(candidate) == "function" then
            return candidate
        end
    end

    error("No executor HTTP request function found. Expected request, http_request, http.request, or syn.request.", 2)
end

function Runtime.resolveWebSocketConnect()
    local environment = getEnvironment()
    local syn = getValue(environment, "syn")

    local websocketCandidates = {
        getValue(environment, "WebSocket"),
        getValue(environment, "Websocket"),
        getValue(environment, "websocket"),
        getValue(syn, "websocket")
    }

    for _, websocket in ipairs(websocketCandidates) do
        local connect = getValue(websocket, "connect")

        if type(connect) == "function" then
            return connect
        end
    end

    error("No executor WebSocket connector found. Expected WebSocket.connect.", 2)
end

function Runtime.connectEvent(target, eventName, callback)
    assertObject(target, "target")
    Utils.assertNonEmptyString(eventName, "eventName")
    Utils.assertFunction(callback, "callback")

    local event = getValue(target, eventName)
    local connect = getValue(event, "Connect")

    if type(connect) == "function" then
        connect(event, callback)
        return
    end

    local success = pcall(function()
        target[eventName] = callback
    end)

    if success then
        return
    end

    error(("WebSocket event %s is not connectable. Expected %s:Connect(callback)."):format(eventName, eventName), 2)
end

function Runtime.sendWebSocket(socket, payload)
    assertObject(socket, "socket")
    Utils.assertNonEmptyString(payload, "payload")

    local send = getValue(socket, "Send")

    if type(send) == "function" then
        send(socket, payload)
        return
    end

    callMethod(socket, "send", payload)
end

function Runtime.closeWebSocket(socket)
    assertObject(socket, "socket")

    local close = getValue(socket, "Close")

    if type(close) == "function" then
        close(socket)
        return
    end

    callMethod(socket, "close")
end

function Runtime.spawn(callback)
    Utils.assertFunction(callback, "callback")

    local environment = getEnvironment()
    local taskLibrary = getValue(environment, "task")
    local spawn = getValue(taskLibrary, "spawn") or getValue(environment, "spawn")

    if type(spawn) ~= "function" then
        error("No task spawn function found. Expected task.spawn or spawn.", 2)
    end

    return spawn(callback)
end

function Runtime.cancel(thread)
    local environment = getEnvironment()
    local taskLibrary = getValue(environment, "task")
    local cancel = getValue(taskLibrary, "cancel")

    if type(cancel) == "function" and thread ~= nil then
        cancel(thread)
    end
end

function Runtime.wait(seconds)
    Utils.assertNumber(seconds, "seconds")

    local environment = getEnvironment()
    local taskLibrary = getValue(environment, "task")
    local taskWait = getValue(taskLibrary, "wait")
    local globalWait = getValue(environment, "wait")

    if type(taskWait) == "function" then
        return taskWait(seconds)
    end

    if type(globalWait) == "function" then
        return globalWait(seconds)
    end

    error("No wait function found. Expected task.wait or wait.", 2)
end

function Runtime.warn(message, fields)
    Utils.assertNonEmptyString(message, "message")

    if fields ~= nil then
        Utils.assertTable(fields, "fields")
    end

    local environment = getEnvironment()
    local warnFunction = getValue(environment, "warn")

    if type(warnFunction) == "function" then
        warnFunction(message, fields)
        return
    end

    print(message, fields)
end

return Runtime
end function __BUNDLER_FILES__.b():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.b if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.b=v end return v.c end end do local function __modImpl()
local Runtime = __BUNDLER_FILES__.b()
local Utils = __BUNDLER_FILES__.a()

local CommandHandler = {}
CommandHandler.__index = CommandHandler

local INTERACTION_APPLICATION_COMMAND = 2
local INTERACTION_MESSAGE_COMPONENT = 3
local OPTION_USER = 6

local function commandPayload(options)
    if options.data then
        local payload = Utils.toJSONValue(options.data, "options.data")
        Utils.assertTable(payload, "options.data")
        return payload
    end

    return {
        type = 1,
        name = options.name,
        description = options.description,
        options = options.options
    }
end

local function interactionUser(interaction)
    if interaction.member and interaction.member.user then
        return interaction.member.user
    end

    return interaction.user
end

local function findOption(interaction, name)
    if not interaction.data or not interaction.data.options then
        return nil
    end

    for _, option in ipairs(interaction.data.options) do
        if option.name == name then
            return option
        end
    end

    return nil
end

local function resolvedUser(interaction, option)
    if not option or option.type ~= OPTION_USER then
        return nil
    end

    if not interaction.data.resolved or not interaction.data.resolved.users then
        return nil
    end

    return interaction.data.resolved.users[option.value]
end

local function resolvedMember(interaction, option)
    if not option or option.type ~= OPTION_USER then
        return nil
    end

    if not interaction.data.resolved or not interaction.data.resolved.members then
        return nil
    end

    return interaction.data.resolved.members[option.value]
end

local function slashInteraction(self, interaction)
    return {
        id = interaction.id,
        token = interaction.token,
        type = interaction.type,
        commandName = interaction.data and interaction.data.name or nil,
        user = interactionUser(interaction),
        member = interaction.member,
        guildId = interaction.guild_id,
        channelId = interaction.channel_id,
        data = interaction.data,

        reply = function(options)
            return self.rest:replyInteraction(interaction.id, interaction.token, options)
        end,

        deferReply = function(ephemeral)
            return self.rest:deferReply(interaction.id, interaction.token, ephemeral == true)
        end,

        defer = function(ephemeral)
            return self.rest:deferReply(interaction.id, interaction.token, ephemeral == true)
        end,

        editReply = function(options)
            return self.rest:editInteractionResponse(interaction.token, options)
        end,

        getOption = function(name)
            Utils.assertNonEmptyString(name, "name")

            local option = findOption(interaction, name)
            return option and option.value or nil
        end,

        getUser = function(name)
            Utils.assertNonEmptyString(name, "name")
            return resolvedUser(interaction, findOption(interaction, name))
        end,

        getMember = function(name)
            Utils.assertNonEmptyString(name, "name")
            return resolvedMember(interaction, findOption(interaction, name))
        end
    }
end

local function componentInteraction(self, interaction)
    return {
        id = interaction.id,
        token = interaction.token,
        type = interaction.type,
        customId = interaction.data and interaction.data.custom_id or nil,
        user = interactionUser(interaction),
        member = interaction.member,
        guildId = interaction.guild_id,
        channelId = interaction.channel_id,
        message = interaction.message,
        data = interaction.data,

        reply = function(options)
            return self.rest:replyInteraction(interaction.id, interaction.token, options)
        end,

        update = function(options)
            return self.rest:updateInteraction(interaction.id, interaction.token, options)
        end,

        deferUpdate = function()
            return self.rest:deferUpdate(interaction.id, interaction.token)
        end
    }
end

function CommandHandler.new(rest)
    Utils.assertTable(rest, "rest")

    local self = setmetatable({}, CommandHandler)
    self.rest = rest
    self.commands = {}
    self.buttons = {}
    return self
end

function CommandHandler:registerCommand(options)
    Utils.assertTable(options, "options")
    Utils.assertFunction(options.execute, "options.execute")

    local payload = commandPayload(options)
    Utils.assertNonEmptyString(payload.name, "command.name")
    Utils.assertNonEmptyString(payload.description, "command.description")

    self.commands[payload.name] = {
        data = payload,
        execute = options.execute
    }

    print(("[COMMAND] Loaded /%s"):format(payload.name))
    return self
end

function CommandHandler:registerButton(customId, execute)
    Utils.assertNonEmptyString(customId, "customId")
    Utils.assertFunction(execute, "execute")

    self.buttons[customId] = execute
    print(("[BUTTON] Loaded %s"):format(customId))
    return self
end

function CommandHandler:registerAll()
    local payloads = {}

    for _, command in pairs(self.commands) do
        table.insert(payloads, command.data)
    end

    self.rest:registerCommands(payloads)
    print(("[COMMANDS] Registered %d command(s)"):format(#payloads))
end

function CommandHandler:handleInteraction(interaction)
    Utils.assertTable(interaction, "interaction")

    if interaction.type == INTERACTION_APPLICATION_COMMAND then
        self:handleCommand(interaction)
    elseif interaction.type == INTERACTION_MESSAGE_COMPONENT then
        self:handleComponent(interaction)
    end
end

function CommandHandler:handleCommand(interaction)
    Utils.assertTable(interaction.data, "interaction.data")

    local name = interaction.data.name
    local command = self.commands[name]

    if not command then
        Runtime.warn(("[COMMAND] No handler for /%s"):format(tostring(name)))
        return
    end

    local wrappedInteraction = slashInteraction(self, interaction)
    local success, err = pcall(function()
        command.execute(wrappedInteraction)
    end)

    if success then
        return
    end

    Runtime.warn(("[COMMAND] /%s failed: %s"):format(tostring(name), tostring(err)))

    pcall(function()
        wrappedInteraction.reply({
            content = "Command failed.",
            ephemeral = true
        })
    end)
end

function CommandHandler:handleComponent(interaction)
    Utils.assertTable(interaction.data, "interaction.data")
    Utils.assertNonEmptyString(interaction.data.custom_id, "interaction.data.custom_id")

    local customId = interaction.data.custom_id
    local execute = self.buttons[customId]

    if not execute then
        Runtime.warn(("[BUTTON] No handler for %s"):format(customId))
        return
    end

    local success, err = pcall(function()
        execute(componentInteraction(self, interaction))
    end)

    if not success then
        Runtime.warn(("[BUTTON] %s failed: %s"):format(customId, tostring(err)))
    end
end

return CommandHandler
end function __BUNDLER_FILES__.c():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.c if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.c=v end return v.c end end do local function __modImpl()
local Runtime = __BUNDLER_FILES__.b()
local Utils = __BUNDLER_FILES__.a()

local Gateway = {}
Gateway.__index = Gateway

local GATEWAY_URL = "wss://gateway.discord.gg/?v=10&encoding=json"
local DEFAULT_INTENTS = 1

local OP_DISPATCH = 0
local OP_HEARTBEAT = 1
local OP_IDENTIFY = 2
local OP_RESUME = 6
local OP_RECONNECT = 7
local OP_INVALID_SESSION = 9
local OP_HELLO = 10
local OP_HEARTBEAT_ACK = 11

local FATAL_CLOSE_CODES = {
    [4004] = true,
    [4010] = true,
    [4011] = true,
    [4013] = true,
    [4014] = true
}

local function log(message)
    print(("[GATEWAY] %s"):format(message))
end

local function warnLog(message)
    Runtime.warn(("[GATEWAY] %s"):format(message))
end

local function gatewayUrl(url)
    Utils.assertNonEmptyString(url, "url")

    if string.find(url, "?", 1, true) then
        return url
    end

    return url .. "?v=10&encoding=json"
end

local function shouldReconnect(code)
    if code == nil then
        return true
    end

    return FATAL_CLOSE_CODES[code] ~= true
end

function Gateway.new(token, intents)
    Utils.assertNonEmptyString(token, "token")

    if intents ~= nil then
        Utils.assertNumber(intents, "intents")
    end

    local self = setmetatable({}, Gateway)
    self.token = token
    self.intents = intents or DEFAULT_INTENTS
    self.ws = nil
    self.state = "idle"
    self.events = {}
    self.heartbeatInterval = nil
    self.heartbeatThread = nil
    self.lastSequence = nil
    self.lastHeartbeatAcked = true
    self.sessionId = nil
    self.resumeGatewayUrl = nil
    self.resumeOnHello = false
    self.intentionalClose = false
    return self
end

function Gateway:on(eventName, callback)
    Utils.assertNonEmptyString(eventName, "eventName")
    Utils.assertFunction(callback, "callback")

    if not self.events[eventName] then
        self.events[eventName] = {}
    end

    table.insert(self.events[eventName], callback)
end

function Gateway:emit(eventName, ...)
    Utils.assertNonEmptyString(eventName, "eventName")

    local callbacks = self.events[eventName]
    if not callbacks then
        return
    end

    local args = { ... }
    local argCount = select("#", ...)

    for _, callback in ipairs(callbacks) do
        Runtime.spawn(function()
            callback(table.unpack(args, 1, argCount))
        end)
    end
end

function Gateway:send(op, data)
    Utils.assertNumber(op, "op")

    if not self.ws then
        error(("Cannot send Discord Gateway opcode %s before websocket is open."):format(tostring(op)), 2)
    end

    Runtime.sendWebSocket(self.ws, Utils.jsonEncode({
        op = op,
        d = data
    }))
end

function Gateway:identify()
    log("Sending Identify")

    self:send(OP_IDENTIFY, {
        token = self.token,
        intents = self.intents,
        properties = {
            os = "windows",
            browser = "disblox",
            device = "disblox"
        }
    })
end

function Gateway:resume()
    Utils.assertNonEmptyString(self.sessionId, "sessionId")

    log("Sending Resume")

    self:send(OP_RESUME, {
        token = self.token,
        session_id = self.sessionId,
        seq = self.lastSequence
    })
end

function Gateway:heartbeat()
    self.lastHeartbeatAcked = false
    self:send(OP_HEARTBEAT, self.lastSequence)
end

function Gateway:stopHeartbeat()
    Runtime.cancel(self.heartbeatThread)
    self.heartbeatThread = nil
end

function Gateway:startHeartbeat()
    self:stopHeartbeat()

    self.heartbeatThread = Runtime.spawn(function()
        Runtime.wait((self.heartbeatInterval / 1000) * math.random())

        while self.ws and self.heartbeatInterval do
            if not self.lastHeartbeatAcked then
                warnLog("Heartbeat ACK missing; reconnecting")
                self:reconnect(true)
                return
            end

            self:heartbeat()
            Runtime.wait(self.heartbeatInterval / 1000)
        end
    end)
end

function Gateway:handleHello(data)
    Utils.assertTable(data, "hello.d")
    Utils.assertNumber(data.heartbeat_interval, "hello.d.heartbeat_interval")

    self.heartbeatInterval = data.heartbeat_interval
    self.lastHeartbeatAcked = true
    log(("Hello received; heartbeat=%sms"):format(tostring(self.heartbeatInterval)))
    self:startHeartbeat()

    if self.resumeOnHello then
        self:resume()
        return
    end

    self:identify()
end

function Gateway:handleDispatch(eventName, data)
    if eventName == "READY" then
        self.state = "ready"
        self.sessionId = data.session_id
        self.resumeGatewayUrl = data.resume_gateway_url
        log("READY received")
    elseif eventName == "RESUMED" then
        self.state = "ready"
        log("RESUMED received")
    end

    self:emit(eventName, data)
end

function Gateway:handlePayload(payload)
    Utils.assertTable(payload, "payload")
    Utils.assertNumber(payload.op, "payload.op")

    if payload.s ~= nil then
        self.lastSequence = payload.s
    end

    log(("op=%s event=%s seq=%s"):format(
        tostring(payload.op),
        tostring(payload.t),
        tostring(payload.s)
    ))

    if payload.op == OP_HELLO then
        self:handleHello(payload.d)
    elseif payload.op == OP_HEARTBEAT then
        self:heartbeat()
    elseif payload.op == OP_HEARTBEAT_ACK then
        self.lastHeartbeatAcked = true
    elseif payload.op == OP_DISPATCH then
        self:handleDispatch(payload.t, payload.d)
    elseif payload.op == OP_RECONNECT then
        warnLog("Discord requested reconnect")
        self:reconnect(true)
    elseif payload.op == OP_INVALID_SESSION then
        warnLog(("Invalid session resumable=%s"):format(tostring(payload.d)))
        Runtime.wait(5)
        self:reconnect(payload.d == true)
    end
end

function Gateway:handleMessage(message)
    Utils.assertNonEmptyString(message, "message")

    local payload = Utils.jsonDecode(message)
    self:handlePayload(payload)
end

function Gateway:connectSocket(url, resume)
    Utils.assertNonEmptyString(url, "url")
    Utils.assertBoolean(resume, "resume")

    local connect = Runtime.resolveWebSocketConnect()
    self.state = "connecting"
    self.resumeOnHello = resume
    self.intentionalClose = false

    log(("Connecting %s"):format(gatewayUrl(url)))
    self.ws = connect(gatewayUrl(url))

    local socket = self.ws

    Runtime.connectEvent(socket, "OnMessage", function(message)
        if self.ws ~= socket then
            return
        end

        local success, err = pcall(function()
            self:handleMessage(message)
        end)

        if not success then
            warnLog(("Message handler failed: %s"):format(tostring(err)))
            self:emit("error", err)
        end
    end)

    Runtime.connectEvent(socket, "OnClose", function(code, reason)
        if self.ws ~= socket then
            return
        end

        self:handleClose(code, reason)
    end)

    log("Socket opened")
end

function Gateway:closeCurrentSocket()
    if not self.ws then
        return
    end

    local socket = self.ws
    self.ws = nil
    self:stopHeartbeat()

    local success, err = pcall(function()
        Runtime.closeWebSocket(socket)
    end)

    if not success then
        warnLog(("Socket close failed: %s"):format(tostring(err)))
    end
end

function Gateway:reconnect(resume)
    Utils.assertBoolean(resume, "resume")

    self.state = "reconnecting"
    self:emit("reconnect")
    self:closeCurrentSocket()
    self.heartbeatInterval = nil
    self.lastHeartbeatAcked = true

    if resume and self.sessionId and self.resumeGatewayUrl then
        self:connectSocket(self.resumeGatewayUrl, true)
        return
    end

    self.sessionId = nil
    self.resumeGatewayUrl = nil
    self.lastSequence = nil
    self:connectSocket(GATEWAY_URL, false)
end

function Gateway:handleClose(code, reason)
    warnLog(("Disconnected code=%s reason=%s"):format(tostring(code), tostring(reason)))
    self:stopHeartbeat()
    self.ws = nil
    self.heartbeatInterval = nil
    self.lastHeartbeatAcked = true
    self.state = "disconnected"
    self:emit("disconnect", code, reason)

    if self.intentionalClose or not shouldReconnect(code) then
        return
    end

    Runtime.spawn(function()
        Runtime.wait(5)
        self:reconnect(self.sessionId ~= nil)
    end)
end

function Gateway:connect()
    if self.ws then
        error("Gateway is already connected. Create another Client or call close before login again.", 2)
    end

    self:connectSocket(GATEWAY_URL, false)
end

function Gateway:close()
    self.intentionalClose = true
    self.state = "closed"
    self:closeCurrentSocket()
end

return Gateway
end function __BUNDLER_FILES__.d():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.d if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.d=v end return v.c end end do local function __modImpl()
local Runtime = __BUNDLER_FILES__.b()
local Utils = __BUNDLER_FILES__.a()

local Rest = {}
Rest.__index = Rest

local API_URL = "https://discord.com/api/v10"

local function encodeBody(body)
    if body == nil then
        return nil
    end

    return Utils.jsonEncode(body)
end

local function decodeBody(body)
    if body == nil or body == "" then
        return nil
    end

    return Utils.jsonDecode(body)
end

local function isSuccess(response)
    return response and response.StatusCode >= 200 and response.StatusCode < 300
end

local function isRetryable(response, requestError)
    if requestError then
        return true
    end

    if not response then
        return true
    end

    return response.StatusCode == 429 or response.StatusCode >= 500
end

local function restError(method, endpoint, response, requestError)
    if requestError then
        return ("Discord REST failed: method=%s endpoint=%s requestError=%s"):format(
            method,
            endpoint,
            tostring(requestError)
        )
    end

    return ("Discord REST failed: method=%s endpoint=%s status=%s body=%s"):format(
        method,
        endpoint,
        tostring(response and response.StatusCode),
        tostring(response and response.Body)
    )
end

function Rest.new(token, applicationId)
    Utils.assertNonEmptyString(token, "token")
    Utils.assertNonEmptyString(applicationId, "applicationId")

    local self = setmetatable({}, Rest)
    self.token = token
    self.applicationId = applicationId
    self.request = Runtime.resolveRequest()
    self.maxRetries = 3
    return self
end

function Rest:requestJson(method, endpoint, body)
    Utils.assertNonEmptyString(method, "method")
    Utils.assertNonEmptyString(endpoint, "endpoint")

    local lastResponse = nil
    local lastError = nil

    for attempt = 1, self.maxRetries do
        local requestBody = encodeBody(body)
        local success, response = pcall(function()
            return self.request({
                Url = API_URL .. endpoint,
                Method = method,
                Headers = {
                    ["Authorization"] = "Bot " .. self.token,
                    ["Content-Type"] = "application/json"
                },
                Body = requestBody
            })
        end)

        if success and isSuccess(response) then
            return decodeBody(response.Body)
        end

        if success then
            lastResponse = response
            lastError = nil
        else
            lastResponse = nil
            lastError = response
        end

        if attempt == self.maxRetries or not isRetryable(lastResponse, lastError) then
            error(restError(method, endpoint, lastResponse, lastError), 2)
        end

        Runtime.warn("[REST] retry", {
            method = method,
            endpoint = endpoint,
            attempt = attempt,
            statusCode = lastResponse and lastResponse.StatusCode or nil,
            error = lastError and tostring(lastError) or nil
        })

        Runtime.wait(attempt)
    end

    error(restError(method, endpoint, lastResponse, lastError), 2)
end

function Rest:registerCommands(commands)
    Utils.assertTable(commands, "commands")
    return self:requestJson("PUT", "/applications/" .. self.applicationId .. "/commands", commands)
end

function Rest:sendMessage(channelId, options, extraOptions)
    Utils.assertNonEmptyString(channelId, "channelId")

    local messageOptions = options

    if extraOptions ~= nil then
        Utils.assertTable(extraOptions, "extraOptions")
        messageOptions = Utils.deepCopy(extraOptions)
        messageOptions.content = options
    end

    local message = Utils.normalizeMessageOptions(messageOptions)

    return self:requestJson("POST", "/channels/" .. channelId .. "/messages", {
        content = message.content,
        embeds = message.embeds,
        components = message.components,
        flags = Utils.resolveMessageFlags(message.flags, message.ephemeral)
    })
end

function Rest:editMessage(channelId, messageId, options)
    Utils.assertNonEmptyString(channelId, "channelId")
    Utils.assertNonEmptyString(messageId, "messageId")

    local message = Utils.normalizeEditOptions(options)

    return self:requestJson("PATCH", "/channels/" .. channelId .. "/messages/" .. messageId, {
        content = message.content,
        embeds = message.embeds,
        components = message.components,
        flags = message.flags
    })
end

function Rest:deleteMessage(channelId, messageId)
    Utils.assertNonEmptyString(channelId, "channelId")
    Utils.assertNonEmptyString(messageId, "messageId")

    return self:requestJson("DELETE", "/channels/" .. channelId .. "/messages/" .. messageId)
end

function Rest:createReaction(channelId, messageId, emoji)
    Utils.assertNonEmptyString(channelId, "channelId")
    Utils.assertNonEmptyString(messageId, "messageId")
    Utils.assertNonEmptyString(emoji, "emoji")

    return self:requestJson("PUT", "/channels/" .. channelId .. "/messages/" .. messageId .. "/reactions/" .. emoji .. "/@me")
end

function Rest:replyInteraction(interactionId, interactionToken, options)
    Utils.assertNonEmptyString(interactionId, "interactionId")
    Utils.assertNonEmptyString(interactionToken, "interactionToken")

    local message = Utils.normalizeMessageOptions(options)

    return self:requestJson("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", {
        type = 4,
        data = {
            content = message.content,
            embeds = message.embeds,
            components = message.components,
            flags = Utils.resolveMessageFlags(message.flags, message.ephemeral)
        }
    })
end

function Rest:deferReply(interactionId, interactionToken, ephemeral)
    Utils.assertNonEmptyString(interactionId, "interactionId")
    Utils.assertNonEmptyString(interactionToken, "interactionToken")
    Utils.assertBoolean(ephemeral, "ephemeral")

    return self:requestJson("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", {
        type = 5,
        data = {
            flags = Utils.resolveMessageFlags(nil, ephemeral)
        }
    })
end

function Rest:editInteractionResponse(interactionToken, options)
    Utils.assertNonEmptyString(interactionToken, "interactionToken")

    local message = Utils.normalizeEditOptions(options)

    return self:requestJson("PATCH", "/webhooks/" .. self.applicationId .. "/" .. interactionToken .. "/messages/@original", {
        content = message.content,
        embeds = message.embeds,
        components = message.components,
        flags = message.flags
    })
end

function Rest:updateInteraction(interactionId, interactionToken, options)
    Utils.assertNonEmptyString(interactionId, "interactionId")
    Utils.assertNonEmptyString(interactionToken, "interactionToken")

    local message = Utils.normalizeEditOptions(options)

    return self:requestJson("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", {
        type = 7,
        data = {
            content = message.content,
            embeds = message.embeds,
            components = message.components,
            flags = message.flags
        }
    })
end

function Rest:deferUpdate(interactionId, interactionToken)
    Utils.assertNonEmptyString(interactionId, "interactionId")
    Utils.assertNonEmptyString(interactionToken, "interactionToken")

    return self:requestJson("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", {
        type = 6
    })
end

return Rest
end function __BUNDLER_FILES__.e():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.e if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.e=v end return v.c end end do local function __modImpl()
local CommandHandler = __BUNDLER_FILES__.c()
local Gateway = __BUNDLER_FILES__.d()
local Rest = __BUNDLER_FILES__.e()
local Runtime = __BUNDLER_FILES__.b()
local Utils = __BUNDLER_FILES__.a()

local Client = {}
Client.__index = Client

local function getUserTag(user)
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
    self.user = nil
    self.ready = false
    self.events = {}
    self.rest = Rest.new(options.token, options.applicationId)
    self.commands = CommandHandler.new(self.rest)
    self.gateway = Gateway.new(options.token, options.intents)

    self.gateway:on("READY", function(data)
        self.ready = true
        self.user = data.user
        print(("[CLIENT] Ready as %s (%s)"):format(getUserTag(self.user), tostring(self.user and self.user.id)))
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
            callback(table.unpack(args, 1, argCount))
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
end function __BUNDLER_FILES__.f():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.f if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.f=v end return v.c end end do local function __modImpl()
local Utils = __BUNDLER_FILES__.a()

local Builders = {}

local APPLICATION_COMMAND_CHAT_INPUT = 1
local COMPONENT_ACTION_ROW = 1
local COMPONENT_BUTTON = 2
local COMPONENT_STRING_SELECT = 3
local COMPONENT_TEXT_INPUT = 4
local COMPONENT_USER_SELECT = 5
local COMPONENT_ROLE_SELECT = 6
local COMPONENT_MENTIONABLE_SELECT = 7
local COMPONENT_CHANNEL_SELECT = 8
local COMPONENT_SECTION = 9
local COMPONENT_TEXT_DISPLAY = 10
local COMPONENT_THUMBNAIL = 11
local COMPONENT_MEDIA_GALLERY = 12
local COMPONENT_FILE = 13
local COMPONENT_SEPARATOR = 14
local COMPONENT_CONTAINER = 17

local SEPARATOR_SPACING_SMALL = 1
local SEPARATOR_SPACING_LARGE = 2
local MESSAGE_FLAG_IS_COMPONENTS_V2 = 32768

local OPTION_STRING = 3
local OPTION_INTEGER = 4
local OPTION_BOOLEAN = 5
local OPTION_USER = 6
local OPTION_CHANNEL = 7
local OPTION_ROLE = 8
local OPTION_MENTIONABLE = 9
local OPTION_NUMBER = 10
local OPTION_ATTACHMENT = 11

local function copyArray(values)
    local result = {}

    for index, value in ipairs(values) do
        result[index] = value
    end

    return result
end

local function copyMap(value)
    local result = {}

    for key, item in pairs(value) do
        if type(item) == "table" then
            result[key] = copyMap(item)
        else
            result[key] = item
        end
    end

    return result
end

local function assertOptionalString(value, name)
    if value ~= nil then
        Utils.assertNonEmptyString(value, name)
    end
end

local function assertOptionalBoolean(value, name)
    if value ~= nil then
        Utils.assertType(value, "boolean", name)
    end
end

local function setField(builder, key, value)
    local data = copyMap(builder.data)
    data[key] = value

    return setmetatable({ data = data }, getmetatable(builder))
end

local function getComponentData(component, name)
    Utils.assertTable(component, name)
    Utils.assertType(component.toJSON, "function", name .. ".toJSON")

    return component:toJSON()
end

local function assertComponentType(componentData, allowedTypes, name)
    if not allowedTypes[componentData.type] then
        error(("%s has unsupported component type: %s"):format(name, tostring(componentData.type)), 3)
    end
end

local function countComponents(componentData)
    local count = 1

    if componentData.components then
        for _, child in ipairs(componentData.components) do
            count = count + countComponents(child)
        end
    end

    if componentData.accessory then
        count = count + countComponents(componentData.accessory)
    end

    return count
end

local function isAttachmentUrl(url)
    return string.sub(url, 1, 13) == "attachment://"
end

local SlashCommandOptionBuilder = {}
SlashCommandOptionBuilder.__index = SlashCommandOptionBuilder

function SlashCommandOptionBuilder.new(optionType)
    Utils.assertType(optionType, "number", "optionType")

    return setmetatable({
        data = {
            type = optionType
        }
    }, SlashCommandOptionBuilder)
end

function SlashCommandOptionBuilder:setName(name)
    Utils.assertNonEmptyString(name, "name")

    return setField(self, "name", name)
end

function SlashCommandOptionBuilder:setDescription(description)
    Utils.assertNonEmptyString(description, "description")

    return setField(self, "description", description)
end

function SlashCommandOptionBuilder:setRequired(required)
    Utils.assertType(required, "boolean", "required")

    return setField(self, "required", required)
end

function SlashCommandOptionBuilder:addChoice(name, value)
    Utils.assertNonEmptyString(name, "name")

    local data = copyMap(self.data)
    local choices = data.choices and copyArray(data.choices) or {}

    table.insert(choices, {
        name = name,
        value = value
    })

    data.choices = choices
    return setmetatable({ data = data }, SlashCommandOptionBuilder)
end

function SlashCommandOptionBuilder:setMinValue(value)
    Utils.assertType(value, "number", "value")

    return setField(self, "min_value", value)
end

function SlashCommandOptionBuilder:setMaxValue(value)
    Utils.assertType(value, "number", "value")

    return setField(self, "max_value", value)
end

function SlashCommandOptionBuilder:setMinLength(value)
    Utils.assertType(value, "number", "value")

    return setField(self, "min_length", value)
end

function SlashCommandOptionBuilder:setMaxLength(value)
    Utils.assertType(value, "number", "value")

    return setField(self, "max_length", value)
end

function SlashCommandOptionBuilder:toJSON()
    Utils.assertNonEmptyString(self.data.name, "option.name")
    Utils.assertNonEmptyString(self.data.description, "option.description")

    return copyMap(self.data)
end

local SlashCommandBuilder = {}
SlashCommandBuilder.__index = SlashCommandBuilder

function SlashCommandBuilder.new()
    return setmetatable({
        data = {
            type = APPLICATION_COMMAND_CHAT_INPUT,
            options = {}
        }
    }, SlashCommandBuilder)
end

function SlashCommandBuilder:setName(name)
    Utils.assertNonEmptyString(name, "name")

    return setField(self, "name", name)
end

function SlashCommandBuilder:setDescription(description)
    Utils.assertNonEmptyString(description, "description")

    return setField(self, "description", description)
end

function SlashCommandBuilder:addOption(optionType, configure)
    Utils.assertType(optionType, "number", "optionType")
    Utils.assertType(configure, "function", "configure")

    local optionBuilder = configure(SlashCommandOptionBuilder.new(optionType))
    Utils.assertTable(optionBuilder, "optionBuilder")
    Utils.assertType(optionBuilder.toJSON, "function", "optionBuilder.toJSON")

    local data = copyMap(self.data)
    local options = data.options and copyArray(data.options) or {}
    table.insert(options, optionBuilder:toJSON())
    data.options = options

    return setmetatable({ data = data }, SlashCommandBuilder)
end

function SlashCommandBuilder:addStringOption(configure)
    return self:addOption(OPTION_STRING, configure)
end

function SlashCommandBuilder:addIntegerOption(configure)
    return self:addOption(OPTION_INTEGER, configure)
end

function SlashCommandBuilder:addBooleanOption(configure)
    return self:addOption(OPTION_BOOLEAN, configure)
end

function SlashCommandBuilder:addUserOption(configure)
    return self:addOption(OPTION_USER, configure)
end

function SlashCommandBuilder:addChannelOption(configure)
    return self:addOption(OPTION_CHANNEL, configure)
end

function SlashCommandBuilder:addRoleOption(configure)
    return self:addOption(OPTION_ROLE, configure)
end

function SlashCommandBuilder:addMentionableOption(configure)
    return self:addOption(OPTION_MENTIONABLE, configure)
end

function SlashCommandBuilder:addNumberOption(configure)
    return self:addOption(OPTION_NUMBER, configure)
end

function SlashCommandBuilder:addAttachmentOption(configure)
    return self:addOption(OPTION_ATTACHMENT, configure)
end

function SlashCommandBuilder:toJSON()
    Utils.assertNonEmptyString(self.data.name, "command.name")
    Utils.assertNonEmptyString(self.data.description, "command.description")

    return copyMap(self.data)
end

local EmbedBuilder = {}
EmbedBuilder.__index = EmbedBuilder

function EmbedBuilder.new()
    return setmetatable({
        data = {
            fields = {}
        }
    }, EmbedBuilder)
end

function EmbedBuilder:setTitle(title)
    assertOptionalString(title, "title")

    return setField(self, "title", title)
end

function EmbedBuilder:setDescription(description)
    assertOptionalString(description, "description")

    return setField(self, "description", description)
end

function EmbedBuilder:setColor(color)
    Utils.assertType(color, "number", "color")

    return setField(self, "color", color)
end

function EmbedBuilder:setURL(url)
    assertOptionalString(url, "url")

    return setField(self, "url", url)
end

function EmbedBuilder:setTimestamp(timestamp)
    assertOptionalString(timestamp, "timestamp")

    return setField(self, "timestamp", timestamp or os.date("!%Y-%m-%dT%H:%M:%S"))
end

function EmbedBuilder:setThumbnail(url)
    Utils.assertNonEmptyString(url, "url")

    return setField(self, "thumbnail", { url = url })
end

function EmbedBuilder:setImage(url)
    Utils.assertNonEmptyString(url, "url")

    return setField(self, "image", { url = url })
end

function EmbedBuilder:setFooter(options)
    Utils.assertTable(options, "options")
    Utils.assertNonEmptyString(options.text, "options.text")

    local footer = {
        text = options.text,
        icon_url = options.iconUrl
    }

    return setField(self, "footer", footer)
end

function EmbedBuilder:setAuthor(options)
    Utils.assertTable(options, "options")
    Utils.assertNonEmptyString(options.name, "options.name")

    local author = {
        name = options.name,
        icon_url = options.iconUrl,
        url = options.url
    }

    return setField(self, "author", author)
end

function EmbedBuilder:addField(name, value, inline)
    Utils.assertNonEmptyString(name, "name")
    Utils.assertNonEmptyString(value, "value")
    assertOptionalBoolean(inline, "inline")

    local data = copyMap(self.data)
    local fields = data.fields and copyArray(data.fields) or {}

    table.insert(fields, {
        name = name,
        value = value,
        inline = inline == true
    })

    data.fields = fields
    return setmetatable({ data = data }, EmbedBuilder)
end

function EmbedBuilder:toJSON()
    local data = copyMap(self.data)

    if data.fields and #data.fields == 0 then
        data.fields = nil
    end

    return data
end

local ButtonBuilder = {}
ButtonBuilder.__index = ButtonBuilder

function ButtonBuilder.new()
    return setmetatable({
        data = {
            type = COMPONENT_BUTTON
        }
    }, ButtonBuilder)
end

function ButtonBuilder:setCustomId(customId)
    Utils.assertNonEmptyString(customId, "customId")

    local data = copyMap(self.data)
    data.custom_id = customId

    if data.style == Builders.ButtonStyle.Link then
        data.style = Builders.ButtonStyle.Primary
        data.url = nil
    end

    return setmetatable({ data = data }, ButtonBuilder)
end

function ButtonBuilder:setLabel(label)
    Utils.assertNonEmptyString(label, "label")

    return setField(self, "label", label)
end

function ButtonBuilder:setStyle(style)
    Utils.assertType(style, "number", "style")

    return setField(self, "style", style)
end

function ButtonBuilder:setEmoji(emoji)
    Utils.assertTable(emoji, "emoji")

    return setField(self, "emoji", emoji)
end

function ButtonBuilder:setURL(url)
    Utils.assertNonEmptyString(url, "url")

    local data = copyMap(self.data)
    data.url = url
    data.custom_id = nil
    data.style = Builders.ButtonStyle.Link

    return setmetatable({ data = data }, ButtonBuilder)
end

function ButtonBuilder:setDisabled(disabled)
    Utils.assertType(disabled, "boolean", "disabled")

    return setField(self, "disabled", disabled)
end

function ButtonBuilder:toJSON()
    local data = copyMap(self.data)

    if data.style == nil then
        data.style = Builders.ButtonStyle.Primary
    end

    if data.style == Builders.ButtonStyle.Link then
        Utils.assertNonEmptyString(data.url, "button.url")
        data.custom_id = nil
    elseif data.url == nil then
        Utils.assertNonEmptyString(data.custom_id, "button.custom_id")
    else
        error("button.url is only valid for link buttons", 2)
    end

    return data
end

local ACTION_ROW_CHILD_COMPONENT_TYPES = {
    [COMPONENT_BUTTON] = true,
    [COMPONENT_STRING_SELECT] = true,
    [COMPONENT_USER_SELECT] = true,
    [COMPONENT_ROLE_SELECT] = true,
    [COMPONENT_MENTIONABLE_SELECT] = true,
    [COMPONENT_CHANNEL_SELECT] = true
}

local ActionRowBuilder = {}
ActionRowBuilder.__index = ActionRowBuilder

function ActionRowBuilder.new()
    return setmetatable({
        data = {
            type = COMPONENT_ACTION_ROW,
            components = {}
        }
    }, ActionRowBuilder)
end

function ActionRowBuilder:addComponent(component)
    local componentData = getComponentData(component, "component")
    assertComponentType(componentData, ACTION_ROW_CHILD_COMPONENT_TYPES, "component")

    local data = copyMap(self.data)
    local components = data.components and copyArray(data.components) or {}

    if componentData.type == COMPONENT_BUTTON then
        if #components >= 5 then
            error("actionRow.components cannot contain more than five buttons", 2)
        end

        if components[1] and components[1].type ~= COMPONENT_BUTTON then
            error("actionRow.components cannot mix buttons and select menus", 2)
        end
    else
        if #components > 0 then
            error("actionRow.components can contain only one select menu", 2)
        end
    end

    table.insert(components, componentData)
    data.components = components

    return setmetatable({ data = data }, ActionRowBuilder)
end

function ActionRowBuilder:toJSON()
    if #self.data.components == 0 then
        error("actionRow.components must contain at least one component", 2)
    end

    return copyMap(self.data)
end

local TextDisplayBuilder = {}
TextDisplayBuilder.__index = TextDisplayBuilder

function TextDisplayBuilder.new()
    return setmetatable({
        data = {
            type = COMPONENT_TEXT_DISPLAY
        }
    }, TextDisplayBuilder)
end

function TextDisplayBuilder:setContent(content)
    Utils.assertNonEmptyString(content, "content")

    return setField(self, "content", content)
end

function TextDisplayBuilder:toJSON()
    Utils.assertNonEmptyString(self.data.content, "textDisplay.content")

    return copyMap(self.data)
end

local ThumbnailBuilder = {}
ThumbnailBuilder.__index = ThumbnailBuilder

function ThumbnailBuilder.new()
    return setmetatable({
        data = {
            type = COMPONENT_THUMBNAIL
        }
    }, ThumbnailBuilder)
end

function ThumbnailBuilder:setURL(url)
    Utils.assertNonEmptyString(url, "url")

    return setField(self, "media", { url = url })
end

function ThumbnailBuilder:setDescription(description)
    Utils.assertNonEmptyString(description, "description")

    return setField(self, "description", description)
end

function ThumbnailBuilder:setSpoiler(spoiler)
    Utils.assertType(spoiler, "boolean", "spoiler")

    return setField(self, "spoiler", spoiler)
end

function ThumbnailBuilder:toJSON()
    Utils.assertTable(self.data.media, "thumbnail.media")
    Utils.assertNonEmptyString(self.data.media.url, "thumbnail.media.url")

    return copyMap(self.data)
end

local MediaGalleryBuilder = {}
MediaGalleryBuilder.__index = MediaGalleryBuilder

function MediaGalleryBuilder.new()
    return setmetatable({
        data = {
            type = COMPONENT_MEDIA_GALLERY,
            items = {}
        }
    }, MediaGalleryBuilder)
end

function MediaGalleryBuilder:addItem(options)
    Utils.assertTable(options, "options")
    Utils.assertNonEmptyString(options.url, "options.url")
    assertOptionalString(options.description, "options.description")
    assertOptionalBoolean(options.spoiler, "options.spoiler")

    local data = copyMap(self.data)
    local items = data.items and copyArray(data.items) or {}

    table.insert(items, {
        media = {
            url = options.url
        },
        description = options.description,
        spoiler = options.spoiler == true
    })

    data.items = items
    return setmetatable({ data = data }, MediaGalleryBuilder)
end

function MediaGalleryBuilder:toJSON()
    if #self.data.items == 0 then
        error("mediaGallery.items must contain at least one item", 2)
    end

    if #self.data.items > 10 then
        error("mediaGallery.items must contain no more than ten items", 2)
    end

    return copyMap(self.data)
end

local FileBuilder = {}
FileBuilder.__index = FileBuilder

function FileBuilder.new()
    return setmetatable({
        data = {
            type = COMPONENT_FILE
        }
    }, FileBuilder)
end

function FileBuilder:setURL(url)
    Utils.assertNonEmptyString(url, "url")

    if not isAttachmentUrl(url) then
        error("file.url must use attachment://<filename>", 2)
    end

    return setField(self, "file", { url = url })
end

function FileBuilder:setSpoiler(spoiler)
    Utils.assertType(spoiler, "boolean", "spoiler")

    return setField(self, "spoiler", spoiler)
end

function FileBuilder:toJSON()
    Utils.assertTable(self.data.file, "file.file")
    Utils.assertNonEmptyString(self.data.file.url, "file.file.url")

    return copyMap(self.data)
end

local SeparatorBuilder = {}
SeparatorBuilder.__index = SeparatorBuilder

function SeparatorBuilder.new()
    return setmetatable({
        data = {
            type = COMPONENT_SEPARATOR
        }
    }, SeparatorBuilder)
end

function SeparatorBuilder:setDivider(divider)
    Utils.assertType(divider, "boolean", "divider")

    return setField(self, "divider", divider)
end

function SeparatorBuilder:setSpacing(spacing)
    Utils.assertType(spacing, "number", "spacing")

    return setField(self, "spacing", spacing)
end

function SeparatorBuilder:toJSON()
    return copyMap(self.data)
end

local SECTION_CHILD_COMPONENT_TYPES = {
    [COMPONENT_TEXT_DISPLAY] = true
}

local SECTION_ACCESSORY_COMPONENT_TYPES = {
    [COMPONENT_BUTTON] = true,
    [COMPONENT_THUMBNAIL] = true
}

local SectionBuilder = {}
SectionBuilder.__index = SectionBuilder

function SectionBuilder.new()
    return setmetatable({
        data = {
            type = COMPONENT_SECTION,
            components = {}
        }
    }, SectionBuilder)
end

function SectionBuilder:addTextDisplay(textDisplay)
    local component = getComponentData(textDisplay, "textDisplay")
    assertComponentType(component, SECTION_CHILD_COMPONENT_TYPES, "textDisplay")

    local data = copyMap(self.data)
    local components = data.components and copyArray(data.components) or {}

    table.insert(components, component)
    data.components = components

    return setmetatable({ data = data }, SectionBuilder)
end

function SectionBuilder:setAccessory(accessory)
    local component = getComponentData(accessory, "accessory")
    assertComponentType(component, SECTION_ACCESSORY_COMPONENT_TYPES, "accessory")

    return setField(self, "accessory", component)
end

function SectionBuilder:toJSON()
    if #self.data.components == 0 then
        error("section.components must contain at least one text display", 2)
    end

    if #self.data.components > 3 then
        error("section.components must contain no more than three text displays", 2)
    end

    Utils.assertTable(self.data.accessory, "section.accessory")

    return copyMap(self.data)
end

local CONTAINER_CHILD_COMPONENT_TYPES = {
    [COMPONENT_ACTION_ROW] = true,
    [COMPONENT_TEXT_DISPLAY] = true,
    [COMPONENT_SECTION] = true,
    [COMPONENT_MEDIA_GALLERY] = true,
    [COMPONENT_SEPARATOR] = true,
    [COMPONENT_FILE] = true
}

local ContainerBuilder = {}
ContainerBuilder.__index = ContainerBuilder

function ContainerBuilder.new()
    return setmetatable({
        data = {
            type = COMPONENT_CONTAINER,
            components = {}
        }
    }, ContainerBuilder)
end

function ContainerBuilder:addComponent(component)
    local componentData = getComponentData(component, "component")
    assertComponentType(componentData, CONTAINER_CHILD_COMPONENT_TYPES, "component")

    local data = copyMap(self.data)
    local components = data.components and copyArray(data.components) or {}

    if #components >= 10 then
        error("container.components cannot contain more than ten components", 2)
    end

    table.insert(components, componentData)
    data.components = components

    return setmetatable({ data = data }, ContainerBuilder)
end

function ContainerBuilder:setAccentColor(color)
    Utils.assertType(color, "number", "color")

    return setField(self, "accent_color", color)
end

function ContainerBuilder:setSpoiler(spoiler)
    Utils.assertType(spoiler, "boolean", "spoiler")

    return setField(self, "spoiler", spoiler)
end

function ContainerBuilder:toJSON()
    if #self.data.components == 0 then
        error("container.components must contain at least one component", 2)
    end

    return copyMap(self.data)
end

local MessageBuilder = {}
MessageBuilder.__index = MessageBuilder

local MESSAGE_TOP_LEVEL_COMPONENT_TYPES = {
    [COMPONENT_ACTION_ROW] = true,
    [COMPONENT_TEXT_DISPLAY] = true,
    [COMPONENT_SECTION] = true,
    [COMPONENT_MEDIA_GALLERY] = true,
    [COMPONENT_FILE] = true,
    [COMPONENT_SEPARATOR] = true,
    [COMPONENT_CONTAINER] = true
}

function MessageBuilder.new()
    return setmetatable({
        data = {
            flags = MESSAGE_FLAG_IS_COMPONENTS_V2,
            components = {}
        }
    }, MessageBuilder)
end

function MessageBuilder:addComponent(component)
    local componentData = getComponentData(component, "component")
    assertComponentType(componentData, MESSAGE_TOP_LEVEL_COMPONENT_TYPES, "component")

    local data = copyMap(self.data)
    local components = data.components and copyArray(data.components) or {}

    table.insert(components, componentData)
    data.components = components

    return setmetatable({ data = data }, MessageBuilder)
end

function MessageBuilder:setEphemeral(ephemeral)
    Utils.assertType(ephemeral, "boolean", "ephemeral")

    local data = copyMap(self.data)
    data.ephemeral = ephemeral

    return setmetatable({ data = data }, MessageBuilder)
end

function MessageBuilder:toJSON()
    if #self.data.components == 0 then
        error("message.components must contain at least one component", 2)
    end

    local componentCount = 0
    for _, component in ipairs(self.data.components) do
        componentCount = componentCount + countComponents(component)
    end

    if componentCount > 40 then
        error("message.components cannot contain more than forty total components", 2)
    end

    return {
        components = copyArray(self.data.components),
        ephemeral = self.data.ephemeral == true,
        flags = self.data.flags
    }
end

Builders.SlashCommandBuilder = SlashCommandBuilder
Builders.SlashCommandOptionBuilder = SlashCommandOptionBuilder
Builders.EmbedBuilder = EmbedBuilder
Builders.ButtonBuilder = ButtonBuilder
Builders.ActionRowBuilder = ActionRowBuilder
Builders.MessageBuilder = MessageBuilder
Builders.TextDisplayBuilder = TextDisplayBuilder
Builders.SectionBuilder = SectionBuilder
Builders.ThumbnailBuilder = ThumbnailBuilder
Builders.MediaGalleryBuilder = MediaGalleryBuilder
Builders.FileBuilder = FileBuilder
Builders.SeparatorBuilder = SeparatorBuilder
Builders.ContainerBuilder = ContainerBuilder

Builders.OptionType = {
    String = OPTION_STRING,
    Integer = OPTION_INTEGER,
    Boolean = OPTION_BOOLEAN,
    User = OPTION_USER,
    Channel = OPTION_CHANNEL,
    Role = OPTION_ROLE,
    Mentionable = OPTION_MENTIONABLE,
    Number = OPTION_NUMBER,
    Attachment = OPTION_ATTACHMENT
}

Builders.ButtonStyle = {
    Primary = 1,
    Secondary = 2,
    Success = 3,
    Danger = 4,
    Link = 5
}

Builders.ComponentType = {
    ActionRow = COMPONENT_ACTION_ROW,
    Button = COMPONENT_BUTTON,
    StringSelect = COMPONENT_STRING_SELECT,
    TextInput = COMPONENT_TEXT_INPUT,
    UserSelect = COMPONENT_USER_SELECT,
    RoleSelect = COMPONENT_ROLE_SELECT,
    MentionableSelect = COMPONENT_MENTIONABLE_SELECT,
    ChannelSelect = COMPONENT_CHANNEL_SELECT,
    Section = COMPONENT_SECTION,
    TextDisplay = COMPONENT_TEXT_DISPLAY,
    Thumbnail = COMPONENT_THUMBNAIL,
    MediaGallery = COMPONENT_MEDIA_GALLERY,
    File = COMPONENT_FILE,
    Separator = COMPONENT_SEPARATOR,
    Container = COMPONENT_CONTAINER
}

Builders.MessageFlags = {
    IsComponentsV2 = MESSAGE_FLAG_IS_COMPONENTS_V2
}

Builders.SeparatorSpacing = {
    Small = SEPARATOR_SPACING_SMALL,
    Large = SEPARATOR_SPACING_LARGE
}

return Builders
end function __BUNDLER_FILES__.g():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.g if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.g=v end return v.c end end end
local Client = __BUNDLER_FILES__.f()
local Utils = __BUNDLER_FILES__.a()
local Builders = __BUNDLER_FILES__.g()
local Runtime = __BUNDLER_FILES__.b()

return {
    Builders = Builders,
    Client = Client,
    Runtime = Runtime,
    Utils = Utils,
    version = "1.0.0"
}
