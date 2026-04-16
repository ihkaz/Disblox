local Constants = {}

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
