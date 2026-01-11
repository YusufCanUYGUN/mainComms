-- MainCominotor Single-Paste Installer
-- Paste this entire file into: edit /home/install.lua
-- Then run: /home/install.lua

local fs = require("filesystem")

local function writeFile(path, content)
    local dir = path:match("(.+)/[^/]+$")
    if dir then fs.makeDirectory(dir) end
    local f = io.open(path, "w")
    f:write(content)
    f:close()
    print("Created: " .. path)
end

print("Installing MainCominotor...")
fs.makeDirectory("/home/lib")

-- CONFIG
writeFile("/home/config.lua", [[
local config = {
    server = {
        url = "https://uygunfamily.duckdns.org/portakalapi",
        apiKey = "YOUR_API_KEY_HERE",
        timeout = 10
    },
    battery = {lowThreshold = 20, highThreshold = 90},
    reactor = {updateInterval = 5, shutdownOnOverheat = true, overheatThreshold = 80},
    display = {enabled = true, refreshRate = 1, showDebug = false, touchEnabled = true},
    reactors = {
        -- {name = "Reactor 1", address = "UUID-HERE"},
    },
    batteries = {
        -- {name = "Battery", address = "UUID-HERE", type = "gt"},
    },
}
return config
]])

-- API LIBRARY
writeFile("/home/lib/api.lua", [[
local component = require("component")
local internet = component.internet
local api = {}

function api.request(config, method, endpoint, data)
    local url = config.server.url .. endpoint
    local headers = {["X-API-Key"] = config.server.apiKey, ["Content-Type"] = "application/json"}
    local body = data and api.toJson(data) or nil
    local success, result = pcall(function()
        local handle = method == "GET" and internet.request(url, nil, headers) or internet.request(url, body, headers, method)
        if not handle then return nil end
        local timeout, startTime = config.server.timeout or 10, os.time()
        while true do
            local status, err = handle.finishConnect()
            if status then break elseif status == nil then return nil end
            if os.time() - startTime > timeout then handle.close() return nil end
            os.sleep(0.1)
        end
        local response = ""
        while true do local chunk = handle.read() if chunk then response = response .. chunk else break end end
        handle.close()
        return response
    end)
    return success and result or nil
end

function api.toJson(tbl)
    if type(tbl) ~= "table" then
        if type(tbl) == "string" then return '"' .. tbl:gsub('"', '\\"') .. '"'
        elseif type(tbl) == "boolean" then return tbl and "true" or "false"
        else return tostring(tbl) end
    end
    local isArray, maxIndex = true, 0
    for k, v in pairs(tbl) do
        if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then isArray = false break end
        maxIndex = math.max(maxIndex, k)
    end
    isArray = isArray and maxIndex == #tbl
    local result = {}
    if isArray then for i, v in ipairs(tbl) do table.insert(result, api.toJson(v)) end return "[" .. table.concat(result, ",") .. "]"
    else for k, v in pairs(tbl) do table.insert(result, '"' .. tostring(k) .. '":' .. api.toJson(v)) end return "{" .. table.concat(result, ",") .. "}" end
end

function api.updateReactor(config, address, heatLevel, euOutput, status)
    return api.request(config, "PUT", "/opencomputers/reactormenagementV1/reactors/address/" .. address, {heatLevel = heatLevel, euOutput = euOutput, status = status})
end

function api.getReactors(config) return api.request(config, "GET", "/opencomputers/reactormenagementV1/reactors", nil) end

function api.updateBattery(config, address, currentEU, maxEU)
    return api.request(config, "PUT", "/opencomputers/batterymanagement/status/address/" .. address, {currentEU = currentEU, maxEU = maxEU})
end

function api.setControlMode(config, address, mode)
    return api.request(config, "POST", "/opencomputers/reactormenagementV1/reactors/address/" .. address .. "/control-mode", {controlMode = mode})
end

return api
]])

-- DRAW LIBRARY
writeFile("/home/lib/draw.lua", [[
local unicode = require("unicode")
local draw = {}
draw.colors = {background = 0x1a1a2e, card = 0x16213e, text = 0xeeeeee, textDim = 0x888888, primary = 0xe94560, success = 0x28a745, warning = 0xffc107, danger = 0xdc3545, offline = 0x6c757d}

function draw.init(gpu, w, h)
    draw.gpu, draw.width, draw.height = gpu, w, h
    if gpu.maxDepth() >= 8 then gpu.setDepth(8) elseif gpu.maxDepth() >= 4 then gpu.setDepth(4) end
    draw.clear()
end

function draw.clear() draw.gpu.setBackground(draw.colors.background) draw.gpu.fill(1, 1, draw.width, draw.height, " ") end
function draw.text(x, y, text, color) if color then draw.gpu.setForeground(color) end draw.gpu.set(x, y, text) end
function draw.centerText(y, text, color) draw.text(math.floor((draw.width - unicode.len(text)) / 2) + 1, y, text, color) end
function draw.box(x, y, w, h, bg) draw.gpu.setBackground(bg or draw.colors.card) draw.gpu.fill(x, y, w, h, " ") draw.gpu.setBackground(draw.colors.background) end

return draw
]])

-- GUI
writeFile("/home/gui.lua", [[
local component = require("component")
local event = require("event")
local computer = require("computer")
local unicode = require("unicode")
local draw = require("lib/draw")
local gui = {}

local ControlMode = {DISABLED = "DISABLED", AUTO = "AUTO", FORCE_ACTIVE = "FORCE_ACTIVE"}
local state = {data = nil, selectedReactor = nil, view = "dashboard", touchAreas = {}, running = true}
local callbacks = {getData = nil, setControlMode = nil, tick = nil}

function gui.init(config)
    local gpu, screen = component.gpu, component.screen
    if config.gpu then gpu = component.proxy(config.gpu) end
    if config.screen then screen = component.proxy(config.screen) end
    gpu.bind(screen.address)
    local w, h = gpu.getResolution()
    draw.init(gpu, w, h)
    gui.gpu, gui.width, gui.height, gui.config = gpu, w, h, config
    return true
end

local function addTouchArea(x, y, w, h, action, data) table.insert(state.touchAreas, {x=x, y=y, width=w, height=h, action=action, data=data}) end
local function clearTouchAreas() state.touchAreas = {} end

local function getModeColor(mode)
    if mode == ControlMode.DISABLED then return draw.colors.danger
    elseif mode == ControlMode.FORCE_ACTIVE then return draw.colors.warning
    else return 0x17a2b8 end
end

local function getStatusColor(status)
    if status == "ONLINE" then return draw.colors.success
    elseif status == "ERROR" then return draw.colors.danger
    else return draw.colors.offline end
end

local function drawButton(x, y, w, text, bg, fg, action, data)
    draw.gpu.setBackground(bg) draw.gpu.setForeground(fg or draw.colors.text)
    draw.gpu.fill(x, y, w, 1, " ")
    draw.gpu.set(x + math.floor((w - unicode.len(text)) / 2), y, text)
    draw.gpu.setBackground(draw.colors.background) draw.gpu.setForeground(draw.colors.text)
    addTouchArea(x, y, w, 1, action, data)
end

local function renderDashboard()
    clearTouchAreas() draw.clear()
    local data = state.data
    if not data then return end
    draw.gpu.setBackground(draw.colors.card) draw.gpu.fill(1, 1, gui.width, 2, " ")
    draw.text(2, 1, "MainCominotor", draw.colors.primary)
    draw.text(gui.width - 12, 1, data.serverConnected and "CONNECTED" or "OFFLINE", data.serverConnected and draw.colors.success or draw.colors.danger)
    draw.gpu.setBackground(draw.colors.background)
    local y = 4
    draw.text(2, y, "REACTORS", draw.colors.textDim) y = y + 1
    for i, reactor in ipairs(data.reactors or {}) do
        if y + 3 > gui.height - 1 then break end
        draw.box(2, y, gui.width - 3, 3, draw.colors.card)
        draw.text(3, y, reactor.name, draw.colors.text)
        addTouchArea(2, y, gui.width - 3, 3, "select_reactor", i)
        draw.gpu.setBackground(getStatusColor(reactor.status)) draw.gpu.set(20, y, " " .. reactor.status .. " ") draw.gpu.setBackground(draw.colors.background)
        draw.text(3, y + 1, "Heat: " .. (reactor.heatLevel or 0) .. "%  EU: " .. (reactor.euOutput or 0), draw.colors.textDim)
        local btnX = gui.width - 28
        drawButton(btnX, y + 2, 8, "AUTO", reactor.controlMode == ControlMode.AUTO and 0x17a2b8 or 0x2a2a4a, draw.colors.text, "set_mode", {reactor = i, mode = ControlMode.AUTO})
        drawButton(btnX + 9, y + 2, 8, "OFF", reactor.controlMode == ControlMode.DISABLED and draw.colors.danger or 0x2a2a4a, draw.colors.text, "set_mode", {reactor = i, mode = ControlMode.DISABLED})
        drawButton(btnX + 18, y + 2, 8, "FORCE", reactor.controlMode == ControlMode.FORCE_ACTIVE and draw.colors.warning or 0x2a2a4a, draw.colors.text, "set_mode", {reactor = i, mode = ControlMode.FORCE_ACTIVE})
        y = y + 4
    end
    draw.gpu.setBackground(draw.colors.card) draw.gpu.fill(1, gui.height, gui.width, 1, " ")
    draw.text(2, gui.height, "Q=Quit  Touch buttons to control", draw.colors.textDim)
    draw.gpu.setBackground(draw.colors.background)
end

local function handleTouch(x, y)
    for _, area in ipairs(state.touchAreas) do
        if x >= area.x and x < area.x + area.width and y >= area.y and y < area.y + area.height then
            if area.action == "set_mode" and callbacks.setControlMode and state.data and state.data.reactors then
                local reactor = state.data.reactors[area.data.reactor]
                if reactor then callbacks.setControlMode(reactor, area.data.mode) reactor.controlMode = area.data.mode end
            end
            return true
        end
    end
    return false
end

function gui.run(getDataFunc, setControlModeFunc, tickFunc)
    callbacks.getData, callbacks.setControlMode, callbacks.tick = getDataFunc, setControlModeFunc, tickFunc
    local lastRender = 0
    while state.running do
        if callbacks.tick then callbacks.tick() end
        if callbacks.getData then state.data = callbacks.getData() end
        local now = computer.uptime()
        if now - lastRender >= (gui.config.display.refreshRate or 1) then renderDashboard() lastRender = now end
        local ev = {event.pull(0.1)}
        if ev[1] == "key_down" and (ev[3] == 113 or ev[3] == 81) then state.running = false
        elseif ev[1] == "touch" then handleTouch(math.floor(ev[3]), math.floor(ev[4])) renderDashboard() end
    end
    draw.clear() draw.centerText(math.floor(gui.height / 2), "Stopped", draw.colors.textDim)
end

return gui
]])

-- MAIN CONTROLLER
writeFile("/home/reactor_controller.lua", [[
local component = require("component")
local event = require("event")
local os = require("os")
local computer = require("computer")
local config = require("config")
local api = require("lib/api")
local gui = require("gui")

local ControlMode = {DISABLED = "DISABLED", AUTO = "AUTO", FORCE_ACTIVE = "FORCE_ACTIVE"}
local state = {reactors = {}, batteries = {}, serverConnected = false, running = true, lastServerSync = 0}

local function getProxy(addr) if not addr or addr == "" then return nil end local s, p = pcall(function() return component.proxy(addr) end) return s and p or nil end

local function initReactors()
    state.reactors = {}
    for i, rc in ipairs(config.reactors or {}) do
        table.insert(state.reactors, {name = rc.name or ("Reactor " .. i), address = rc.address, component = getProxy(rc.address), redstoneComponent = getProxy(rc.redstoneAddress), redstoneSide = rc.redstoneSide, controlMode = ControlMode.AUTO})
    end
    return #state.reactors
end

local function initBatteries()
    state.batteries = {}
    for i, bc in ipairs(config.batteries or {}) do
        table.insert(state.batteries, {name = bc.name or ("Battery " .. i), address = bc.address, type = bc.type or "gt", component = getProxy(bc.address)})
    end
    return #state.batteries
end

local function getReactorData(reactor)
    local data = {address = reactor.address, name = reactor.name, controlMode = reactor.controlMode, heatLevel = 0, euOutput = 0, status = "OFFLINE", isRunning = false}
    local comp = reactor.component
    if not comp then data.status = "ERROR" return data end
    pcall(function()
        data.isRunning = comp.producesEnergy and comp.producesEnergy() or false
        local heat = comp.getHeat and comp.getHeat() or 0
        local maxHeat = comp.getMaxHeat and comp.getMaxHeat() or 1
        data.heatLevel = math.floor(heat * 100 / maxHeat)
        data.euOutput = comp.getReactorEUOutput and comp.getReactorEUOutput() or 0
        data.status = data.isRunning and "ONLINE" or (data.heatLevel > 80 and "ERROR" or "OFFLINE")
    end)
    return data
end

local function getBatteryData(battery)
    local data = {address = battery.address, name = battery.name, currentEU = 0, maxEU = 1, chargePercent = 0}
    local comp = battery.component
    if not comp then return data end
    pcall(function()
        if battery.type == "gt" then data.currentEU = comp.getStoredEU and comp.getStoredEU() or 0 data.maxEU = comp.getEUMaxStored and comp.getEUMaxStored() or 1
        else data.currentEU = comp.getEnergy and comp.getEnergy() or 0 data.maxEU = comp.getCapacity and comp.getCapacity() or 1 end
        data.chargePercent = math.floor(data.currentEU * 100 / math.max(data.maxEU, 1))
    end)
    return data
end

local function getAverageBatteryCharge()
    if #state.batteries == 0 then return 50 end
    local total = 0
    for _, b in ipairs(state.batteries) do total = total + getBatteryData(b).chargePercent end
    return math.floor(total / #state.batteries)
end

local function setReactorState(reactor, enabled)
    if reactor.component and reactor.component.setActive then pcall(function() reactor.component.setActive(enabled) end) end
    if reactor.redstoneComponent and reactor.redstoneSide then pcall(function() reactor.redstoneComponent.setOutput(reactor.redstoneSide, enabled and 15 or 0) end) end
end

local function manageReactors()
    local avgCharge = getAverageBatteryCharge()
    local low, high = config.battery.lowThreshold, config.battery.highThreshold
    for _, reactor in ipairs(state.reactors) do
        local data = getReactorData(reactor)
        if data.heatLevel > config.reactor.overheatThreshold then setReactorState(reactor, false)
        elseif reactor.controlMode == ControlMode.DISABLED then setReactorState(reactor, false)
        elseif reactor.controlMode == ControlMode.FORCE_ACTIVE then setReactorState(reactor, true)
        else setReactorState(reactor, avgCharge < high and avgCharge < low or avgCharge < (low + high) / 2) end
    end
end

local function syncWithServer()
    if not component.isAvailable("internet") then state.serverConnected = false return end
    local success = true
    for _, reactor in ipairs(state.reactors) do
        local data = getReactorData(reactor)
        if not api.updateReactor(config, reactor.address, data.heatLevel, data.euOutput, data.status) then success = false end
    end
    for _, battery in ipairs(state.batteries) do
        local data = getBatteryData(battery)
        if not api.updateBattery(config, battery.address, data.currentEU, data.maxEU) then success = false end
    end
    state.serverConnected = success
    state.lastServerSync = computer.uptime()
end

local function setReactorControlMode(reactor, mode) reactor.controlMode = mode if component.isAvailable("internet") then api.setControlMode(config, reactor.address, mode) end end

local function getGuiData()
    local rd, bd = {}, {}
    for _, r in ipairs(state.reactors) do local d = getReactorData(r) d.controlMode = r.controlMode table.insert(rd, d) end
    for _, b in ipairs(state.batteries) do table.insert(bd, getBatteryData(b)) end
    return {reactors = rd, batteries = bd, serverConnected = state.serverConnected, avgBatteryCharge = getAverageBatteryCharge()}
end

local function main()
    print("MainCominotor Reactor Controller")
    print("================================")
    local rc, bc = initReactors(), initBatteries()
    print("Reactors: " .. rc .. "  Batteries: " .. bc)
    if rc == 0 then print("No reactors! Edit /home/config.lua") return end
    print("Connecting to server...")
    syncWithServer()
    print(state.serverConnected and "Connected!" or "Offline mode")
    if config.display.enabled then
        print("Starting GUI...")
        gui.init(config)
        gui.run(getGuiData, setReactorControlMode, function()
            manageReactors()
            if computer.uptime() - state.lastServerSync >= config.reactor.updateInterval then syncWithServer() end
        end)
    else
        print("Headless mode. Ctrl+C to stop.")
        while state.running do manageReactors() if computer.uptime() - state.lastServerSync >= config.reactor.updateInterval then syncWithServer() end os.sleep(1) end
    end
end

pcall(main)
]])

print("")
print("========================================")
print("  Installation Complete!")
print("========================================")
print("")
print("NEXT STEPS:")
print("1. Run: components")
print("2. Edit: edit /home/config.lua")
print("3. Add your API key and component addresses")
print("4. Run: /home/reactor_controller.lua")
print("")