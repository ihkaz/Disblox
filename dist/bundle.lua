local __BUNDLER_FILES__ __BUNDLER_FILES__={cache={}, load=function(m)if not __BUNDLER_FILES__.cache[m]then __BUNDLER_FILES__.cache[m]={c=__BUNDLER_FILES__[m]()}end return __BUNDLER_FILES__.cache[m].c end}do function __BUNDLER_FILES__.a()
local Utils = {}
local HttpService = game:GetService("HttpService")

function Utils.jsonEncode(data)
    return HttpService:JSONEncode(data)
end

function Utils.jsonDecode(str)
    local success, result = pcall(function()
        return HttpService:JSONDecode(str)
    end)
    return success and result or nil
end

function Utils.makeEmbed(options)
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
    return math.floor(tonumber(snowflake) / 4194304 + 1420070400000) / 1000
end

function Utils.makeButton(options)
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

return Utils
end function __BUNDLER_FILES__.b()

local Utils = __BUNDLER_FILES__.load('a')

local Gateway = {}
Gateway.__index = Gateway

function Gateway.new(token)
    local self = setmetatable({}, Gateway)
    self.token = token
    self.ws = nil
    self.heartbeatInterval = nil
    self.lastSequence = nil
    self.sessionId = nil
    self.heartbeatTask = nil
    self.events = {}
    return self
end

function Gateway:on(eventName, callback)
    if not self.events[eventName] then
        self.events[eventName] = {}
    end
    table.insert(self.events[eventName], callback)
end

function Gateway:emit(eventName, ...)
    if self.events[eventName] then
        for _, callback in ipairs(self.events[eventName]) do
            task.spawn(callback, ...)
        end
    end
end

function Gateway:send(op, data)
    local payload = {op = op, d = data}
    self.ws:Send(Utils.jsonEncode(payload))
end

function Gateway:startHeartbeat()
    if self.heartbeatTask then
        task.cancel(self.heartbeatTask)
    end
    
    self.heartbeatTask = task.spawn(function()
        while self.ws and self.heartbeatInterval do
            wait(self.heartbeatInterval / 1000)
            self:send(1, self.lastSequence)
        end
    end)
end

function Gateway:identify()
    self:send(2, {
        token = self.token,
        intents = 33281,
        properties = {
            ["$os"] = "windows",
            ["$browser"] = "discord.lua",
            ["$device"] = "discord.lua"
        }
    })
end

function Gateway:connect()
    print("[GATEWAY] Connecting...")
    
    self.ws = Websocket.connect("wss://gateway.discord.gg/?v=10&encoding=json")
    
    self.ws.OnMessage:Connect(function(msg)
        local data = Utils.jsonDecode(msg)
        if not data then return end
        
        if data.s then
            self.lastSequence = data.s
        end
        
        if data.op == 10 then
            print("[HELLO] Received")
            self.heartbeatInterval = data.d.heartbeat_interval
            self:identify()
            self:startHeartbeat()
            
        elseif data.op == 11 then
            
            
        elseif data.op == 0 then
            self:emit(data.t, data.d)
            
        elseif data.op == 9 then
            warn("[INVALID SESSION]")
            wait(5)
            self:identify()
        end
    end)
    
    self.ws.OnClose:Connect(function()
        warn("[DISCONNECTED]")
        if self.heartbeatTask then
            task.cancel(self.heartbeatTask)
        end
        self:emit("disconnect")
    end)
    
    print("[GATEWAY] Connected")
end

return Gateway
end function __BUNDLER_FILES__.c()

local Utils = __BUNDLER_FILES__.load('a')

local Rest = {}
Rest.__index = Rest

function Rest.new(token, applicationId)
    local self = setmetatable({}, Rest)
    self.token = token
    self.applicationId = applicationId
    self.baseUrl = "https://discord.com/api/v10"
    return self
end

function Rest:request(method, endpoint, body)
    local success, response = pcall(function()
        return request({
            Url = self.baseUrl .. endpoint,
            Method = method,
            Headers = {
                ["Authorization"] = "Bot " .. self.token,
                ["Content-Type"] = "application/json"
            },
            Body = body and Utils.jsonEncode(body) or nil
        })
    end)
    
    if success and response.StatusCode >= 200 and response.StatusCode < 300 then
        return true, Utils.jsonDecode(response.Body)
    else
        warn("[REST ERROR]", method, endpoint, response and response.StatusCode or "Failed")
        return false, nil
    end
end

function Rest:sendMessage(channelId, content, options)
    options = options or {}
    local body = {
        content = content,
        embeds = options.embeds,
        components = options.components,
        message_reference = options.reply and {message_id = options.reply} or nil
    }
    return self:request("POST", "/channels/" .. channelId .. "/messages", body)
end

function Rest:editMessage(channelId, messageId, content, embeds, components)
    local body = {
        content = content,
        embeds = embeds,
        components = components
    }
    return self:request("PATCH", "/channels/" .. channelId .. "/messages/" .. messageId, body)
end

function Rest:deleteMessage(channelId, messageId)
    return self:request("DELETE", "/channels/" .. channelId .. "/messages/" .. messageId)
end

function Rest:createReaction(channelId, messageId, emoji)
    return self:request("PUT", "/channels/" .. channelId .. "/messages/" .. messageId .. "/reactions/" .. emoji .. "/@me")
end

function Rest:registerCommands(commands)
    return self:request("PUT", "/applications/" .. self.applicationId .. "/commands", commands)
end

function Rest:replyInteraction(interactionId, interactionToken, content, ephemeral, embeds, components)
    local body = {
        type = 4,
        data = {
            content = content,
            embeds = embeds,
            components = components,
            flags = ephemeral and 64 or nil
        }
    }
    return self:request("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", body)
end

function Rest:deferReply(interactionId, interactionToken, ephemeral)
    local body = {
        type = 5,
        data = {
            flags = ephemeral and 64 or nil
        }
    }
    return self:request("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", body)
end

function Rest:editInteractionResponse(interactionToken, content, embeds, components)
    local body = {
        content = content,
        embeds = embeds,
        components = components
    }
    return self:request("PATCH", "/webhooks/" .. self.applicationId .. "/" .. interactionToken .. "/messages/@original", body)
end

function Rest:updateComponent(interactionId, interactionToken, content, embeds, components)
    local body = {
        type = 7,
        data = {
            content = content,
            embeds = embeds,
            components = components
        }
    }
    return self:request("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", body)
end

function Rest:deferUpdate(interactionId, interactionToken)
    local body = {
        type = 6
    }
    return self:request("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", body)
end

return Rest
end function __BUNDLER_FILES__.d()__BUNDLER_FILES__.load('a')



local CommandHandler = {}
CommandHandler.__index = CommandHandler

function CommandHandler.new(rest)
    local self = setmetatable({}, CommandHandler)
    self.commands = {}
    self.buttons = {}
    self.rest = rest
    return self
end

function CommandHandler:registerCommand(options)
    local command = {
        name = options.name,
        description = options.description,
        options = options.options,
        execute = options.execute,
        type = 1
    }
    
    self.commands[options.name] = command
    print("[COMMAND] Registered:", options.name)
end

function CommandHandler:registerAll()
    local commandsData = {}
    for name, cmd in pairs(self.commands) do
        table.insert(commandsData, {
            name = cmd.name,
            description = cmd.description,
            options = cmd.options,
            type = cmd.type
        })
    end
    
    local success = self.rest:registerCommands(commandsData)
    if success then
        print("[COMMANDS] Registered", #commandsData, "commands")
    end
end

function CommandHandler:registerButton(customId, handler)
    self.buttons[customId] = handler
    print("[BUTTON] Registered:", customId)
end

function CommandHandler:handleInteraction(interaction)
    if interaction.type == 2 then
        self:handleSlashCommand(interaction)
    elseif interaction.type == 3 then
        self:handleButton(interaction)
    end
end

function CommandHandler:handleSlashCommand(interaction)
    local commandName = interaction.data.name
    local command = self.commands[commandName]
    
    if command then
        print("[COMMAND]", commandName, "from", interaction.member.user.username)
        
        local interactionObj = {
            id = interaction.id,
            token = interaction.token,
            user = interaction.member.user,
            member = interaction.member,
            guild_id = interaction.guild_id,
            channel_id = interaction.channel_id,
            data = interaction.data,
            
            reply = function(options)
                local content, ephemeral, embeds, components
                
                if type(options) == "string" then
                    content = options
                    ephemeral = false
                    embeds = nil
                    components = nil
                elseif type(options) == "table" then
                    if options.content or options.embeds or options.components or options.ephemeral ~= nil then
                        content = options.content
                        ephemeral = options.ephemeral or false
                        embeds = options.embeds
                        components = options.components
                    else
                        content = nil
                        ephemeral = false
                        embeds = {options}
                        components = nil
                    end
                end
                
                return self.rest:replyInteraction(
                    interaction.id, 
                    interaction.token, 
                    content, 
                    ephemeral, 
                    embeds,
                    components
                )
            end,
            
            defer = function(ephemeral)
                ephemeral = ephemeral or false
                return self.rest:deferReply(interaction.id, interaction.token, ephemeral)
            end,
            
            editReply = function(options)
                local content, embeds, components
                
                if type(options) == "string" then
                    content = options
                    embeds = nil
                    components = nil
                elseif type(options) == "table" then
                    if options.content or options.embeds or options.components then
                        content = options.content
                        embeds = options.embeds
                        components = options.components
                    else
                        content = nil
                        embeds = {options}
                        components = nil
                    end
                end
                
                return self.rest:editInteractionResponse(interaction.token, content, embeds, components)
            end,
            
            getOption = function(name)
                if not interaction.data.options then return nil end
                for _, option in ipairs(interaction.data.options) do
                    if option.name == name then
                        return option.value
                    end
                end
                return nil
            end,
            
            getUser = function(name)
                if not interaction.data.options or not interaction.data.resolved then 
                    return nil 
                end
                
                for _, option in ipairs(interaction.data.options) do
                    if option.name == name and option.type == 6 then
                        return interaction.data.resolved.users[option.value]
                    end
                end
                return nil
            end,
            
            getMember = function(name)
                if not interaction.data.options or not interaction.data.resolved then 
                    return nil 
                end
                
                for _, option in ipairs(interaction.data.options) do
                    if option.name == name and option.type == 6 then
                        return interaction.data.resolved.members[option.value]
                    end
                end
                return nil
            end
        }
        
        local success, err = pcall(function()
            command.execute(interactionObj)
        end)
        
        if not success then
            warn("[COMMAND ERROR]", commandName, err)
            pcall(function()
                interactionObj.reply({
                    content = "❌ An error occurred while executing this command.",
                    ephemeral = true
                })
            end)
        end
    end
end

function CommandHandler:handleButton(interaction)
    local customId = interaction.data.custom_id
    local handler = self.buttons[customId]
    
    if handler then
        print("[BUTTON]", customId, "clicked by", interaction.member.user.username)
        
        local buttonObj = {
            id = interaction.id,
            token = interaction.token,
            user = interaction.member.user,
            member = interaction.member,
            guild_id = interaction.guild_id,
            channel_id = interaction.channel_id,
            message = interaction.message,
            customId = customId,
            
            update = function(options)
                local content, embeds, components
                
                if type(options) == "string" then
                    content = options
                    embeds = nil
                    components = nil
                elseif type(options) == "table" then
                    content = options.content
                    embeds = options.embeds
                    components = options.components
                end
                
                return self.rest:updateComponent(
                    interaction.id,
                    interaction.token,
                    content,
                    embeds,
                    components
                )
            end,
            
            reply = function(options)
                local content, ephemeral, embeds, components
                
                if type(options) == "string" then
                    content = options
                    ephemeral = false
                    embeds = nil
                    components = nil
                elseif type(options) == "table" then
                    content = options.content
                    ephemeral = options.ephemeral or false
                    embeds = options.embeds
                    components = options.components
                end
                
                return self.rest:replyInteraction(
                    interaction.id,
                    interaction.token,
                    content,
                    ephemeral,
                    embeds,
                    components
                )
            end,
            
            deferUpdate = function()
                return self.rest:deferUpdate(interaction.id, interaction.token)
            end
        }
        
        local success, err = pcall(function()
            handler(buttonObj)
        end)
        
        if not success then
            warn("[BUTTON ERROR]", customId, err)
        end
    else
        warn("[BUTTON] No handler for:", customId)
    end
end

return CommandHandler
end function __BUNDLER_FILES__.e()

local Gateway = __BUNDLER_FILES__.load('b')
local Rest = __BUNDLER_FILES__.load('c')
local CommandHandler = __BUNDLER_FILES__.load('d')
__BUNDLER_FILES__.load('a')

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
end end

local Client = __BUNDLER_FILES__.load('e')
local Utils = __BUNDLER_FILES__.load('a')

return {
    Client = Client,
    Utils = Utils,
    version = "1.0.0"
}
