-- GUI Module for MainCominotor
-- Touch-capable dashboard for OpenComputers
-- Mirrors web dashboard functionality

local component = require("component")
local event = require("event")
local computer = require("computer")
local unicode = require("unicode")

local gui = {}

-- Load drawing library
local draw = require("lib/draw")

-- Control modes
local ControlMode = {
    DISABLED = "DISABLED",
    AUTO = "AUTO",
    FORCE_ACTIVE = "FORCE_ACTIVE"
}

-- State
local state = {
    data = nil,
    selectedReactor = nil,
    view = "dashboard",  -- "dashboard" or "reactor-detail"
    touchAreas = {},     -- Clickable areas
    running = true
}

-- Callbacks
local callbacks = {
    getData = nil,
    setControlMode = nil,
    tick = nil
}

-- Initialize GUI
function gui.init(config)
    gui.config = config

    -- Get GPU and screen
    local gpu = component.gpu
    local screen = component.screen

    if config.gpu then
        gpu = component.proxy(config.gpu)
    end
    if config.screen then
        screen = component.proxy(config.screen)
    end

    gpu.bind(screen.address)
    local width, height = gpu.getResolution()

    draw.init(gpu, width, height)
    gui.gpu = gpu
    gui.width = width
    gui.height = height

    return true
end

-- Register a touch area
local function addTouchArea(x, y, width, height, action, data)
    table.insert(state.touchAreas, {
        x = x, y = y,
        width = width, height = height,
        action = action,
        data = data
    })
end

-- Clear touch areas
local function clearTouchAreas()
    state.touchAreas = {}
end

-- Check if point is in area
local function pointInArea(px, py, area)
    return px >= area.x and px < area.x + area.width and
           py >= area.y and py < area.y + area.height
end

-- Draw a button
local function drawButton(x, y, width, text, bgColor, fgColor, action, data)
    draw.gpu.setBackground(bgColor)
    draw.gpu.setForeground(fgColor or draw.colors.text)
    draw.gpu.fill(x, y, width, 1, " ")
    local textX = x + math.floor((width - unicode.len(text)) / 2)
    draw.gpu.set(textX, y, text)
    draw.gpu.setBackground(draw.colors.background)
    draw.gpu.setForeground(draw.colors.text)
    addTouchArea(x, y, width, 1, action, data)
end

-- Get color for control mode
local function getModeColor(mode)
    if mode == ControlMode.DISABLED then
        return draw.colors.danger
    elseif mode == ControlMode.FORCE_ACTIVE then
        return draw.colors.warning
    else
        return 0x17a2b8  -- cyan for AUTO
    end
end

-- Get color for status
local function getStatusColor(status)
    if status == "ONLINE" then
        return draw.colors.success
    elseif status == "ERROR" then
        return draw.colors.danger
    else
        return draw.colors.offline
    end
end

-- Get color for heat level
local function getHeatColor(heat)
    if heat > 80 then
        return draw.colors.danger
    elseif heat > 50 then
        return draw.colors.warning
    else
        return draw.colors.success
    end
end

-- Get color for battery level
local function getBatteryColor(percent)
    if percent < 20 then
        return draw.colors.danger
    elseif percent > 80 then
        return draw.colors.success
    else
        return draw.colors.warning
    end
end

-- Render dashboard view
local function renderDashboard()
    clearTouchAreas()
    draw.clear()

    local data = state.data
    if not data then return end

    -- Header
    draw.gpu.setBackground(draw.colors.card)
    draw.gpu.fill(1, 1, gui.width, 2, " ")
    draw.text(2, 1, "MainCominotor", draw.colors.primary)

    -- Connection status
    local connText = data.serverConnected and "CONNECTED" or "OFFLINE"
    local connColor = data.serverConnected and draw.colors.success or draw.colors.danger
    draw.text(gui.width - 12, 1, connText, connColor)
    draw.gpu.setBackground(draw.colors.background)

    local y = 4

    -- Stats row
    draw.text(2, y, "OVERVIEW", draw.colors.textDim)
    y = y + 1

    -- Calculate stats
    local totalEU = 0
    local onlineCount = 0
    local autoCount = 0
    for _, r in ipairs(data.reactors or {}) do
        if r.status == "ONLINE" then
            totalEU = totalEU + (r.euOutput or 0)
            onlineCount = onlineCount + 1
        end
        if r.controlMode == ControlMode.AUTO then
            autoCount = autoCount + 1
        end
    end

    -- Stats cards
    local cardWidth = math.floor((gui.width - 6) / 4)
    draw.box(2, y, cardWidth, 3, draw.colors.card)
    draw.text(3, y, "EU Output", draw.colors.textDim)
    draw.text(3, y + 1, tostring(totalEU) .. " EU/t", draw.colors.primary)

    draw.box(3 + cardWidth, y, cardWidth, 3, draw.colors.card)
    draw.text(4 + cardWidth, y, "Battery", draw.colors.textDim)
    local batteryColor = getBatteryColor(data.avgBatteryCharge or 50)
    draw.text(4 + cardWidth, y + 1, tostring(data.avgBatteryCharge or 0) .. "%", batteryColor)

    draw.box(4 + cardWidth * 2, y, cardWidth, 3, draw.colors.card)
    draw.text(5 + cardWidth * 2, y, "Online", draw.colors.textDim)
    draw.text(5 + cardWidth * 2, y + 1, onlineCount .. "/" .. #(data.reactors or {}), draw.colors.success)

    draw.box(5 + cardWidth * 3, y, cardWidth, 3, draw.colors.card)
    draw.text(6 + cardWidth * 3, y, "Auto Mode", draw.colors.textDim)
    draw.text(6 + cardWidth * 3, y + 1, tostring(autoCount), 0x17a2b8)

    y = y + 5

    -- Battery section
    if #(data.batteries or {}) > 0 then
        draw.text(2, y, "BATTERIES", draw.colors.textDim)
        y = y + 1

        for i, battery in ipairs(data.batteries) do
            if y + 2 > gui.height - 4 then break end

            draw.box(2, y, gui.width - 3, 2, draw.colors.card)
            draw.text(3, y, battery.name, draw.colors.text)

            -- Battery bar
            local barWidth = gui.width - 20
            local barX = 3
            draw.gpu.setBackground(0x2a2a4a)
            draw.gpu.fill(barX, y + 1, barWidth, 1, " ")
            local fillWidth = math.floor(barWidth * battery.chargePercent / 100)
            if fillWidth > 0 then
                draw.gpu.setBackground(getBatteryColor(battery.chargePercent))
                draw.gpu.fill(barX, y + 1, fillWidth, 1, " ")
            end
            draw.gpu.setBackground(draw.colors.background)

            draw.text(gui.width - 8, y, battery.chargePercent .. "%", getBatteryColor(battery.chargePercent))
            y = y + 3
        end
    end

    -- Reactor section
    draw.text(2, y, "REACTORS", draw.colors.textDim)
    y = y + 1

    if #(data.reactors or {}) == 0 then
        draw.text(4, y + 1, "No reactors configured", draw.colors.textDim)
    else
        for i, reactor in ipairs(data.reactors) do
            if y + 3 > gui.height - 1 then break end

            draw.box(2, y, gui.width - 3, 3, draw.colors.card)

            -- Name (clickable)
            draw.text(3, y, reactor.name, draw.colors.text)
            addTouchArea(2, y, gui.width - 3, 3, "select_reactor", i)

            -- Status badge
            local statusX = 3 + unicode.len(reactor.name) + 2
            draw.gpu.setBackground(getStatusColor(reactor.status))
            draw.gpu.setForeground(draw.colors.text)
            draw.gpu.set(statusX, y, " " .. reactor.status .. " ")
            draw.gpu.setBackground(draw.colors.background)

            -- Control mode badge
            local modeX = statusX + unicode.len(reactor.status) + 4
            draw.gpu.setBackground(getModeColor(reactor.controlMode))
            draw.gpu.setForeground(reactor.controlMode == ControlMode.FORCE_ACTIVE and 0x000000 or draw.colors.text)
            local modeText = reactor.controlMode == ControlMode.FORCE_ACTIVE and "FORCE" or reactor.controlMode
            draw.gpu.set(modeX, y, " " .. modeText .. " ")
            draw.gpu.setBackground(draw.colors.background)
            draw.gpu.setForeground(draw.colors.text)

            -- Heat and EU
            draw.text(3, y + 1, "Heat: " .. reactor.heatLevel .. "%", getHeatColor(reactor.heatLevel))
            draw.text(20, y + 1, "EU: " .. (reactor.euOutput or 0) .. " EU/t", draw.colors.text)

            -- Control buttons
            local btnY = y + 2
            local btnWidth = 8
            local btnX = gui.width - 28

            drawButton(btnX, btnY, btnWidth, "AUTO",
                reactor.controlMode == ControlMode.AUTO and 0x17a2b8 or 0x2a2a4a,
                draw.colors.text, "set_mode", {reactor = i, mode = ControlMode.AUTO})

            drawButton(btnX + btnWidth + 1, btnY, btnWidth, "OFF",
                reactor.controlMode == ControlMode.DISABLED and draw.colors.danger or 0x2a2a4a,
                draw.colors.text, "set_mode", {reactor = i, mode = ControlMode.DISABLED})

            drawButton(btnX + (btnWidth + 1) * 2, btnY, btnWidth, "FORCE",
                reactor.controlMode == ControlMode.FORCE_ACTIVE and draw.colors.warning or 0x2a2a4a,
                reactor.controlMode == ControlMode.FORCE_ACTIVE and 0x000000 or draw.colors.text,
                "set_mode", {reactor = i, mode = ControlMode.FORCE_ACTIVE})

            y = y + 4
        end
    end

    -- Footer
    draw.gpu.setBackground(draw.colors.card)
    draw.gpu.fill(1, gui.height, gui.width, 1, " ")
    draw.text(2, gui.height, "Q=Quit  Touch reactor for details", draw.colors.textDim)
    draw.gpu.setBackground(draw.colors.background)
end

-- Render reactor detail view
local function renderReactorDetail()
    clearTouchAreas()
    draw.clear()

    local data = state.data
    local idx = state.selectedReactor
    if not data or not idx or not data.reactors[idx] then
        state.view = "dashboard"
        return
    end

    local reactor = data.reactors[idx]

    -- Header with back button
    draw.gpu.setBackground(draw.colors.card)
    draw.gpu.fill(1, 1, gui.width, 2, " ")
    drawButton(2, 1, 8, "< BACK", draw.colors.primary, draw.colors.text, "back", nil)
    draw.text(12, 1, reactor.name, draw.colors.text)
    draw.gpu.setBackground(draw.colors.background)

    local y = 4

    -- Large status display
    draw.box(2, y, gui.width - 3, 5, draw.colors.card)
    draw.text(4, y + 1, "STATUS", draw.colors.textDim)
    draw.gpu.setBackground(getStatusColor(reactor.status))
    draw.gpu.set(4, y + 2, " " .. reactor.status .. " ")
    draw.gpu.setBackground(draw.colors.card)

    draw.text(20, y + 1, "CONTROL MODE", draw.colors.textDim)
    draw.gpu.setBackground(getModeColor(reactor.controlMode))
    draw.gpu.setForeground(reactor.controlMode == ControlMode.FORCE_ACTIVE and 0x000000 or draw.colors.text)
    local modeText = reactor.controlMode == ControlMode.FORCE_ACTIVE and "FORCE ACTIVE" or reactor.controlMode
    draw.gpu.set(20, y + 2, " " .. modeText .. " ")
    draw.gpu.setBackground(draw.colors.background)
    draw.gpu.setForeground(draw.colors.text)

    y = y + 7

    -- Heat gauge
    draw.text(2, y, "HEAT LEVEL", draw.colors.textDim)
    y = y + 1
    draw.box(2, y, gui.width - 3, 2, draw.colors.card)

    local barWidth = gui.width - 8
    draw.gpu.setBackground(0x2a2a4a)
    draw.gpu.fill(4, y + 1, barWidth, 1, " ")
    local heatFill = math.floor(barWidth * reactor.heatLevel / 100)
    if heatFill > 0 then
        draw.gpu.setBackground(getHeatColor(reactor.heatLevel))
        draw.gpu.fill(4, y + 1, heatFill, 1, " ")
    end
    draw.gpu.setBackground(draw.colors.background)
    draw.text(gui.width - 8, y, reactor.heatLevel .. "%", getHeatColor(reactor.heatLevel))

    y = y + 4

    -- Stats
    draw.text(2, y, "DETAILS", draw.colors.textDim)
    y = y + 1
    draw.box(2, y, gui.width - 3, 4, draw.colors.card)
    draw.text(4, y, "EU Output:", draw.colors.textDim)
    draw.text(20, y, (reactor.euOutput or 0) .. " EU/t", draw.colors.text)
    draw.text(4, y + 1, "Address:", draw.colors.textDim)
    local addrDisplay = reactor.address and (unicode.len(reactor.address) > 30 and unicode.sub(reactor.address, 1, 30) .. "..." or reactor.address) or "N/A"
    draw.text(20, y + 1, addrDisplay, draw.colors.text)

    y = y + 6

    -- Control mode buttons (large)
    draw.text(2, y, "CONTROL", draw.colors.textDim)
    y = y + 1

    local btnWidth = math.floor((gui.width - 6) / 3)

    drawButton(2, y, btnWidth, "AUTO",
        reactor.controlMode == ControlMode.AUTO and 0x17a2b8 or 0x2a2a4a,
        draw.colors.text, "set_mode", {reactor = idx, mode = ControlMode.AUTO})

    drawButton(3 + btnWidth, y, btnWidth, "DISABLED",
        reactor.controlMode == ControlMode.DISABLED and draw.colors.danger or 0x2a2a4a,
        draw.colors.text, "set_mode", {reactor = idx, mode = ControlMode.DISABLED})

    drawButton(4 + btnWidth * 2, y, btnWidth, "FORCE ACTIVE",
        reactor.controlMode == ControlMode.FORCE_ACTIVE and draw.colors.warning or 0x2a2a4a,
        reactor.controlMode == ControlMode.FORCE_ACTIVE and 0x000000 or draw.colors.text,
        "set_mode", {reactor = idx, mode = ControlMode.FORCE_ACTIVE})

    y = y + 3

    -- Mode descriptions
    draw.box(2, y, gui.width - 3, 5, draw.colors.card)
    draw.text(4, y, "AUTO:", 0x17a2b8)
    draw.text(10, y, "Battery-based control (20-90%)", draw.colors.textDim)
    draw.text(4, y + 1, "DISABLED:", draw.colors.danger)
    draw.text(14, y + 1, "Reactor never runs", draw.colors.textDim)
    draw.text(4, y + 2, "FORCE:", draw.colors.warning)
    draw.text(11, y + 2, "Always run (if safe)", draw.colors.textDim)

    -- Footer
    draw.gpu.setBackground(draw.colors.card)
    draw.gpu.fill(1, gui.height, gui.width, 1, " ")
    draw.text(2, gui.height, "Touch buttons to change mode", draw.colors.textDim)
    draw.gpu.setBackground(draw.colors.background)
end

-- Handle touch event
local function handleTouch(x, y)
    for _, area in ipairs(state.touchAreas) do
        if pointInArea(x, y, area) then
            if area.action == "select_reactor" then
                state.selectedReactor = area.data
                state.view = "reactor-detail"
                return true
            elseif area.action == "back" then
                state.view = "dashboard"
                state.selectedReactor = nil
                return true
            elseif area.action == "set_mode" then
                if callbacks.setControlMode and state.data and state.data.reactors then
                    local reactor = state.data.reactors[area.data.reactor]
                    if reactor then
                        callbacks.setControlMode(reactor, area.data.mode)
                        -- Update local state immediately
                        reactor.controlMode = area.data.mode
                    end
                end
                return true
            end
        end
    end
    return false
end

-- Render current view
local function render()
    if state.view == "reactor-detail" then
        renderReactorDetail()
    else
        renderDashboard()
    end
end

-- Run GUI loop
function gui.run(getDataFunc, setControlModeFunc, tickFunc)
    callbacks.getData = getDataFunc
    callbacks.setControlMode = setControlModeFunc
    callbacks.tick = tickFunc

    -- Event handlers
    local function onKey(_, _, char, code)
        if char == 113 or char == 81 then  -- Q
            state.running = false
        elseif char == 98 or char == 66 then  -- B (back)
            state.view = "dashboard"
            state.selectedReactor = nil
        end
    end

    local function onTouch(_, x, y, button, player)
        handleTouch(math.floor(x), math.floor(y))
    end

    event.listen("key_down", onKey)
    event.listen("touch", onTouch)

    local lastRender = 0
    local refreshRate = gui.config.display.refreshRate or 1

    while state.running do
        -- Run tick function (reactor management, server sync)
        if callbacks.tick then
            callbacks.tick()
        end

        -- Update data
        if callbacks.getData then
            state.data = callbacks.getData()
        end

        -- Render at refresh rate
        local now = computer.uptime()
        if now - lastRender >= refreshRate then
            render()
            lastRender = now
        end

        -- Process events
        local ev = {event.pull(0.1)}
        if ev[1] == "key_down" then
            onKey(ev[1], ev[2], ev[3], ev[4])
        elseif ev[1] == "touch" then
            onTouch(ev[1], ev[2], ev[3], ev[4], ev[5])
            render()  -- Immediate render after touch
        end
    end

    event.ignore("key_down", onKey)
    event.ignore("touch", onTouch)

    -- Exit screen
    draw.clear()
    draw.centerText(math.floor(gui.height / 2), "Reactor Controller Stopped", draw.colors.textDim)
end

return gui