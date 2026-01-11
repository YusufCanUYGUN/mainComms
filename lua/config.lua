-- MainCominotor Configuration File
-- Edit this file to configure your reactor controller
-- All reactor/battery definitions are LOCAL - server only sees status

local config = {
    -- Server connection
    -- DEVELOPMENT: Use this URL for local testing
    -- server = {
    --     url = "http://localhost:8081/portakalapi",
    --     apiKey = "YOUR_API_KEY_HERE",
    --     timeout = 10
    -- },

    -- PRODUCTION: Use this URL for internet access
    server = {
        url = "https://uygunfamily.duckdns.org/portakalapi",
        apiKey = "YOUR_API_KEY_HERE",  -- Get this from the web dashboard
        timeout = 10  -- Request timeout in seconds
    },

    -- Battery thresholds for reactor management
    battery = {
        lowThreshold = 20,   -- Below this: all reactors ON
        highThreshold = 90,  -- Above this: all reactors OFF
        -- Between these values: gradual shutdown
    },

    -- Reactor settings
    reactor = {
        updateInterval = 5,  -- How often to sync with server (seconds)
        shutdownOnOverheat = true,  -- Auto-shutdown if heat > threshold
        overheatThreshold = 80  -- Heat percentage to trigger shutdown
    },

    -- Display settings
    display = {
        enabled = true,
        refreshRate = 1,  -- Screen refresh rate (seconds)
        showDebug = false,  -- Show debug information
        touchEnabled = true  -- Enable touch screen controls
    },

    --[[
    ============================================================================
    REACTOR DEFINITIONS
    ============================================================================
    Define your reactors here. Each reactor needs:
    - name: Display name
    - address: OpenComputers reactor component address
    - redstoneAddress: (optional) Redstone I/O address for control
    - redstoneSide: (optional) Side of redstone (0=bottom,1=top,2=north,3=south,4=west,5=east)
    - fuelSlots: (optional) Table of slot numbers where fuel rods go
    - fuelType: (optional) Item name pattern for fuel (e.g., "reactorUranium")
    - coolingSlots: (optional) Table of slot numbers where cooling cells go
    - coolingType: (optional) Item name pattern for cooling (e.g., "reactorCoolant")
    - transposerAddress: (optional) Transposer address for refueling
    - transposerReactorSide: (optional) Side facing reactor
    - transposerStorageSide: (optional) Side facing storage chest
    ]]--
    reactors = {
        -- Example reactor configuration:
        -- {
        --     name = "Reactor 1",
        --     address = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        --     -- Redstone control (optional)
        --     redstoneAddress = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
        --     redstoneSide = 2,  -- north
        --     -- Fuel configuration (optional)
        --     fuelSlots = {0, 1, 2, 3},
        --     fuelType = "reactorUraniumQuad",
        --     -- Cooling configuration (optional)
        --     coolingSlots = {4, 5, 6, 7, 8, 9},
        --     coolingType = "reactorCoolantSix",
        --     -- Transposer for refueling (optional)
        --     transposerAddress = "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz",
        --     transposerReactorSide = 1,  -- top
        --     transposerStorageSide = 0,  -- bottom
        -- },
    },

    --[[
    ============================================================================
    BATTERY DEFINITIONS
    ============================================================================
    Define your batteries here. Each battery needs:
    - name: Display name
    - address: OpenComputers component address
    - type: "gt" for GregTech batteries, "ic2" for IC2 batteries
    ]]--
    batteries = {
        -- Example battery configuration:
        -- {
        --     name = "Main Battery",
        --     address = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        --     type = "gt"  -- or "ic2"
        -- },
    },

    -- GPU and Screen addresses (leave nil for auto-detect)
    gpu = nil,
    screen = nil
}

return config