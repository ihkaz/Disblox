local Constants = require("./Constants")
local Runtime = require("./Runtime")
local Utils = require("./Utils")

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
