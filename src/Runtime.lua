--!nolint DeprecatedApi

local Utils = require("./Utils")

local Runtime = {}

local function getEnvironment()
    local success, environment = pcall(function()
        return getfenv(0)
    end)

    if success and type(environment) == "table" then
        return environment
    end

    return _G
end

local function getValue(container, key)
    if type(container) ~= "table" and type(container) ~= "userdata" then
        return nil
    end

    local success, value = pcall(function()
        return container[key]
    end)

    if success then
        return value
    end

    return nil
end

local function assertObject(value, name)
    local valueType = type(value)

    if valueType ~= "table" and valueType ~= "userdata" then
        error(("%s must be table or userdata, got %s"):format(name, valueType), 3)
    end
end

local function callMethod(target, methodName, ...)
    local method = getValue(target, methodName)

    if type(method) ~= "function" then
        error(("Method %s is unavailable"):format(methodName), 3)
    end

    return method(target, ...)
end

function Runtime.resolveRequest()
    local environment = getEnvironment()
    local http = getValue(environment, "http")
    local syn = getValue(environment, "syn")

    local candidates = {
        getValue(environment, "request"),
        getValue(environment, "http_request"),
        getValue(http, "request"),
        getValue(syn, "request")
    }

    for _, requestFunction in ipairs(candidates) do
        if type(requestFunction) == "function" then
            return requestFunction
        end
    end

    error("No HTTP request function found. Expected request, http_request, http.request, or syn.request.", 2)
end

function Runtime.resolveWebSocketConnect()
    local environment = getEnvironment()
    local syn = getValue(environment, "syn")

    local websocketCandidates = {
        getValue(environment, "WebSocket"),
        getValue(environment, "Websocket"),
        getValue(environment, "websocket"),
        getValue(syn, "websocket")
    }

    for _, websocket in ipairs(websocketCandidates) do
        local connect = getValue(websocket, "connect")

        if type(connect) == "function" then
            return connect
        end
    end

    error("No WebSocket connector found. Expected WebSocket.connect.", 2)
end

function Runtime.connectEvent(target, eventName, callback)
    assertObject(target, "target")
    Utils.assertNonEmptyString(eventName, "eventName")
    Utils.assertFunction(callback, "callback")

    local event = getValue(target, eventName)
    local connect = getValue(event, "Connect")

    if type(connect) == "function" then
        connect(event, callback)
        return
    end

    local success = pcall(function()
        target[eventName] = callback
    end)

    if success then
        return
    end

    error(("WebSocket event %s is not supported. Expected %s:Connect(callback)."):format(eventName, eventName), 2)
end

function Runtime.sendWebSocket(socket, payload)
    assertObject(socket, "socket")
    Utils.assertNonEmptyString(payload, "payload")

    local send = getValue(socket, "Send")

    if type(send) == "function" then
        send(socket, payload)
        return
    end

    callMethod(socket, "send", payload)
end

function Runtime.closeWebSocket(socket)
    assertObject(socket, "socket")

    local close = getValue(socket, "Close")

    if type(close) == "function" then
        close(socket)
        return
    end

    callMethod(socket, "close")
end

function Runtime.firstString(...)
    local argumentCount = select("#", ...)

    for index = 1, argumentCount do
        local value = select(index, ...)

        if type(value) == "string" then
            return value
        end
    end

    error("Expected at least one string argument.", 2)
end

function Runtime.firstNumber(...)
    local argumentCount = select("#", ...)

    for index = 1, argumentCount do
        local value = select(index, ...)

        if type(value) == "number" then
            return value
        end
    end

    return nil
end

function Runtime.spawn(callback)
    Utils.assertFunction(callback, "callback")

    local environment = getEnvironment()
    local taskLibrary = getValue(environment, "task")
    local spawnFunction = getValue(taskLibrary, "spawn") or getValue(environment, "spawn")

    if type(spawnFunction) ~= "function" then
        error("No spawn function found. Expected task.spawn or spawn.", 2)
    end

    return spawnFunction(callback)
end

function Runtime.cancel(thread)
    local environment = getEnvironment()
    local taskLibrary = getValue(environment, "task")
    local cancel = getValue(taskLibrary, "cancel")

    if thread ~= nil and type(cancel) == "function" then
        cancel(thread)
    end
end

function Runtime.wait(seconds)
    Utils.assertNumber(seconds, "seconds")

    local environment = getEnvironment()
    local taskLibrary = getValue(environment, "task")
    local waitFunction = getValue(taskLibrary, "wait") or getValue(environment, "wait")

    if type(waitFunction) == "function" then
        return waitFunction(seconds)
    end

    error("No wait function found. Expected task.wait or wait.", 2)
end

function Runtime.unpack(values, firstIndex, lastIndex)
    Utils.assertTable(values, "values")
    Utils.assertNumber(firstIndex, "firstIndex")
    Utils.assertNumber(lastIndex, "lastIndex")

    local environment = getEnvironment()
    local tableLibrary = getValue(environment, "table")
    local unpackFunction = getValue(tableLibrary, "unpack") or getValue(environment, "unpack")

    if type(unpackFunction) == "function" then
        return unpackFunction(values, firstIndex, lastIndex)
    end

    error("No unpack function found. Expected table.unpack or unpack.", 2)
end

function Runtime.warn(message, fields)
    Utils.assertNonEmptyString(message, "message")

    if fields ~= nil then
        Utils.assertTable(fields, "fields")
    end

    local environment = getEnvironment()
    local warnFunction = getValue(environment, "warn")

    if type(warnFunction) == "function" then
        warnFunction(message, fields)
        return
    end

    print(message, fields)
end

return Runtime
