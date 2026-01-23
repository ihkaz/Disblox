
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
