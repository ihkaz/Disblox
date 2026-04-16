local Constants = require("./Constants")
local Runtime = require("./Runtime")
local Utils = require("./Utils")

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
