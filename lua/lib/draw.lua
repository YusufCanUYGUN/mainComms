-- Drawing Library for OpenComputers GPU
-- Provides gauge, chart, and status display functions

local component = require("component")
local unicode = require("unicode")

local draw = {}

-- Color palette
draw.colors = {
    background = 0x1a1a2e,
    card = 0x16213e,
    text = 0xeeeeee,
    textDim = 0x888888,
    primary = 0xe94560,
    success = 0x28a745,
    warning = 0xffc107,
    danger = 0xdc3545,
    offline = 0x6c757d
}

-- Initialize GPU
function draw.init(gpu, screenWidth, screenHeight)
    draw.gpu = gpu
    draw.width = screenWidth
    draw.height = screenHeight

    -- Set up color depth
    if gpu.maxDepth() >= 8 then
        gpu.setDepth(8)
    elseif gpu.maxDepth() >= 4 then
        gpu.setDepth(4)
    end

    draw.clear()
end

-- Clear screen
function draw.clear()
    draw.gpu.setBackground(draw.colors.background)
    draw.gpu.fill(1, 1, draw.width, draw.height, " ")
end

-- Set colors
function draw.setColors(fg, bg)
    if fg then draw.gpu.setForeground(fg) end
    if bg then draw.gpu.setBackground(bg) end
end

-- Draw text
function draw.text(x, y, text, color)
    if color then draw.gpu.setForeground(color) end
    draw.gpu.set(x, y, text)
end

-- Draw centered text
function draw.centerText(y, text, color)
    local x = math.floor((draw.width - unicode.len(text)) / 2) + 1
    draw.text(x, y, text, color)
end

-- Draw a box/card
function draw.box(x, y, width, height, bgColor)
    draw.gpu.setBackground(bgColor or draw.colors.card)
    draw.gpu.fill(x, y, width, height, " ")
    draw.gpu.setBackground(draw.colors.background)
end

-- Draw a horizontal bar
function draw.horizontalBar(x, y, width, percent, fgColor, bgColor)
    draw.gpu.setBackground(bgColor or draw.colors.card)
    draw.gpu.fill(x, y, width, 1, " ")

    local fillWidth = math.floor(width * percent / 100)
    if fillWidth > 0 then
        draw.gpu.setBackground(fgColor or draw.colors.success)
        draw.gpu.fill(x, y, fillWidth, 1, " ")
    end
    draw.gpu.setBackground(draw.colors.background)
end

-- Draw a vertical gauge
function draw.verticalGauge(x, y, width, height, percent, fgColor, bgColor)
    draw.gpu.setBackground(bgColor or draw.colors.card)
    draw.gpu.fill(x, y, width, height, " ")

    local fillHeight = math.floor(height * percent / 100)
    if fillHeight > 0 then
        draw.gpu.setBackground(fgColor or draw.colors.success)
        draw.gpu.fill(x, y + height - fillHeight, width, fillHeight, " ")
    end
    draw.gpu.setBackground(draw.colors.background)
end

-- Get color based on value and thresholds
function draw.getHeatColor(percent)
    if percent > 80 then
        return draw.colors.danger
    elseif percent > 50 then
        return draw.colors.warning
    else
        return draw.colors.success
    end
end

function draw.getBatteryColor(percent)
    if percent < 20 then
        return draw.colors.danger
    elseif percent > 90 then
        return draw.colors.success
    else
        return draw.colors.primary
    end
end

function draw.getStatusColor(status)
    if status == "ONLINE" then
        return draw.colors.success
    elseif status == "ERROR" then
        return draw.colors.danger
    else
        return draw.colors.offline
    end
end

-- Draw a status indicator
function draw.statusIndicator(x, y, status, label)
    local color = draw.getStatusColor(status)
    draw.gpu.setForeground(color)
    draw.gpu.set(x, y, unicode.char(0x25CF))  -- Filled circle
    draw.gpu.setForeground(draw.colors.text)
    draw.gpu.set(x + 2, y, label or status)
end

-- Draw header
function draw.header(title)
    draw.box(1, 1, draw.width, 3, draw.colors.card)
    draw.centerText(2, title, draw.colors.primary)
end

-- Draw a reactor card
function draw.reactorCard(x, y, reactor)
    local cardWidth = 24
    local cardHeight = 7

    draw.box(x, y, cardWidth, cardHeight)

    -- Name
    draw.text(x + 1, y + 1, reactor.name:sub(1, cardWidth - 2), draw.colors.primary)

    -- Status indicator
    draw.statusIndicator(x + 1, y + 2, reactor.status)

    -- Heat bar
    draw.text(x + 1, y + 3, "Heat:", draw.colors.textDim)
    local heatColor = draw.getHeatColor(reactor.heatLevel)
    draw.horizontalBar(x + 7, y + 3, cardWidth - 8, reactor.heatLevel, heatColor)

    -- EU output
    draw.text(x + 1, y + 4, "EU/t:", draw.colors.textDim)
    draw.text(x + 7, y + 4, tostring(reactor.euOutput), draw.colors.text)

    -- Enabled status
    local enabledText = reactor.enabled and "ENABLED" or "DISABLED"
    local enabledColor = reactor.enabled and draw.colors.success or draw.colors.offline
    draw.text(x + 1, y + 5, enabledText, enabledColor)
end

-- Draw a battery card
function draw.batteryCard(x, y, battery, width, height)
    draw.box(x, y, width, height)

    -- Name
    draw.centerText(y + 1, battery.name, draw.colors.primary)

    -- Gauge
    local gaugeWidth = 6
    local gaugeHeight = height - 5
    local gaugeX = x + math.floor((width - gaugeWidth) / 2)
    local gaugeY = y + 3

    local color = draw.getBatteryColor(battery.chargePercent)
    draw.verticalGauge(gaugeX, gaugeY, gaugeWidth, gaugeHeight, battery.chargePercent, color)

    -- Percentage text
    local percentText = battery.chargePercent .. "%"
    draw.centerText(y + height - 1, percentText, draw.colors.text)
end

-- Draw connection status
function draw.connectionStatus(y, connected)
    local status = connected and "CONNECTED" or "DISCONNECTED"
    local color = connected and draw.colors.success or draw.colors.danger
    local icon = connected and unicode.char(0x25CF) or unicode.char(0x25CB)

    draw.gpu.setForeground(color)
    draw.gpu.set(draw.width - unicode.len(status) - 2, y, icon)
    draw.gpu.set(draw.width - unicode.len(status), y, status)
    draw.gpu.setForeground(draw.colors.text)
end

-- Draw simple line chart
function draw.lineChart(x, y, width, height, values, maxValue, color)
    draw.box(x, y, width, height)

    if #values < 2 then return end

    maxValue = maxValue or math.max(table.unpack(values))
    if maxValue == 0 then maxValue = 1 end

    draw.gpu.setForeground(color or draw.colors.primary)

    local step = (width - 2) / (#values - 1)
    for i = 1, #values - 1 do
        local x1 = x + 1 + math.floor((i - 1) * step)
        local x2 = x + 1 + math.floor(i * step)
        local y1 = y + height - 1 - math.floor((values[i] / maxValue) * (height - 2))
        local y2 = y + height - 1 - math.floor((values[i + 1] / maxValue) * (height - 2))

        -- Draw point
        draw.gpu.set(x1, y1, unicode.char(0x2022))
    end
    -- Draw last point
    local lastY = y + height - 1 - math.floor((values[#values] / maxValue) * (height - 2))
    draw.gpu.set(x + width - 2, lastY, unicode.char(0x2022))

    draw.gpu.setForeground(draw.colors.text)
end

return draw
