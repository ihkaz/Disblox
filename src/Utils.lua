--!nolint DeprecatedApi

local Constants = require("./Constants")

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
