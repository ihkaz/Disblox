local Constants = require("./Constants")
local Utils = require("./Utils")

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
