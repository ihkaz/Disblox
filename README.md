# Disblox

Disblox is an executor-compatible Luau library for building Discord bots from Roblox executor environments. It provides a Discord Gateway client, a REST client, slash command handling, interaction replies, button handlers, and Discord.js-style builders for Components v2 messages.

The runtime target is Roblox Luau with executor APIs, not standalone Lua, Luvit, or normal Roblox server scripts.

## Features

- Discord Gateway v10 login
- Gateway heartbeat, reconnect, resume, and invalid-session handling
- Slash command registration
- Slash command interaction dispatch
- Button interaction dispatch
- Interaction replies, deferred replies, original response edits, message updates, and deferred updates
- Channel message sending through REST
- Discord.js-style builders for commands, embeds, buttons, and Components v2
- Single bundled file for `loadstring(game:HttpGet(url))()`

## Requirements

Your executor must provide these APIs:

```lua
game:GetService("HttpService")
WebSocket.connect(url)
ws.OnMessage:Connect(callback)
ws.OnClose:Connect(callback)
ws:Send(payload)
request(options)
```

`request(options)` is only required for REST operations:

- registering slash commands
- replying to interactions
- editing interaction responses
- sending channel messages
- sending webhook messages

The gateway can connect without `request`, but commands and replies need HTTP request support.

Disblox also detects common aliases:

```lua
http_request(options)
http.request(options)
syn.request(options)
Websocket.connect(url)
websocket.connect(url)
syn.websocket.connect(url)
```

## Installation

Use the bundled file in `dist/bundle.lua`.

```lua
local Disblox = loadstring(game:HttpGet("https://raw.githubusercontent.com/ihkaz/Disblox/main/dist/bundle.lua"))()
```

Local edits do not affect the executor when loading from GitHub raw. Push the updated `dist/bundle.lua` to GitHub before testing through `game:HttpGet`.

## Quick Start

```lua
local Disblox = loadstring(game:HttpGet("https://raw.githubusercontent.com/ihkaz/Disblox/main/dist/bundle.lua"))()

local client = Disblox.Client.new({
    token = "YOUR_BOT_TOKEN",
    applicationId = "YOUR_APPLICATION_ID",
    intents = 1
})

client:on("ready", function()
    print(("[BOT] Ready as %s"):format(tostring(client.user and client.user.username)))
end)

client.commands:registerCommand({
    data = Disblox.Builders.SlashCommandBuilder.new()
        :setName("ping")
        :setDescription("Replies with pong."),

    execute = function(interaction)
        interaction.reply({
            content = "Pong.",
            ephemeral = true
        })
    end
})

client:login()
```

## Client

Create a client with a bot token and application ID.

```lua
local client = Disblox.Client.new({
    token = "YOUR_BOT_TOKEN",
    applicationId = "YOUR_APPLICATION_ID",
    intents = 1
})
```

### Options

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `token` | `string` | Yes | Discord bot token. |
| `applicationId` | `string` | Yes | Discord application ID. |
| `intents` | `number` | No | Gateway intent bitfield. Defaults to `1` (`Guilds`). |

### Methods

| Method | Description |
| --- | --- |
| `client:on(eventName, callback)` | Registers an event listener. |
| `client:login()` | Opens the Discord Gateway connection. |
| `client:destroy()` | Closes the active gateway connection. |

### Events

| Event | Payload | Description |
| --- | --- | --- |
| `ready` | `READY` dispatch data | Fired after Discord sends `READY`. |
| `resumed` | `RESUMED` dispatch data | Fired after a session resumes. |
| `interactionCreate` | raw interaction table | Fired for every interaction before command dispatch. |
| `messageCreate` | raw message table | Fired for new messages when enabled by intents. |
| `reconnect` | none | Fired before reconnecting the gateway. |
| `disconnect` | `code`, `reason` | Fired when the websocket closes. |
| `error` | error value | Fired when gateway message handling fails. |

## Slash Commands

Register commands through `client.commands:registerCommand`.

```lua
local Builders = Disblox.Builders

client.commands:registerCommand({
    data = Builders.SlashCommandBuilder.new()
        :setName("echo")
        :setDescription("Repeats your text.")
        :addStringOption(function(option)
            return option
                :setName("text")
                :setDescription("Text to repeat.")
                :setRequired(true)
        end),

    execute = function(interaction)
        local text = interaction.getOption("text")

        interaction.reply({
            content = tostring(text),
            ephemeral = true
        })
    end
})
```

Commands are registered globally after `ready`. Global Discord commands can take time to appear in clients.

## Interaction Object

Slash command handlers receive an interaction wrapper.

| Field or Method | Description |
| --- | --- |
| `interaction.id` | Interaction ID. |
| `interaction.token` | Interaction token. |
| `interaction.commandName` | Slash command name. |
| `interaction.user` | User table when available. |
| `interaction.member` | Guild member table when available. |
| `interaction.guildId` | Guild ID when available. |
| `interaction.channelId` | Channel ID when available. |
| `interaction.data` | Raw interaction data. |
| `interaction.getOption(name)` | Reads an option value by name. |
| `interaction.reply(options)` | Sends an interaction response. |
| `interaction.deferReply(ephemeral)` | Defers the interaction response. |
| `interaction.defer(ephemeral)` | Alias for `deferReply`. |
| `interaction.editReply(options)` | Edits the original interaction response. |

## Button Interactions

Register a button handler by custom ID.

```lua
client.commands:registerButton("refresh_panel", function(interaction)
    interaction.reply({
        content = "Panel refreshed.",
        ephemeral = true
    })
end)
```

Button interaction wrappers provide:

| Field or Method | Description |
| --- | --- |
| `interaction.customId` | Button custom ID. |
| `interaction.message` | Source message table. |
| `interaction.reply(options)` | Sends a response. |
| `interaction.update(options)` | Updates the source message. |
| `interaction.deferUpdate()` | Defers the update. |

## Components V2

Components v2 messages must include the `IsComponentsV2` message flag. `MessageBuilder` sets this automatically.

```lua
local Builders = Disblox.Builders

local message = Builders.MessageBuilder.new()
    :addComponent(
        Builders.ContainerBuilder.new()
            :setAccentColor(Disblox.Utils.Colors.Green)
            :addComponent(
                Builders.TextDisplayBuilder.new()
                    :setContent("## System Online\nGateway and interaction routing are active.")
            )
            :addComponent(
                Builders.ActionRowBuilder.new()
                    :addComponent(
                        Builders.ButtonBuilder.new()
                            :setCustomId("refresh_panel")
                            :setLabel("Refresh")
                            :setStyle(Builders.ButtonStyle.Primary)
                    )
            )
    )

interaction.reply(message)
```

### Components V2 Builders

| Builder | Purpose |
| --- | --- |
| `MessageBuilder` | Top-level Components v2 message payload. |
| `ContainerBuilder` | Components v2 container. |
| `TextDisplayBuilder` | Markdown text component. |
| `ActionRowBuilder` | Row for button components. |
| `ButtonBuilder` | Button component. |
| `SectionBuilder` | Section with text and accessory. |
| `ThumbnailBuilder` | Thumbnail accessory for sections. |
| `SeparatorBuilder` | Visual separator. |

## Embed Builder

```lua
local embed = Disblox.Builders.EmbedBuilder.new()
    :setTitle("Status")
    :setDescription("Bot is online.")
    :setColor(Disblox.Utils.Colors.Green)
    :setImage("https://example.com/image.png")

interaction.reply({
    embeds = { embed:toJSON() },
    ephemeral = true
})
```

Executors cannot read local files from Discord. Use public image URLs for embeds, thumbnails, and Components v2 media.

## REST

The REST client is available at `client.rest`.

```lua
client.rest:sendMessage("CHANNEL_ID", {
    content = "Hello from Disblox."
})
```

REST requests retry transient failures and raise an error with method, endpoint, status code, and response body when the request fails.

## Gateway

Disblox connects to:

```text
wss://gateway.discord.gg/?v=10&encoding=json
```

Gateway behavior:

- waits for `HELLO`
- starts heartbeat with Discord's heartbeat interval
- sends `IDENTIFY`
- stores `session_id` and `resume_gateway_url` after `READY`
- sends heartbeat ACK checks
- reconnects when Discord requests reconnect
- resumes when possible
- re-identifies on invalid sessions when required

Disblox does not require shards for small bots. Use a single connection until your bot reaches Discord's sharding requirements.

## Intents

The default intent is:

```lua
intents = 1
```

That is the `Guilds` intent. Add more intents only when your bot needs additional gateway events and the Discord Developer Portal has the required privileged intents enabled.

Invalid or disallowed intents can cause gateway close codes `4013` or `4014`.

## Build

Bundle source into `dist/bundle.lua`:

```bash
darklua process src/init.lua dist/bundle.lua
```

## Validate

```bash
luau-analyze src/Constants.lua src/Utils.lua src/Runtime.lua src/Gateway.lua src/Rest.lua src/Builders.lua src/CommandHandler.lua src/Client.lua src/init.lua
luau-compile --text src/init.lua
luau-compile --text dist/bundle.lua
```

## Project Structure

```text
src/
  Constants.lua        Discord API constants
  Runtime.lua          Executor API adapter
  Utils.lua            JSON, validation, message normalization
  Gateway.lua          Discord Gateway v10 client
  Rest.lua             Discord REST client
  Builders.lua         Discord.js-style command and component builders
  CommandHandler.lua   Slash command and component dispatcher
  Client.lua           Public client facade
  init.lua             Library export

dist/
  bundle.lua           Executor-ready bundled output
```

## Troubleshooting

### Gateway connects but `ready` does not print

Check that your executor supports `WebSocket.connect`, `OnMessage`, `OnClose`, and `Send`. Also make sure your executor is loading the newest `dist/bundle.lua` from GitHub raw.

### `Disconnected code=4004`

The bot token is invalid. Regenerate the token in the Discord Developer Portal and update your script.

### `Disconnected code=4013` or `4014`

The intents are invalid or disallowed. Lower the `intents` value or enable the required privileged intents in the Discord Developer Portal.

### Commands do not appear

Global slash commands can take time to update. Also confirm that `request` works in your executor, because command registration uses Discord REST.

### Interaction reply fails

The executor likely does not expose a working HTTP request function. Disblox checks `request`, `http_request`, `http.request`, and `syn.request`.

### Images do not load

Use public HTTPS URLs. Executor scripts usually cannot upload or attach local image files directly.

## Security

Never publish your bot token. Anyone with the token can control your bot.

Use environment-specific private scripts or a private raw URL for real tokens.

## License

Add your preferred license before publishing this project as a public package.
