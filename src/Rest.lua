
local Utils = require("./Utils")

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
