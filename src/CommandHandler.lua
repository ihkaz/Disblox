
local Utils = require("./Utils")

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
