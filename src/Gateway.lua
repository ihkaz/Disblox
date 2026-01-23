
local Utils = require("./Utils")

local Gateway = {}
Gateway.__index = Gateway

function Gateway.new(token)
    local self = setmetatable({}, Gateway)
    self.token = token
    self.ws = nil
    self.heartbeatInterval = nil
    self.lastSequence = nil
    self.sessionId = nil
    self.heartbeatTask = nil
    self.events = {}
    return self
end

function Gateway:on(eventName, callback)
    if not self.events[eventName] then
        self.events[eventName] = {}
    end
    table.insert(self.events[eventName], callback)
end

function Gateway:emit(eventName, ...)
    if self.events[eventName] then
        for _, callback in ipairs(self.events[eventName]) do
            task.spawn(callback, ...)
        end
    end
end

function Gateway:send(op, data)
    local payload = {op = op, d = data}
    self.ws:Send(Utils.jsonEncode(payload))
end

function Gateway:startHeartbeat()
    if self.heartbeatTask then
        task.cancel(self.heartbeatTask)
    end
    
    self.heartbeatTask = task.spawn(function()
        while self.ws and self.heartbeatInterval do
            wait(self.heartbeatInterval / 1000)
            self:send(1, self.lastSequence)
        end
    end)
end

function Gateway:identify()
    self:send(2, {
        token = self.token,
        intents = 33281,
        properties = {
            ["$os"] = "windows",
            ["$browser"] = "discord.lua",
            ["$device"] = "discord.lua"
        }
    })
end

function Gateway:connect()
    print("[GATEWAY] Connecting...")
    
    self.ws = Websocket.connect("wss://gateway.discord.gg/?v=10&encoding=json")
    
    self.ws.OnMessage:Connect(function(msg)
        local data = Utils.jsonDecode(msg)
        if not data then return end
        
        if data.s then
            self.lastSequence = data.s
        end
        
        if data.op == 10 then
            print("[HELLO] Received")
            self.heartbeatInterval = data.d.heartbeat_interval
            self:identify()
            self:startHeartbeat()
            
        elseif data.op == 11 then
            -- Heartbeat ACK
            
        elseif data.op == 0 then
            self:emit(data.t, data.d)
            
        elseif data.op == 9 then
            warn("[INVALID SESSION]")
            wait(5)
            self:identify()
        end
    end)
    
    self.ws.OnClose:Connect(function()
        warn("[DISCONNECTED]")
        if self.heartbeatTask then
            task.cancel(self.heartbeatTask)
        end
        self:emit("disconnect")
    end)
    
    print("[GATEWAY] Connected")
end

return Gateway
