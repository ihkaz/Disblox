local Constants = require("./Constants")
local Runtime = require("./Runtime")
local Utils = require("./Utils")

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
            ["$os"] = "windows",
            ["$browser"] = "disblox",
            ["$device"] = "disblox"
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

    Runtime.connectEvent(socket, "OnMessage", function(...)
        if self.ws ~= socket then
            return
        end

        local arguments = { ... }

        local success, err = pcall(function()
            local message = Runtime.firstString(Runtime.unpack(arguments, 1, #arguments))
            self:handleMessage(message)
        end)

        if not success then
            warnLog(("Message handler failed: %s"):format(tostring(err)))
            self:emit("error", err)
        end
    end)

    Runtime.connectEvent(socket, "OnClose", function(...)
        if self.ws ~= socket then
            return
        end

        local arguments = { ... }
        local code = Runtime.firstNumber(Runtime.unpack(arguments, 1, #arguments))
        local reason = nil
        local argumentCount = #arguments

        for index = 1, argumentCount do
            local value = arguments[index]

            if type(value) == "string" then
                reason = value
                break
            end
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
