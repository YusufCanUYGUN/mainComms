-- MainCominotor Reactor Controller
-- Main script for managing IC2 reactors with OpenComputers
-- Reactors/batteries are defined in local config.lua
-- Server only receives status updates and can enable/disable reactors

local component = require("component")
local event = require("event")
local os = require("os")
local computer = require("computer")

-- Load modules
local config = require("config")
local api = require("lib/api")
local gui = require("gui")

-- Control Modes (from server)
local ControlMode = {
    DISABLED = "DISABLED",      -- Never run (server disabled)
    AUTO = "AUTO",              -- Battery-based control (default)
    FORCE_ACTIVE = "FORCE_ACTIVE"  -- Always run (if safe)
}

-- State
local state = {
    reactors = {},          -- Reactor objects with components
    batteries = {},         -- Battery objects with components
    serverControlModes = {}, -- Control modes from server (key = address)
    serverConnected = false,
    running = true,
    lastServerSync = 0
}

-- Get proxy for component by address
local function getProxy(address)
    if not address or address == "" then return nil end
    local success, proxy = pcall(function()
        return component.proxy(address)
    end)
    return success and proxy or nil
end

-- Initialize reactors from local config
local function initReactors()
    state.reactors = {}
    for i, reactorConfig in ipairs(config.reactors or {}) do
        local reactor = {
            name = reactorConfig.name or ("Reactor " .. i),
            address = reactorConfig.address,
            -- Control components
            component = getProxy(reactorConfig.address),
            redstoneAddress = reactorConfig.redstoneAddress,
            redstoneSide = reactorConfig.redstoneSide,
            redstoneComponent = getProxy(reactorConfig.redstoneAddress),
            -- Fuel/cooling config
            fuelSlots = reactorConfig.fuelSlots or {},
            fuelType = reactorConfig.fuelType,
            coolingSlots = reactorConfig.coolingSlots or {},
            coolingType = reactorConfig.coolingType,
            -- Transposer config
            transposerAddress = reactorConfig.transposerAddress,
            transposerReactorSide = reactorConfig.transposerReactorSide,
            transposerStorageSide = reactorConfig.transposerStorageSide,
            transposerComponent = getProxy(reactorConfig.transposerAddress),
            -- Runtime state
            controlMode = ControlMode.AUTO  -- Default, updated from server
        }
        table.insert(state.reactors, reactor)
    end
    return #state.reactors
end

-- Initialize batteries from local config
local function initBatteries()
    state.batteries = {}
    for i, batteryConfig in ipairs(config.batteries or {}) do
        local battery = {
            name = batteryConfig.name or ("Battery " .. i),
            address = batteryConfig.address,
            type = batteryConfig.type or "gt",
            component = getProxy(batteryConfig.address)
        }
        table.insert(state.batteries, battery)
    end
    return #state.batteries
end

-- Get reactor runtime data
local function getReactorData(reactor)
    local data = {
        address = reactor.address,
        name = reactor.name,
        controlMode = reactor.controlMode,
        heatLevel = 0,
        euOutput = 0,
        status = "OFFLINE",
        isRunning = false
    }

    local comp = reactor.component
    if not comp then
        data.status = "ERROR"
        return data
    end

    local success = pcall(function()
        data.isRunning = comp.producesEnergy and comp.producesEnergy() or false
        local heat = comp.getHeat and comp.getHeat() or 0
        local maxHeat = comp.getMaxHeat and comp.getMaxHeat() or 1
        data.heatLevel = math.floor(heat * 100 / maxHeat)
        data.euOutput = comp.getReactorEUOutput and comp.getReactorEUOutput() or 0

        if data.isRunning then
            data.status = "ONLINE"
        elseif data.heatLevel > 80 then
            data.status = "ERROR"
        else
            data.status = "OFFLINE"
        end
    end)

    if not success then
        data.status = "ERROR"
    end

    return data
end

-- Get battery data
local function getBatteryData(battery)
    local data = {
        address = battery.address,
        name = battery.name,
        currentEU = 0,
        maxEU = 1,
        chargePercent = 0
    }

    local comp = battery.component
    if not comp then return data end

    pcall(function()
        if battery.type == "gt" then
            data.currentEU = comp.getStoredEU and comp.getStoredEU() or 0
            data.maxEU = comp.getEUMaxStored and comp.getEUMaxStored() or 1
        else
            data.currentEU = comp.getEnergy and comp.getEnergy() or 0
            data.maxEU = comp.getCapacity and comp.getCapacity() or 1
        end
        data.chargePercent = math.floor(data.currentEU * 100 / math.max(data.maxEU, 1))
    end)

    return data
end

-- Get average battery charge
local function getAverageBatteryCharge()
    if #state.batteries == 0 then return 50 end

    local totalCharge = 0
    for _, battery in ipairs(state.batteries) do
        local data = getBatteryData(battery)
        totalCharge = totalCharge + data.chargePercent
    end
    return math.floor(totalCharge / #state.batteries)
end

-- Calculate how many reactors should be active
local function calculateActiveReactors(chargePercent, totalReactors)
    local low = config.battery.lowThreshold
    local high = config.battery.highThreshold

    if chargePercent < low then
        return totalReactors
    elseif chargePercent > high then
        return 0
    else
        return math.ceil(totalReactors * (high - chargePercent) / (high - low))
    end
end

-- Set reactor state
local function setReactorState(reactor, enabled)
    -- Try direct reactor control
    if reactor.component and reactor.component.setActive then
        pcall(function() reactor.component.setActive(enabled) end)
    end

    -- Use redstone control if configured
    if reactor.redstoneComponent and reactor.redstoneSide ~= nil then
        pcall(function()
            reactor.redstoneComponent.setOutput(reactor.redstoneSide, enabled and 15 or 0)
        end)
    end
end

-- Check if item matches type
local function itemMatches(item, itemType)
    if not item or not itemType then return false end
    return string.find(item.name or "", itemType, 1, true) ~= nil
end

-- Refuel reactor
local function refuelReactor(reactor)
    if not reactor.transposerComponent then return end
    if #reactor.fuelSlots == 0 or not reactor.fuelType then return end

    local transposer = reactor.transposerComponent
    local reactorSide = reactor.transposerReactorSide
    local storageSide = reactor.transposerStorageSide
    if not reactorSide or not storageSide then return end

    for _, slot in ipairs(reactor.fuelSlots) do
        pcall(function()
            local item = transposer.getStackInSlot(reactorSide, slot)
            local needsFuel = not item or (item.damage and item.damage >= item.maxDamage - 1)

            if needsFuel then
                if item then
                    transposer.transferItem(reactorSide, storageSide, 1, slot)
                end

                local storageSize = transposer.getInventorySize(storageSide) or 0
                for i = 1, storageSize do
                    local storageItem = transposer.getStackInSlot(storageSide, i)
                    if storageItem and itemMatches(storageItem, reactor.fuelType) then
                        transposer.transferItem(storageSide, reactorSide, 1, i, slot)
                        break
                    end
                end
            end
        end)
    end
end

-- Replace cooling cells
local function replaceCooling(reactor)
    if not reactor.transposerComponent then return end
    if #reactor.coolingSlots == 0 or not reactor.coolingType then return end

    local transposer = reactor.transposerComponent
    local reactorSide = reactor.transposerReactorSide
    local storageSide = reactor.transposerStorageSide
    if not reactorSide or not storageSide then return end

    for _, slot in ipairs(reactor.coolingSlots) do
        pcall(function()
            local item = transposer.getStackInSlot(reactorSide, slot)
            local needsCooling = not item or (item.damage and item.damage >= item.maxDamage - 1)

            if needsCooling then
                if item then
                    transposer.transferItem(reactorSide, storageSide, 1, slot)
                end

                local storageSize = transposer.getInventorySize(storageSide) or 0
                for i = 1, storageSize do
                    local storageItem = transposer.getStackInSlot(storageSide, i)
                    if storageItem and itemMatches(storageItem, reactor.coolingType) then
                        transposer.transferItem(storageSide, reactorSide, 1, i, slot)
                        break
                    end
                end
            end
        end)
    end
end

-- Check reactor safety
local function isReactorSafe(reactor)
    local data = getReactorData(reactor)
    return data.heatLevel <= config.reactor.overheatThreshold
end

-- Manage all reactors
local function manageReactors()
    local avgCharge = getAverageBatteryCharge()

    -- Get AUTO mode reactors
    local autoReactors = {}
    for _, reactor in ipairs(state.reactors) do
        if reactor.controlMode == ControlMode.AUTO then
            table.insert(autoReactors, reactor)
        end
    end

    -- Calculate target for AUTO reactors
    local targetActive = calculateActiveReactors(avgCharge, #autoReactors)

    -- Sort AUTO reactors by heat (cooler first)
    table.sort(autoReactors, function(a, b)
        return getReactorData(a).heatLevel < getReactorData(b).heatLevel
    end)

    -- Process all reactors
    for _, reactor in ipairs(state.reactors) do
        -- Safety first - disable overheated reactors
        if not isReactorSafe(reactor) then
            setReactorState(reactor, false)
            goto continue
        end

        -- Handle refueling/cooling
        refuelReactor(reactor)
        replaceCooling(reactor)

        -- Control based on mode
        if reactor.controlMode == ControlMode.DISABLED then
            -- Server disabled - MUST turn off
            setReactorState(reactor, false)

        elseif reactor.controlMode == ControlMode.FORCE_ACTIVE then
            -- Force active (if safe)
            setReactorState(reactor, true)

        elseif reactor.controlMode == ControlMode.AUTO then
            -- Battery-based control
            local shouldBeActive = false
            for i, autoReactor in ipairs(autoReactors) do
                if autoReactor.address == reactor.address then
                    shouldBeActive = (i <= targetActive)
                    break
                end
            end
            setReactorState(reactor, shouldBeActive)
        end

        ::continue::
    end
end

-- Sync with server
local function syncWithServer()
    if not component.isAvailable("internet") then
        state.serverConnected = false
        return
    end

    local success = true

    -- Send reactor status to server
    for _, reactor in ipairs(state.reactors) do
        local data = getReactorData(reactor)
        local response = api.updateReactor(config, reactor.address, data.heatLevel, data.euOutput, data.status)
        if not response then success = false end
    end

    -- Send battery status to server
    for _, battery in ipairs(state.batteries) do
        local data = getBatteryData(battery)
        local response = api.updateBattery(config, battery.address, data.currentEU, data.maxEU)
        if not response then success = false end
    end

    -- Get control modes from server
    local response = api.getReactors(config)
    if response and response.data then
        for _, serverReactor in ipairs(response.data) do
            state.serverControlModes[serverReactor.address] = serverReactor.controlMode or ControlMode.AUTO
        end
        -- Update local reactor control modes
        for _, reactor in ipairs(state.reactors) do
            if state.serverControlModes[reactor.address] then
                reactor.controlMode = state.serverControlModes[reactor.address]
            end
        end
    end

    state.serverConnected = success
    state.lastServerSync = computer.uptime()
end

-- Set control mode for a reactor (called from GUI)
local function setReactorControlMode(reactor, mode)
    -- Update locally
    reactor.controlMode = mode

    -- Send to server
    if component.isAvailable("internet") then
        api.setControlMode(config, reactor.address, mode)
    end
end

-- Get all data for GUI
local function getGuiData()
    local reactorData = {}
    for _, reactor in ipairs(state.reactors) do
        local data = getReactorData(reactor)
        data.controlMode = reactor.controlMode
        table.insert(reactorData, data)
    end

    local batteryData = {}
    for _, battery in ipairs(state.batteries) do
        table.insert(batteryData, getBatteryData(battery))
    end

    return {
        reactors = reactorData,
        batteries = batteryData,
        serverConnected = state.serverConnected,
        avgBatteryCharge = getAverageBatteryCharge()
    }
end

-- Headless mode
local function runHeadless()
    print("Running in headless mode. Press Ctrl+C to stop.")

    while state.running do
        manageReactors()

        if computer.uptime() - state.lastServerSync >= config.reactor.updateInterval then
            syncWithServer()
        end

        os.sleep(1)
    end
end

-- Main function
local function main()
    print("MainCominotor Reactor Controller")
    print("================================")
    print("")

    -- Initialize from local config
    print("Loading configuration...")
    local reactorCount = initReactors()
    local batteryCount = initBatteries()

    print("Configured " .. reactorCount .. " reactor(s)")
    print("Configured " .. batteryCount .. " battery/batteries")

    if reactorCount == 0 then
        print("")
        print("No reactors configured!")
        print("Edit config.lua to add your reactors.")
        return
    end

    -- Check component connections
    local validReactors = 0
    for _, reactor in ipairs(state.reactors) do
        if reactor.component then
            validReactors = validReactors + 1
        else
            print("Warning: " .. reactor.name .. " not found at " .. (reactor.address or "nil"))
        end
    end
    print("Connected reactors: " .. validReactors .. "/" .. reactorCount)

    -- Initial server sync
    print("")
    print("Connecting to server...")
    syncWithServer()
    if state.serverConnected then
        print("Server connected.")
    else
        print("Server offline - running in local mode.")
    end

    -- Run GUI or headless
    if config.display.enabled then
        print("")
        print("Starting GUI...")
        gui.init(config)
        gui.run(getGuiData, setReactorControlMode, function()
            manageReactors()
            if computer.uptime() - state.lastServerSync >= config.reactor.updateInterval then
                syncWithServer()
            end
        end)
    else
        runHeadless()
    end
end

-- Run
local success, err = pcall(main)
if not success then
    print("Error: " .. tostring(err))
end