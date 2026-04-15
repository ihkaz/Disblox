local __BUNDLER_FILES__={cache={}::any}do do local function __modImpl()local Utils = {}

local EPHEMERAL_MESSAGE_FLAG = 64
local IS_COMPONENTS_V2_MESSAGE_FLAG = 32768

local function getHttpService()
    return game:GetService("HttpService")
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

function Utils.jsonDecode(str)
    local success, result = pcall(function()
        return getHttpService():JSONDecode(str)
    end)

    if not success then
        error(("Failed to decode JSON: %s"):format(tostring(result)), 2)
    end

    return result
end

function Utils.assertType(value, expectedType, name)
    if type(value) ~= expectedType then
        error(("%s must be a %s, got %s"):format(name, expectedType, type(value)), 3)
    end
end

function Utils.assertNonEmptyString(value, name)
    Utils.assertType(value, "string", name)

    if value == "" then
        error(("%s must not be empty"):format(name), 3)
    end
end

function Utils.assertTable(value, name)
    Utils.assertType(value, "table", name)
end

function Utils.hasFlag(flags, flag)
    Utils.assertType(flags, "number", "flags")
    Utils.assertType(flag, "number", "flag")

    return flags % (flag * 2) >= flag
end

function Utils.addFlag(flags, flag)
    Utils.assertType(flags, "number", "flags")
    Utils.assertType(flag, "number", "flag")

    if Utils.hasFlag(flags, flag) then
        return flags
    end

    return flags + flag
end

function Utils.resolveMessageFlags(flags, ephemeral)
    local resolvedFlags = flags or 0

    Utils.assertType(resolvedFlags, "number", "flags")

    if ephemeral then
        resolvedFlags = Utils.addFlag(resolvedFlags, EPHEMERAL_MESSAGE_FLAG)
    end

    if resolvedFlags == 0 then
        return nil
    end

    return resolvedFlags
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

    if options.toJSON then
        Utils.assertType(options.toJSON, "function", "options.toJSON")
        options = options:toJSON()
    end

    if options.content or options.embeds or options.components or options.ephemeral ~= nil or options.flags ~= nil then
        return {
            content = options.content,
            ephemeral = options.ephemeral == true,
            embeds = options.embeds,
            components = options.components,
            flags = options.flags
        }
    end

    return {
        content = nil,
        ephemeral = false,
        embeds = { options },
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

    if options.toJSON then
        Utils.assertType(options.toJSON, "function", "options.toJSON")
        options = options:toJSON()
    end

    if options.content or options.embeds or options.components or options.flags ~= nil then
        return {
            content = options.content,
            embeds = options.embeds,
            components = options.components,
            flags = options.flags
        }
    end

    return {
        content = nil,
        embeds = { options },
        components = nil,
        flags = nil
    }
end

function Utils.makeEmbed(options)
    Utils.assertTable(options, "options")

    return {
        title = options.title,
        description = options.description,
        color = options.color or 0x5865F2,
        fields = options.fields or {},
        thumbnail = options.thumbnail,
        image = options.image,
        footer = options.footer,
        author = options.author,
        timestamp = options.timestamp or os.date("!%Y-%m-%dT%H:%M:%S"),
        url = options.url
    }
end

function Utils.snowflakeToTimestamp(snowflake)
    local numericSnowflake = tonumber(snowflake)

    if not numericSnowflake then
        error(("snowflake must be numeric, got %s"):format(tostring(snowflake)), 2)
    end

    return math.floor(numericSnowflake / 4194304 + 1420070400000) / 1000
end

function Utils.makeButton(options)
    Utils.assertTable(options, "options")

    local button = {
        type = 2,
        style = options.style or 1,
        label = options.label,
        custom_id = options.customId,
        emoji = options.emoji,
        url = options.url,
        disabled = options.disabled or false
    }
    
    if button.url then
        button.custom_id = nil
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

local Gateway = {}
Gateway.__index = Gateway

local DISCORD_GATEWAY_URL = "wss://gateway.discord.gg/?v=10&encoding=json"
local OP_DISPATCH = 0
local OP_HEARTBEAT = 1
local OP_IDENTIFY = 2
local OP_RECONNECT = 7
local OP_INVALID_SESSION = 9
local OP_HELLO = 10
local OP_HEARTBEAT_ACK = 11

local DEFAULT_GATEWAY_INTENTS = 1

local function resolveWebSocketConnect()
    if WebSocket and WebSocket.connect then
        return WebSocket.connect
    end

    if Websocket and Websocket.connect then
        return Websocket.connect
    end

    if websocket and websocket.connect then
        return websocket.connect
    end

    error("No supported websocket connector found. Expected WebSocket.connect, Websocket.connect, or websocket.connect.", 2)
end

function Gateway.new(token, intents)
    Utils.assertNonEmptyString(token, "token")

    if intents ~= nil then
        Utils.assertType(intents, "number", "intents")
    end

    local self = setmetatable({}, Gateway)
    self.token = token
    self.intents = intents or DEFAULT_GATEWAY_INTENTS
    self.ws = nil
    self.heartbeatInterval = nil
    self.lastSequence = nil
    self.sessionId = nil
    self.resumeGatewayUrl = nil
    self.lastHeartbeatAcked = true
    self.heartbeatTask = nil
    self.events = {}
    return self
end

function Gateway:on(eventName, callback)
    Utils.assertNonEmptyString(eventName, "eventName")
    Utils.assertType(callback, "function", "callback")

    if not self.events[eventName] then
        self.events[eventName] = {}
    end

    table.insert(self.events[eventName], callback)
end

function Gateway:emit(eventName, ...)
    Utils.assertNonEmptyString(eventName, "eventName")

    if self.events[eventName] then
        for _, callback in ipairs(self.events[eventName]) do
            task.spawn(callback, ...)
        end
    end
end

function Gateway:send(op, data)
    if not self.ws then
        error(("Cannot send gateway payload before websocket is connected: op=%s"):format(tostring(op)), 2)
    end

    local payload = { op = op, d = data }
    self.ws:Send(Utils.jsonEncode(payload))
end

function Gateway:heartbeat()
    self.lastHeartbeatAcked = false
    self:send(OP_HEARTBEAT, self.lastSequence)
end

function Gateway:startHeartbeat()
    if self.heartbeatTask then
        task.cancel(self.heartbeatTask)
    end
    
    self.heartbeatTask = task.spawn(function()
        while self.ws and self.heartbeatInterval do
            wait(self.heartbeatInterval / 1000)

            if not self.lastHeartbeatAcked then
                warn("[GATEWAY] Heartbeat ACK missing")
            end

            self:heartbeat()
        end
    end)
end

function Gateway:identify()
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

function Gateway:connect()
    if self.ws then
        error("Gateway is already connected. Do not call client:login() more than once for the same client.", 2)
    end

    print("[GATEWAY] Connecting")

    local connectWebSocket = resolveWebSocketConnect()
    self.ws = connectWebSocket(DISCORD_GATEWAY_URL)

    self.ws.OnMessage:Connect(function(msg)
        local data = Utils.jsonDecode(msg)

        if data.s then
            self.lastSequence = data.s
        end

        if data.op == OP_HELLO then
            print("[GATEWAY] Hello received")
            self.heartbeatInterval = data.d.heartbeat_interval
            self:startHeartbeat()
            self:identify()

        elseif data.op == OP_HEARTBEAT then
            self:heartbeat()

        elseif data.op == OP_HEARTBEAT_ACK then
            self.lastHeartbeatAcked = true

        elseif data.op == OP_DISPATCH then
            if data.t == "READY" then
                self.sessionId = data.d.session_id
                self.resumeGatewayUrl = data.d.resume_gateway_url
            end

            self:emit(data.t, data.d)

        elseif data.op == OP_RECONNECT then
            warn("[GATEWAY] Reconnect requested")

        elseif data.op == OP_INVALID_SESSION then
            warn("[GATEWAY] Invalid session")
            wait(5)
            self:identify()
        end
    end)

    self.ws.OnClose:Connect(function()
        warn("[GATEWAY] Disconnected")

        if self.heartbeatTask then
            task.cancel(self.heartbeatTask)
            self.heartbeatTask = nil
        end

        self.ws = nil
        self.heartbeatInterval = nil
        self.lastHeartbeatAcked = true
        self:emit("disconnect")
    end)

    print("[GATEWAY] Socket opened")
end

return Gateway
end function __BUNDLER_FILES__.b():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.b if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.b=v end return v.c end end do local function __modImpl()
local Utils = __BUNDLER_FILES__.a()

local Rest = {}
Rest.__index = Rest

function Rest.new(token, applicationId)
    Utils.assertNonEmptyString(token, "token")
    Utils.assertNonEmptyString(applicationId, "applicationId")

    local self = setmetatable({}, Rest)
    self.token = token
    self.applicationId = applicationId
    self.baseUrl = "https://discord.com/api/v10"
    self.maxRetries = 3
    return self
end

local function buildRequestBody(body)
    if body == nil then
        return nil
    end

    return Utils.jsonEncode(body)
end

local function decodeResponseBody(body)
    if not body or body == "" then
        return nil
    end

    return Utils.jsonDecode(body)
end

local function formatRestError(method, endpoint, response, requestError)
    if requestError then
        return ("Discord REST request failed: method=%s endpoint=%s error=%s"):format(
            method,
            endpoint,
            tostring(requestError)
        )
    end

    return ("Discord REST request failed: method=%s endpoint=%s status=%s body=%s"):format(
        method,
        endpoint,
        tostring(response and response.StatusCode),
        tostring(response and response.Body)
    )
end

local function shouldRetry(response, requestError)
    if requestError then
        return true
    end

    if not response then
        return true
    end

    return response.StatusCode == 429 or response.StatusCode >= 500
end

function Rest:request(method, endpoint, body)
    Utils.assertNonEmptyString(method, "method")
    Utils.assertNonEmptyString(endpoint, "endpoint")

    local lastResponse = nil
    local lastError = nil

    for attempt = 1, self.maxRetries do
        local requestBody = buildRequestBody(body)

        local success, response = pcall(function()
            return request({
                Url = self.baseUrl .. endpoint,
                Method = method,
                Headers = {
                    ["Authorization"] = "Bot " .. self.token,
                    ["Content-Type"] = "application/json"
                },
                Body = requestBody
            })
        end)

        if success and response and response.StatusCode >= 200 and response.StatusCode < 300 then
            return decodeResponseBody(response.Body)
        end

        lastResponse = response
        lastError = nil

        if not success then
            lastResponse = nil
            lastError = response
        end

        if attempt == self.maxRetries or not shouldRetry(lastResponse, lastError) then
            error(formatRestError(method, endpoint, lastResponse, lastError), 2)
        end

        warn("[REST RETRY]", {
            method = method,
            endpoint = endpoint,
            attempt = attempt,
            maxRetries = self.maxRetries,
            statusCode = lastResponse and lastResponse.StatusCode or nil,
            error = lastError and tostring(lastError) or nil
        })

        wait(attempt)
    end

    error(formatRestError(method, endpoint, lastResponse, lastError), 2)
end

function Rest:sendMessage(channelId, content, options)
    Utils.assertNonEmptyString(channelId, "channelId")

    if content ~= nil then
        Utils.assertNonEmptyString(content, "content")
    end

    if options ~= nil then
        Utils.assertTable(options, "options")

        if options.toJSON then
            Utils.assertType(options.toJSON, "function", "options.toJSON")
            options = options:toJSON()
        end
    end

    local messageOptions = options or {}

    if content == nil and messageOptions.embeds == nil and messageOptions.components == nil then
        error("content, options.embeds, or options.components is required", 2)
    end

    local body = {
        content = content,
        embeds = messageOptions.embeds,
        components = messageOptions.components,
        flags = messageOptions.flags,
        message_reference = messageOptions.reply and { message_id = messageOptions.reply } or nil
    }

    return self:request("POST", "/channels/" .. channelId .. "/messages", body)
end

function Rest:editMessage(channelId, messageId, content, embeds, components, flags)
    Utils.assertNonEmptyString(channelId, "channelId")
    Utils.assertNonEmptyString(messageId, "messageId")

    local body = {
        content = content,
        embeds = embeds,
        components = components,
        flags = flags
    }

    return self:request("PATCH", "/channels/" .. channelId .. "/messages/" .. messageId, body)
end

function Rest:deleteMessage(channelId, messageId)
    Utils.assertNonEmptyString(channelId, "channelId")
    Utils.assertNonEmptyString(messageId, "messageId")

    return self:request("DELETE", "/channels/" .. channelId .. "/messages/" .. messageId)
end

function Rest:createReaction(channelId, messageId, emoji)
    Utils.assertNonEmptyString(channelId, "channelId")
    Utils.assertNonEmptyString(messageId, "messageId")
    Utils.assertNonEmptyString(emoji, "emoji")

    return self:request("PUT", "/channels/" .. channelId .. "/messages/" .. messageId .. "/reactions/" .. emoji .. "/@me")
end

function Rest:registerCommands(commands)
    Utils.assertTable(commands, "commands")

    return self:request("PUT", "/applications/" .. self.applicationId .. "/commands", commands)
end

function Rest:replyInteraction(interactionId, interactionToken, content, ephemeral, embeds, components, flags)
    Utils.assertNonEmptyString(interactionId, "interactionId")
    Utils.assertNonEmptyString(interactionToken, "interactionToken")

    local resolvedFlags = Utils.resolveMessageFlags(flags, ephemeral)
    local body = {
        type = 4,
        data = {
            content = content,
            embeds = embeds,
            components = components,
            flags = resolvedFlags
        }
    }

    return self:request("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", body)
end

function Rest:deferReply(interactionId, interactionToken, ephemeral)
    Utils.assertNonEmptyString(interactionId, "interactionId")
    Utils.assertNonEmptyString(interactionToken, "interactionToken")

    local resolvedFlags = Utils.resolveMessageFlags(nil, ephemeral)
    local body = {
        type = 5,
        data = {
            flags = resolvedFlags
        }
    }

    return self:request("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", body)
end

function Rest:editInteractionResponse(interactionToken, content, embeds, components, flags)
    Utils.assertNonEmptyString(interactionToken, "interactionToken")

    local body = {
        content = content,
        embeds = embeds,
        components = components,
        flags = flags
    }

    return self:request("PATCH", "/webhooks/" .. self.applicationId .. "/" .. interactionToken .. "/messages/@original", body)
end

function Rest:updateComponent(interactionId, interactionToken, content, embeds, components, flags)
    Utils.assertNonEmptyString(interactionId, "interactionId")
    Utils.assertNonEmptyString(interactionToken, "interactionToken")

    local body = {
        type = 7,
        data = {
            content = content,
            embeds = embeds,
            components = components,
            flags = flags
        }
    }

    return self:request("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", body)
end

function Rest:deferUpdate(interactionId, interactionToken)
    Utils.assertNonEmptyString(interactionId, "interactionId")
    Utils.assertNonEmptyString(interactionToken, "interactionToken")

    local body = {
        type = 6
    }

    return self:request("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", body)
end

return Rest
end function __BUNDLER_FILES__.c():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.c if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.c=v end return v.c end end do local function __modImpl()
local Utils = __BUNDLER_FILES__.a()

local CommandHandler = {}
CommandHandler.__index = CommandHandler

local INTERACTION_APPLICATION_COMMAND = 2
local INTERACTION_MESSAGE_COMPONENT = 3
local OPTION_USER = 6

local function resolveCommandData(options)
    if options.data then
        Utils.assertTable(options.data, "options.data")

        if options.data.toJSON then
            Utils.assertType(options.data.toJSON, "function", "options.data.toJSON")
            return options.data:toJSON()
        end

        return options.data
    end

    return {
        name = options.name,
        description = options.description,
        options = options.options,
        type = 1
    }
end

function CommandHandler.new(rest)
    Utils.assertTable(rest, "rest")

    local self = setmetatable({}, CommandHandler)
    self.commands = {}
    self.buttons = {}
    self.rest = rest
    return self
end

function CommandHandler:registerCommand(options)
    Utils.assertTable(options, "options")
    Utils.assertType(options.execute, "function", "options.execute")

    local commandData = resolveCommandData(options)
    Utils.assertNonEmptyString(commandData.name, "commandData.name")
    Utils.assertNonEmptyString(commandData.description, "commandData.description")

    local command = {
        data = commandData,
        name = commandData.name,
        description = commandData.description,
        options = commandData.options,
        execute = options.execute,
        type = commandData.type or 1
    }

    self.commands[command.name] = command
    print(("[COMMAND] Registered %s"):format(command.name))
end

function CommandHandler:registerAll()
    local commandsData = {}
    for _, cmd in pairs(self.commands) do
        table.insert(commandsData, cmd.data)
    end

    self.rest:registerCommands(commandsData)
    print(("[COMMANDS] Registered %d command(s)"):format(#commandsData))
end

function CommandHandler:registerButton(customId, handler)
    Utils.assertNonEmptyString(customId, "customId")
    Utils.assertType(handler, "function", "handler")

    self.buttons[customId] = handler
    print(("[BUTTON] Registered %s"):format(customId))
end

function CommandHandler:handleInteraction(interaction)
    Utils.assertTable(interaction, "interaction")

    if interaction.type == INTERACTION_APPLICATION_COMMAND then
        self:handleSlashCommand(interaction)
    elseif interaction.type == INTERACTION_MESSAGE_COMPONENT then
        self:handleButton(interaction)
    end
end

local function getInteractionUser(interaction)
    if interaction.member and interaction.member.user then
        return interaction.member.user
    end

    return interaction.user
end

local function getOption(interaction, name)
    if not interaction.data.options then
        return nil
    end

    for _, option in ipairs(interaction.data.options) do
        if option.name == name then
            return option
        end
    end

    return nil
end

local function getResolvedUser(interaction, option)
    if not interaction.data.resolved or not interaction.data.resolved.users then
        return nil
    end

    return interaction.data.resolved.users[option.value]
end

local function getResolvedMember(interaction, option)
    if not interaction.data.resolved or not interaction.data.resolved.members then
        return nil
    end

    return interaction.data.resolved.members[option.value]
end

local function replyWithCommandError(interactionObj, commandName, err)
    warn("[COMMAND ERROR]", {
        command = commandName,
        error = tostring(err)
    })

    local success, replyError = pcall(function()
        interactionObj.reply({
            content = "An error occurred while executing this command.",
            ephemeral = true
        })
    end)

    if not success then
        warn("[COMMAND ERROR REPLY FAILED]", {
            command = commandName,
            error = tostring(replyError)
        })
    end
end

local function buildSlashCommandInteraction(self, interaction)
    return {
        id = interaction.id,
        token = interaction.token,
        user = getInteractionUser(interaction),
        member = interaction.member,
        guild_id = interaction.guild_id,
        channel_id = interaction.channel_id,
        data = interaction.data,

        reply = function(options)
            local response = Utils.normalizeMessageOptions(options)

            return self.rest:replyInteraction(
                interaction.id,
                interaction.token,
                response.content,
                response.ephemeral,
                response.embeds,
                response.components,
                response.flags
            )
        end,

        defer = function(ephemeral)
            return self.rest:deferReply(interaction.id, interaction.token, ephemeral == true)
        end,

        editReply = function(options)
            local response = Utils.normalizeEditOptions(options)

            return self.rest:editInteractionResponse(
                interaction.token,
                response.content,
                response.embeds,
                response.components,
                response.flags
            )
        end,

        getOption = function(name)
            Utils.assertNonEmptyString(name, "name")

            local option = getOption(interaction, name)
            return option and option.value or nil
        end,

        getUser = function(name)
            Utils.assertNonEmptyString(name, "name")

            local option = getOption(interaction, name)
            if not option or option.type ~= OPTION_USER then
                return nil
            end

            return getResolvedUser(interaction, option)
        end,

        getMember = function(name)
            Utils.assertNonEmptyString(name, "name")

            local option = getOption(interaction, name)
            if not option or option.type ~= OPTION_USER then
                return nil
            end

            return getResolvedMember(interaction, option)
        end
    }
end

local function buildButtonInteraction(self, interaction, customId)
    return {
        id = interaction.id,
        token = interaction.token,
        user = getInteractionUser(interaction),
        member = interaction.member,
        guild_id = interaction.guild_id,
        channel_id = interaction.channel_id,
        message = interaction.message,
        customId = customId,

        update = function(options)
            local response = Utils.normalizeEditOptions(options)

            return self.rest:updateComponent(
                interaction.id,
                interaction.token,
                response.content,
                response.embeds,
                response.components,
                response.flags
            )
        end,

        reply = function(options)
            local response = Utils.normalizeMessageOptions(options)

            return self.rest:replyInteraction(
                interaction.id,
                interaction.token,
                response.content,
                response.ephemeral,
                response.embeds,
                response.components,
                response.flags
            )
        end,

        deferUpdate = function()
            return self.rest:deferUpdate(interaction.id, interaction.token)
        end
    }
end

function CommandHandler:handleSlashCommand(interaction)
    Utils.assertTable(interaction.data, "interaction.data")

    local commandName = interaction.data.name
    local command = self.commands[commandName]

    if command then
        local user = getInteractionUser(interaction)
        print(("[COMMAND] %s from %s (%s)"):format(
            tostring(commandName),
            tostring(user and user.username),
            tostring(user and user.id)
        ))

        local interactionObj = buildSlashCommandInteraction(self, interaction)
        local success, err = pcall(function()
            command.execute(interactionObj)
        end)

        if not success then
            replyWithCommandError(interactionObj, commandName, err)
        end
    else
        warn(("[COMMAND] Missing handler for %s"):format(tostring(commandName)))
    end
end

function CommandHandler:handleButton(interaction)
    Utils.assertTable(interaction.data, "interaction.data")
    Utils.assertNonEmptyString(interaction.data.custom_id, "interaction.data.custom_id")

    local customId = interaction.data.custom_id
    local handler = self.buttons[customId]

    if handler then
        local user = getInteractionUser(interaction)
        print(("[BUTTON] %s from %s (%s)"):format(
            tostring(customId),
            tostring(user and user.username),
            tostring(user and user.id)
        ))

        local buttonObj = buildButtonInteraction(self, interaction, customId)
        local success, err = pcall(function()
            handler(buttonObj)
        end)

        if not success then
            warn("[BUTTON ERROR]", {
                customId = customId,
                error = tostring(err)
            })
        end
    else
        warn(("[BUTTON] Missing handler for %s"):format(tostring(customId)))
    end
end

return CommandHandler
end function __BUNDLER_FILES__.d():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.d if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.d=v end return v.c end end do local function __modImpl()
local Gateway = __BUNDLER_FILES__.b()
local Rest = __BUNDLER_FILES__.c()
local CommandHandler = __BUNDLER_FILES__.d()
local Utils = __BUNDLER_FILES__.a()

local Client = {}
Client.__index = Client

function Client.new(options)
    Utils.assertTable(options, "options")
    Utils.assertNonEmptyString(options.token, "options.token")
    Utils.assertNonEmptyString(options.applicationId, "options.applicationId")

    local self = setmetatable({}, Client)
    self.token = options.token
    self.applicationId = options.applicationId
    self.intents = options.intents
    
    self.gateway = Gateway.new(self.token, self.intents)
    self.rest = Rest.new(self.token, self.applicationId)
    self.commands = CommandHandler.new(self.rest)
    
    self.user = nil
    self.events = {}
    
    self.gateway:on("READY", function(data)
        self.user = data.user
        print(("[READY] Logged in as %s (%s)"):format(
            tostring(data.user and data.user.username),
            tostring(data.user and data.user.id)
        ))
        self:emit("ready")

        task.spawn(function()
            wait(2)
            self.commands:registerAll()
        end)
    end)
    
    self.gateway:on("INTERACTION_CREATE", function(data)
        self:emit("interactionCreate", data)
        self.commands:handleInteraction(data)
    end)
    
    self.gateway:on("MESSAGE_CREATE", function(data)
        if data.author.bot then return end
        self:emit("messageCreate", data)
    end)
    
    return self
end

function Client:on(eventName, callback)
    Utils.assertNonEmptyString(eventName, "eventName")
    Utils.assertType(callback, "function", "callback")

    if not self.events[eventName] then
        self.events[eventName] = {}
    end

    table.insert(self.events[eventName], callback)
end

function Client:emit(eventName, ...)
    Utils.assertNonEmptyString(eventName, "eventName")

    if self.events[eventName] then
        for _, callback in ipairs(self.events[eventName]) do
            task.spawn(callback, ...)
        end
    end
end

function Client:login()
    Utils.assertNonEmptyString(self.token, "token")

    self.gateway:connect()
end

return Client
end function __BUNDLER_FILES__.e():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.e if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.e=v end return v.c end end do local function __modImpl()
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
end function __BUNDLER_FILES__.f():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.f if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.f=v end return v.c end end end
local Client = __BUNDLER_FILES__.e()
local Utils = __BUNDLER_FILES__.a()
local Builders = __BUNDLER_FILES__.f()

return {
    Builders = Builders,
    Client = Client,
    Utils = Utils,
    version = "1.0.0"
}
