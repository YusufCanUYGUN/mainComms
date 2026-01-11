-- API Library for MainCominotor
-- Handles communication with the server

local component = require("component")
local internet = component.internet
local serialization = require("serialization")

local api = {}

-- HTTP request helper
function api.request(config, method, endpoint, data)
    local url = config.server.url .. endpoint
    local headers = {
        ["X-API-Key"] = config.server.apiKey,
        ["Content-Type"] = "application/json"
    }

    local body = nil
    if data then
        body = serialization.serialize(data)
        -- Convert Lua table to JSON-like format
        body = api.toJson(data)
    end

    local success, result = pcall(function()
        local handle
        if method == "GET" then
            handle = internet.request(url, nil, headers)
        else
            handle = internet.request(url, body, headers, method)
        end

        if not handle then
            return nil, "Failed to create request"
        end

        -- Wait for response
        local timeout = config.server.timeout or 10
        local startTime = os.time()
        while true do
            local status, err = handle.finishConnect()
            if status then
                break
            elseif status == nil then
                return nil, err or "Connection failed"
            end
            if os.time() - startTime > timeout then
                handle.close()
                return nil, "Request timeout"
            end
            os.sleep(0.1)
        end

        -- Read response
        local response = ""
        while true do
            local chunk = handle.read()
            if chunk then
                response = response .. chunk
            else
                break
            end
        end
        handle.close()

        return response
    end)

    if not success then
        return nil, result
    end

    return result
end

-- Convert Lua table to JSON string
function api.toJson(tbl)
    if type(tbl) ~= "table" then
        if type(tbl) == "string" then
            return '"' .. tbl:gsub('"', '\\"') .. '"'
        elseif type(tbl) == "boolean" then
            return tbl and "true" or "false"
        else
            return tostring(tbl)
        end
    end

    local isArray = true
    local maxIndex = 0
    for k, v in pairs(tbl) do
        if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
            isArray = false
            break
        end
        maxIndex = math.max(maxIndex, k)
    end
    isArray = isArray and maxIndex == #tbl

    local result = {}
    if isArray then
        for i, v in ipairs(tbl) do
            table.insert(result, api.toJson(v))
        end
        return "[" .. table.concat(result, ",") .. "]"
    else
        for k, v in pairs(tbl) do
            table.insert(result, '"' .. tostring(k) .. '":' .. api.toJson(v))
        end
        return "{" .. table.concat(result, ",") .. "}"
    end
end

-- Parse JSON response (simple parser)
function api.parseJson(str)
    -- Simple JSON parser for our use case
    local func, err = load("return " .. str:gsub('":"', "'='"):gsub('"', "'"):gsub("null", "nil"):gsub("true", "true"):gsub("false", "false"))
    if func then
        local success, result = pcall(func)
        if success then
            return result
        end
    end
    return nil, "Failed to parse JSON"
end

-- API Endpoints

-- Register a reactor
function api.registerReactor(config, name, address)
    local data = {
        name = name,
        address = address
    }
    return api.request(config, "POST", "/opencomputers/reactormenagementV1/reactors", data)
end

-- Update reactor data
function api.updateReactor(config, address, heatLevel, euOutput, status)
    local data = {
        heatLevel = heatLevel,
        euOutput = euOutput,
        status = status
    }
    return api.request(config, "PUT", "/opencomputers/reactormenagementV1/reactors/address/" .. address, data)
end

-- Get all reactors
function api.getReactors(config)
    return api.request(config, "GET", "/opencomputers/reactormenagementV1/reactors", nil)
end

-- Register a battery
function api.registerBattery(config, name, address)
    local data = {
        name = name,
        address = address
    }
    return api.request(config, "POST", "/opencomputers/batterymanagement/register", data)
end

-- Update battery data
function api.updateBattery(config, address, currentEU, maxEU)
    local data = {
        currentEU = currentEU,
        maxEU = maxEU
    }
    return api.request(config, "PUT", "/opencomputers/batterymanagement/status/address/" .. address, data)
end

-- Get battery status
function api.getBatteryStatus(config)
    return api.request(config, "GET", "/opencomputers/batterymanagement/status", nil)
end

-- Get all batteries
function api.getBatteries(config)
    return api.request(config, "GET", "/opencomputers/batterymanagement/batteries", nil)
end

-- Get reactor recommendation
function api.getReactorRecommendation(config)
    return api.request(config, "GET", "/opencomputers/batterymanagement/reactor-recommendation", nil)
end

-- Set reactor control mode
function api.setControlMode(config, address, mode)
    local data = {
        controlMode = mode
    }
    return api.request(config, "POST", "/opencomputers/reactormenagementV1/reactors/address/" .. address .. "/control-mode", data)
end

return api
