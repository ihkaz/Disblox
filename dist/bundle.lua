local __BUNDLER_FILES__={cache={}::any}do do local function __modImpl()local Constants = {}

Constants.Discord = {
    ApiUrl = "https://discord.com/api/v10",
    GatewayUrl = "wss://gateway.discord.gg/?v=10&encoding=json",
    DefaultIntents = 1
}

Constants.Opcode = {
    Dispatch = 0,
    Heartbeat = 1,
    Identify = 2,
    Resume = 6,
    Reconnect = 7,
    InvalidSession = 9,
    Hello = 10,
    HeartbeatAck = 11
}

Constants.InteractionType = {
    ApplicationCommand = 2,
    MessageComponent = 3
}

Constants.InteractionResponseType = {
    ChannelMessageWithSource = 4,
    DeferredChannelMessageWithSource = 5,
    DeferredUpdateMessage = 6,
    UpdateMessage = 7
}

Constants.ApplicationCommandType = {
    ChatInput = 1
}

Constants.OptionType = {
    String = 3,
    Integer = 4,
    Boolean = 5,
    User = 6,
    Channel = 7,
    Role = 8,
    Mentionable = 9,
    Number = 10,
    Attachment = 11
}

Constants.ComponentType = {
    ActionRow = 1,
    Button = 2,
    StringSelect = 3,
    TextInput = 4,
    UserSelect = 5,
    RoleSelect = 6,
    MentionableSelect = 7,
    ChannelSelect = 8,
    Section = 9,
    TextDisplay = 10,
    Thumbnail = 11,
    MediaGallery = 12,
    File = 13,
    Separator = 14,
    Container = 17
}

Constants.ButtonStyle = {
    Primary = 1,
    Secondary = 2,
    Success = 3,
    Danger = 4,
    Link = 5
}

Constants.SeparatorSpacing = {
    Small = 1,
    Large = 2
}

Constants.MessageFlags = {
    Ephemeral = 64,
    IsComponentsV2 = 32768
}

Constants.CloseCode = {
    AuthenticationFailed = 4004,
    InvalidShard = 4010,
    ShardingRequired = 4011,
    InvalidIntents = 4013,
    DisallowedIntents = 4014
}

return Constants
end function __BUNDLER_FILES__.a():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.a if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.a=v end return v.c end end do local function __modImpl()


local Constants = __BUNDLER_FILES__.a()

local Utils = {}

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
        error("HttpService is unavailable. This library must run in a Roblox/executor environment.", 3)
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

function Utils.assertString(value, name)
    Utils.assertType(value, "string", name)
end

function Utils.assertNonEmptyString(value, name)
    Utils.assertString(value, name)

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
    Utils.assertTable(values, "values")

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
        error(("JSON encode failed: %s"):format(tostring(result)), 2)
    end

    return result
end

function Utils.jsonDecode(value)
    Utils.assertNonEmptyString(value, "value")

    local success, result = pcall(function()
        return getHttpService():JSONDecode(value)
    end)

    if not success then
        error(("JSON decode failed: %s"):format(tostring(result)), 2)
    end

    return result
end

function Utils.toJSONValue(value, name)
    if type(value) == "table" and value.toJSON ~= nil then
        Utils.assertFunction(value.toJSON, name .. ".toJSON")
        return value:toJSON()
    end

    return value
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
        resolvedFlags = Utils.addFlag(resolvedFlags, Constants.MessageFlags.Ephemeral)
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
            embeds = nil,
            components = nil,
            ephemeral = false,
            flags = nil
        }
    end

    local data = Utils.toJSONValue(options, "options")
    Utils.assertTable(data, "options")

    if data.content or data.embeds or data.components or data.flags ~= nil or data.ephemeral ~= nil then
        return {
            content = data.content,
            embeds = data.embeds,
            components = data.components,
            ephemeral = data.ephemeral == true,
            flags = data.flags
        }
    end

    return {
        content = nil,
        embeds = { data },
        components = nil,
        ephemeral = false,
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

Utils.Colors = {
    Blurple = 0x5865F2,
    Green = 0x57F287,
    Yellow = 0xFEE75C,
    Red = 0xED4245,
    White = 0xFFFFFF,
    Black = 0x000000
}

Utils.ButtonStyle = Constants.ButtonStyle
Utils.MessageFlags = Constants.MessageFlags

return Utils
end function __BUNDLER_FILES__.b():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.b if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.b=v end return v.c end end do local function __modImpl()
local Constants = __BUNDLER_FILES__.a()
local Utils = __BUNDLER_FILES__.b()

local Builders = {}

local function copyMap(value)
    local result = {}

    for key, item in pairs(value) do
        result[key] = Utils.deepCopy(item)
    end

    return result
end

local function setField(builder, key, value)
    local data = copyMap(builder.data)
    data[key] = value
    return setmetatable({ data = data }, getmetatable(builder))
end

local function getJSON(value, name)
    Utils.assertTable(value, name)
    Utils.assertFunction(value.toJSON, name .. ".toJSON")
    return value:toJSON()
end

local SlashCommandOptionBuilder = {}
SlashCommandOptionBuilder.__index = SlashCommandOptionBuilder

function SlashCommandOptionBuilder.new(optionType)
    Utils.assertNumber(optionType, "optionType")
    return setmetatable({ data = { type = optionType } }, SlashCommandOptionBuilder)
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
    Utils.assertBoolean(required, "required")
    return setField(self, "required", required)
end

function SlashCommandOptionBuilder:addChoice(name, value)
    Utils.assertNonEmptyString(name, "name")

    local data = copyMap(self.data)
    local choices = data.choices or {}
    table.insert(choices, {
        name = name,
        value = value
    })
    data.choices = choices

    return setmetatable({ data = data }, SlashCommandOptionBuilder)
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
            type = Constants.ApplicationCommandType.ChatInput,
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
    Utils.assertNumber(optionType, "optionType")
    Utils.assertFunction(configure, "configure")

    local option = configure(SlashCommandOptionBuilder.new(optionType))
    local data = copyMap(self.data)
    local options = data.options or {}
    table.insert(options, getJSON(option, "option"))
    data.options = options

    return setmetatable({ data = data }, SlashCommandBuilder)
end

function SlashCommandBuilder:addStringOption(configure)
    return self:addOption(Constants.OptionType.String, configure)
end

function SlashCommandBuilder:addIntegerOption(configure)
    return self:addOption(Constants.OptionType.Integer, configure)
end

function SlashCommandBuilder:addBooleanOption(configure)
    return self:addOption(Constants.OptionType.Boolean, configure)
end

function SlashCommandBuilder:addUserOption(configure)
    return self:addOption(Constants.OptionType.User, configure)
end

function SlashCommandBuilder:toJSON()
    Utils.assertNonEmptyString(self.data.name, "command.name")
    Utils.assertNonEmptyString(self.data.description, "command.description")

    local data = copyMap(self.data)
    if data.options and #data.options == 0 then
        data.options = nil
    end

    return data
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
    Utils.assertNonEmptyString(title, "title")
    return setField(self, "title", title)
end

function EmbedBuilder:setDescription(description)
    Utils.assertNonEmptyString(description, "description")
    return setField(self, "description", description)
end

function EmbedBuilder:setColor(color)
    Utils.assertNumber(color, "color")
    return setField(self, "color", color)
end

function EmbedBuilder:setURL(url)
    Utils.assertNonEmptyString(url, "url")
    return setField(self, "url", url)
end

function EmbedBuilder:setThumbnail(url)
    Utils.assertNonEmptyString(url, "url")
    return setField(self, "thumbnail", { url = url })
end

function EmbedBuilder:setImage(url)
    Utils.assertNonEmptyString(url, "url")
    return setField(self, "image", { url = url })
end

function EmbedBuilder:addField(name, value, inline)
    Utils.assertNonEmptyString(name, "name")
    Utils.assertNonEmptyString(value, "value")

    if inline ~= nil then
        Utils.assertBoolean(inline, "inline")
    end

    local data = copyMap(self.data)
    local fields = data.fields or {}
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
            type = Constants.ComponentType.Button
        }
    }, ButtonBuilder)
end

function ButtonBuilder:setCustomId(customId)
    Utils.assertNonEmptyString(customId, "customId")
    local data = copyMap(self.data)
    data.custom_id = customId
    data.url = nil
    return setmetatable({ data = data }, ButtonBuilder)
end

function ButtonBuilder:setLabel(label)
    Utils.assertNonEmptyString(label, "label")
    return setField(self, "label", label)
end

function ButtonBuilder:setStyle(style)
    Utils.assertNumber(style, "style")
    return setField(self, "style", style)
end

function ButtonBuilder:setURL(url)
    Utils.assertNonEmptyString(url, "url")
    local data = copyMap(self.data)
    data.url = url
    data.custom_id = nil
    data.style = Constants.ButtonStyle.Link
    return setmetatable({ data = data }, ButtonBuilder)
end

function ButtonBuilder:setDisabled(disabled)
    Utils.assertBoolean(disabled, "disabled")
    return setField(self, "disabled", disabled)
end

function ButtonBuilder:toJSON()
    local data = copyMap(self.data)
    data.style = data.style or Constants.ButtonStyle.Primary

    if data.style == Constants.ButtonStyle.Link then
        Utils.assertNonEmptyString(data.url, "button.url")
        data.custom_id = nil
    else
        Utils.assertNonEmptyString(data.custom_id, "button.custom_id")
    end

    return data
end

local ActionRowBuilder = {}
ActionRowBuilder.__index = ActionRowBuilder

function ActionRowBuilder.new()
    return setmetatable({
        data = {
            type = Constants.ComponentType.ActionRow,
            components = {}
        }
    }, ActionRowBuilder)
end

function ActionRowBuilder:addComponent(component)
    local componentData = getJSON(component, "component")

    if componentData.type ~= Constants.ComponentType.Button then
        error("ActionRowBuilder currently supports button components only", 2)
    end

    local data = copyMap(self.data)
    local components = data.components or {}

    if #components >= 5 then
        error("action row cannot contain more than five buttons", 2)
    end

    table.insert(components, componentData)
    data.components = components

    return setmetatable({ data = data }, ActionRowBuilder)
end

function ActionRowBuilder:toJSON()
    if #self.data.components == 0 then
        error("action row must contain at least one component", 2)
    end

    return copyMap(self.data)
end

local TextDisplayBuilder = {}
TextDisplayBuilder.__index = TextDisplayBuilder

function TextDisplayBuilder.new()
    return setmetatable({
        data = {
            type = Constants.ComponentType.TextDisplay
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
            type = Constants.ComponentType.Thumbnail
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

function ThumbnailBuilder:toJSON()
    Utils.assertTable(self.data.media, "thumbnail.media")
    Utils.assertNonEmptyString(self.data.media.url, "thumbnail.media.url")
    return copyMap(self.data)
end

local SeparatorBuilder = {}
SeparatorBuilder.__index = SeparatorBuilder

function SeparatorBuilder.new()
    return setmetatable({
        data = {
            type = Constants.ComponentType.Separator
        }
    }, SeparatorBuilder)
end

function SeparatorBuilder:setDivider(divider)
    Utils.assertBoolean(divider, "divider")
    return setField(self, "divider", divider)
end

function SeparatorBuilder:setSpacing(spacing)
    Utils.assertNumber(spacing, "spacing")
    return setField(self, "spacing", spacing)
end

function SeparatorBuilder:toJSON()
    return copyMap(self.data)
end

local SectionBuilder = {}
SectionBuilder.__index = SectionBuilder

function SectionBuilder.new()
    return setmetatable({
        data = {
            type = Constants.ComponentType.Section,
            components = {}
        }
    }, SectionBuilder)
end

function SectionBuilder:addTextDisplay(textDisplay)
    local component = getJSON(textDisplay, "textDisplay")

    if component.type ~= Constants.ComponentType.TextDisplay then
        error("section child must be a text display", 2)
    end

    local data = copyMap(self.data)
    local components = data.components or {}
    table.insert(components, component)
    data.components = components

    return setmetatable({ data = data }, SectionBuilder)
end

function SectionBuilder:setAccessory(accessory)
    local component = getJSON(accessory, "accessory")

    if component.type ~= Constants.ComponentType.Button and component.type ~= Constants.ComponentType.Thumbnail then
        error("section accessory must be a button or thumbnail", 2)
    end

    return setField(self, "accessory", component)
end

function SectionBuilder:toJSON()
    if #self.data.components == 0 then
        error("section must contain at least one text display", 2)
    end

    Utils.assertTable(self.data.accessory, "section.accessory")
    return copyMap(self.data)
end

local ContainerBuilder = {}
ContainerBuilder.__index = ContainerBuilder

local CONTAINER_TYPES = {
    [Constants.ComponentType.ActionRow] = true,
    [Constants.ComponentType.TextDisplay] = true,
    [Constants.ComponentType.Section] = true,
    [Constants.ComponentType.Separator] = true
}

function ContainerBuilder.new()
    return setmetatable({
        data = {
            type = Constants.ComponentType.Container,
            components = {}
        }
    }, ContainerBuilder)
end

function ContainerBuilder:addComponent(component)
    local componentData = getJSON(component, "component")

    if not CONTAINER_TYPES[componentData.type] then
        error(("unsupported container component type: %s"):format(tostring(componentData.type)), 2)
    end

    local data = copyMap(self.data)
    local components = data.components or {}
    table.insert(components, componentData)
    data.components = components

    return setmetatable({ data = data }, ContainerBuilder)
end

function ContainerBuilder:setAccentColor(color)
    Utils.assertNumber(color, "color")
    return setField(self, "accent_color", color)
end

function ContainerBuilder:toJSON()
    if #self.data.components == 0 then
        error("container must contain at least one component", 2)
    end

    return copyMap(self.data)
end

local MessageBuilder = {}
MessageBuilder.__index = MessageBuilder

function MessageBuilder.new()
    return setmetatable({
        data = {
            flags = Constants.MessageFlags.IsComponentsV2,
            components = {}
        }
    }, MessageBuilder)
end

function MessageBuilder:addComponent(component)
    local data = copyMap(self.data)
    local components = data.components or {}
    table.insert(components, getJSON(component, "component"))
    data.components = components

    return setmetatable({ data = data }, MessageBuilder)
end

function MessageBuilder:setEphemeral(ephemeral)
    Utils.assertBoolean(ephemeral, "ephemeral")
    return setField(self, "ephemeral", ephemeral)
end

function MessageBuilder:toJSON()
    if #self.data.components == 0 then
        error("message must contain at least one component", 2)
    end

    return {
        components = Utils.arrayCopy(self.data.components),
        ephemeral = self.data.ephemeral == true,
        flags = self.data.flags
    }
end

Builders.SlashCommandBuilder = SlashCommandBuilder
Builders.SlashCommandOptionBuilder = SlashCommandOptionBuilder
Builders.EmbedBuilder = EmbedBuilder
Builders.ButtonBuilder = ButtonBuilder
Builders.ActionRowBuilder = ActionRowBuilder
Builders.TextDisplayBuilder = TextDisplayBuilder
Builders.ThumbnailBuilder = ThumbnailBuilder
Builders.SeparatorBuilder = SeparatorBuilder
Builders.SectionBuilder = SectionBuilder
Builders.ContainerBuilder = ContainerBuilder
Builders.MessageBuilder = MessageBuilder

Builders.OptionType = Constants.OptionType
Builders.ComponentType = Constants.ComponentType
Builders.ButtonStyle = Constants.ButtonStyle
Builders.SeparatorSpacing = Constants.SeparatorSpacing
Builders.MessageFlags = Constants.MessageFlags

return Builders
end function __BUNDLER_FILES__.c():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.c if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.c=v end return v.c end end do local function __modImpl()


local Utils = __BUNDLER_FILES__.b()

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

local function assertObject(value, name)
    local valueType = type(value)

    if valueType ~= "table" and valueType ~= "userdata" then
        error(("%s must be table or userdata, got %s"):format(name, valueType), 3)
    end
end

local function callMethod(target, methodName, ...)
    local method = getValue(target, methodName)

    if type(method) ~= "function" then
        error(("Method %s is unavailable"):format(methodName), 3)
    end

    return method(target, ...)
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

    for _, requestFunction in ipairs(candidates) do
        if type(requestFunction) == "function" then
            return requestFunction
        end
    end

    error("No HTTP request function found. Expected request, http_request, http.request, or syn.request.", 2)
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

    error("No WebSocket connector found. Expected WebSocket.connect.", 2)
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

    error(("WebSocket event %s is not supported. Expected %s:Connect(callback)."):format(eventName, eventName), 2)
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
    local spawnFunction = getValue(taskLibrary, "spawn") or getValue(environment, "spawn")

    if type(spawnFunction) ~= "function" then
        error("No spawn function found. Expected task.spawn or spawn.", 2)
    end

    return spawnFunction(callback)
end

function Runtime.cancel(thread)
    local environment = getEnvironment()
    local taskLibrary = getValue(environment, "task")
    local cancel = getValue(taskLibrary, "cancel")

    if thread ~= nil and type(cancel) == "function" then
        cancel(thread)
    end
end

function Runtime.wait(seconds)
    Utils.assertNumber(seconds, "seconds")

    local environment = getEnvironment()
    local taskLibrary = getValue(environment, "task")
    local waitFunction = getValue(taskLibrary, "wait") or getValue(environment, "wait")

    if type(waitFunction) == "function" then
        return waitFunction(seconds)
    end

    error("No wait function found. Expected task.wait or wait.", 2)
end

function Runtime.unpack(values, firstIndex, lastIndex)
    Utils.assertTable(values, "values")
    Utils.assertNumber(firstIndex, "firstIndex")
    Utils.assertNumber(lastIndex, "lastIndex")

    local environment = getEnvironment()
    local tableLibrary = getValue(environment, "table")
    local unpackFunction = getValue(tableLibrary, "unpack") or getValue(environment, "unpack")

    if type(unpackFunction) == "function" then
        return unpackFunction(values, firstIndex, lastIndex)
    end

    error("No unpack function found. Expected table.unpack or unpack.", 2)
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
end function __BUNDLER_FILES__.d():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.d if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.d=v end return v.c end end do local function __modImpl()
local Constants = __BUNDLER_FILES__.a()
local Runtime = __BUNDLER_FILES__.d()
local Utils = __BUNDLER_FILES__.b()

local CommandHandler = {}
CommandHandler.__index = CommandHandler

local function commandData(options)
    if options.data then
        local data = Utils.toJSONValue(options.data, "options.data")
        Utils.assertTable(data, "options.data")
        return data
    end

    return {
        type = Constants.ApplicationCommandType.ChatInput,
        name = options.name,
        description = options.description,
        options = options.options
    }
end

local function getUser(interaction)
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

local function createCommandInteraction(self, interaction)
    return {
        id = interaction.id,
        token = interaction.token,
        type = interaction.type,
        commandName = interaction.data and interaction.data.name or nil,
        user = getUser(interaction),
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
        end
    }
end

local function createComponentInteraction(self, interaction)
    return {
        id = interaction.id,
        token = interaction.token,
        type = interaction.type,
        customId = interaction.data and interaction.data.custom_id or nil,
        user = getUser(interaction),
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

    local data = commandData(options)
    Utils.assertNonEmptyString(data.name, "command.name")
    Utils.assertNonEmptyString(data.description, "command.description")

    self.commands[data.name] = {
        data = data,
        execute = options.execute
    }

    print(("[COMMAND] Loaded /%s"):format(data.name))
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
    local payload = {}

    for _, command in pairs(self.commands) do
        table.insert(payload, command.data)
    end

    self.rest:registerCommands(payload)
    print(("[COMMANDS] Registered %d command(s)"):format(#payload))
end

function CommandHandler:handleInteraction(interaction)
    Utils.assertTable(interaction, "interaction")

    if interaction.type == Constants.InteractionType.ApplicationCommand then
        self:handleCommand(interaction)
    elseif interaction.type == Constants.InteractionType.MessageComponent then
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

    local wrapped = createCommandInteraction(self, interaction)
    local success, err = pcall(function()
        command.execute(wrapped)
    end)

    if success then
        return
    end

    Runtime.warn(("[COMMAND] /%s failed: %s"):format(tostring(name), tostring(err)))

    pcall(function()
        wrapped.reply({
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
        execute(createComponentInteraction(self, interaction))
    end)

    if not success then
        Runtime.warn(("[BUTTON] %s failed: %s"):format(customId, tostring(err)))
    end
end

return CommandHandler
end function __BUNDLER_FILES__.e():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.e if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.e=v end return v.c end end do local function __modImpl()
local Constants = __BUNDLER_FILES__.a()
local Runtime = __BUNDLER_FILES__.d()
local Utils = __BUNDLER_FILES__.b()

local Gateway = {}
Gateway.__index = Gateway

local FATAL_CLOSE_CODES = {
    [Constants.CloseCode.AuthenticationFailed] = true,
    [Constants.CloseCode.InvalidShard] = true,
    [Constants.CloseCode.ShardingRequired] = true,
    [Constants.CloseCode.InvalidIntents] = true,
    [Constants.CloseCode.DisallowedIntents] = true
}

local function log(message)
    print(("[GATEWAY] %s"):format(message))
end

local function warnLog(message)
    Runtime.warn(("[GATEWAY] %s"):format(message))
end

local function normalizeGatewayUrl(url)
    Utils.assertNonEmptyString(url, "url")

    if string.find(url, "?", 1, true) then
        return url
    end

    return url .. "?v=10&encoding=json"
end

local function canReconnect(code)
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
    self.intents = intents or Constants.Discord.DefaultIntents
    self.ws = nil
    self.events = {}
    self.state = "idle"
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
    return self
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
            callback(Runtime.unpack(args, 1, argCount))
        end)
    end
end

function Gateway:send(op, data)
    Utils.assertNumber(op, "op")

    if not self.ws then
        error(("Cannot send gateway opcode %s before websocket is open."):format(tostring(op)), 2)
    end

    Runtime.sendWebSocket(self.ws, Utils.jsonEncode({
        op = op,
        d = data
    }))
end

function Gateway:identify()
    log("Sending Identify")

    self:send(Constants.Opcode.Identify, {
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

    self:send(Constants.Opcode.Resume, {
        token = self.token,
        session_id = self.sessionId,
        seq = self.lastSequence
    })
end

function Gateway:heartbeat()
    self.lastHeartbeatAcked = false
    self:send(Constants.Opcode.Heartbeat, self.lastSequence)
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

    log(("op=%s event=%s seq=%s"):format(tostring(payload.op), tostring(payload.t), tostring(payload.s)))

    if payload.op == Constants.Opcode.Hello then
        self:handleHello(payload.d)
    elseif payload.op == Constants.Opcode.Heartbeat then
        self:heartbeat()
    elseif payload.op == Constants.Opcode.HeartbeatAck then
        self.lastHeartbeatAcked = true
    elseif payload.op == Constants.Opcode.Dispatch then
        self:handleDispatch(payload.t, payload.d)
    elseif payload.op == Constants.Opcode.Reconnect then
        warnLog("Discord requested reconnect")
        self:reconnect(true)
    elseif payload.op == Constants.Opcode.InvalidSession then
        warnLog(("Invalid session resumable=%s"):format(tostring(payload.d)))
        Runtime.wait(5)
        self:reconnect(payload.d == true)
    end
end

function Gateway:handleMessage(message)
    Utils.assertNonEmptyString(message, "message")
    self:handlePayload(Utils.jsonDecode(message))
end

function Gateway:connectSocket(url, resume)
    Utils.assertNonEmptyString(url, "url")
    Utils.assertBoolean(resume, "resume")

    local connect = Runtime.resolveWebSocketConnect()
    local resolvedUrl = normalizeGatewayUrl(url)

    self.state = "connecting"
    self.resumeOnHello = resume
    self.intentionalClose = false

    log(("Connecting %s"):format(resolvedUrl))
    self.ws = connect(resolvedUrl)

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
    self:connectSocket(Constants.Discord.GatewayUrl, false)
end

function Gateway:handleClose(code, reason)
    warnLog(("Disconnected code=%s reason=%s"):format(tostring(code), tostring(reason)))
    self:stopHeartbeat()
    self.ws = nil
    self.heartbeatInterval = nil
    self.lastHeartbeatAcked = true
    self.state = "disconnected"
    self:emit("disconnect", code, reason)

    if self.intentionalClose or not canReconnect(code) then
        return
    end

    Runtime.spawn(function()
        Runtime.wait(5)
        self:reconnect(self.sessionId ~= nil)
    end)
end

function Gateway:connect()
    if self.ws then
        error("Gateway is already connected.", 2)
    end

    self:connectSocket(Constants.Discord.GatewayUrl, false)
end

function Gateway:close()
    self.intentionalClose = true
    self.state = "closed"
    self:closeCurrentSocket()
end

return Gateway
end function __BUNDLER_FILES__.f():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.f if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.f=v end return v.c end end do local function __modImpl()
local Constants = __BUNDLER_FILES__.a()
local Runtime = __BUNDLER_FILES__.d()
local Utils = __BUNDLER_FILES__.b()

local Rest = {}
Rest.__index = Rest

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
    if requestError or not response then
        return true
    end

    return response.StatusCode == 429 or response.StatusCode >= 500
end

local function formatError(method, endpoint, response, requestError)
    if requestError then
        return ("Discord REST failed: method=%s endpoint=%s requestError=%s"):format(method, endpoint, tostring(requestError))
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
    self.request = nil
    self.maxRetries = 3
    return self
end

function Rest:requestJson(method, endpoint, body)
    Utils.assertNonEmptyString(method, "method")
    Utils.assertNonEmptyString(endpoint, "endpoint")

    local requestFunction = self.request
    if not requestFunction then
        requestFunction = Runtime.resolveRequest()
        self.request = requestFunction
    end

    local lastResponse = nil
    local lastError = nil

    for attempt = 1, self.maxRetries do
        local requestBody = encodeBody(body)
        local success, response = pcall(function()
            return requestFunction({
                Url = Constants.Discord.ApiUrl .. endpoint,
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
            error(formatError(method, endpoint, lastResponse, lastError), 2)
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

    error(formatError(method, endpoint, lastResponse, lastError), 2)
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

function Rest:replyInteraction(interactionId, interactionToken, options)
    Utils.assertNonEmptyString(interactionId, "interactionId")
    Utils.assertNonEmptyString(interactionToken, "interactionToken")

    local message = Utils.normalizeMessageOptions(options)

    return self:requestJson("POST", "/interactions/" .. interactionId .. "/" .. interactionToken .. "/callback", {
        type = Constants.InteractionResponseType.ChannelMessageWithSource,
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
        type = Constants.InteractionResponseType.DeferredChannelMessageWithSource,
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
        type = Constants.InteractionResponseType.UpdateMessage,
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
        type = Constants.InteractionResponseType.DeferredUpdateMessage
    })
end

return Rest
end function __BUNDLER_FILES__.g():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.g if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.g=v end return v.c end end do local function __modImpl()
local CommandHandler = __BUNDLER_FILES__.e()
local Gateway = __BUNDLER_FILES__.f()
local Rest = __BUNDLER_FILES__.g()
local Runtime = __BUNDLER_FILES__.d()
local Utils = __BUNDLER_FILES__.b()

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
end function __BUNDLER_FILES__.h():typeof(__modImpl())local v=__BUNDLER_FILES__.cache.h if not v then v={c=__modImpl()}__BUNDLER_FILES__.cache.h=v end return v.c end end end
local Builders = __BUNDLER_FILES__.c()
local Client = __BUNDLER_FILES__.h()
local Constants = __BUNDLER_FILES__.a()
local Runtime = __BUNDLER_FILES__.d()
local Utils = __BUNDLER_FILES__.b()

return {
    Builders = Builders,
    Client = Client,
    Constants = Constants,
    Runtime = Runtime,
    Utils = Utils,
    version = "2.0.0"
}
