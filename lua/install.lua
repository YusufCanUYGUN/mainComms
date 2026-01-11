-- MainCominotor Installer for OpenComputers
-- Run: wget https://raw.githubusercontent.com/YusufCanUYGUN/mainComms/main/lua/install.lua install.lua && install.lua

local component = require("component")
local filesystem = require("filesystem")
local shell = require("shell")
local term = require("term")

local baseUrl = "https://raw.githubusercontent.com/YusufCanUYGUN/mainComms/main/lua/"

local files = {
    {url = "config.lua", path = "/home/config.lua"},
    {url = "reactor_controller.lua", path = "/home/reactor_controller.lua"},
    {url = "gui.lua", path = "/home/gui.lua"},
    {url = "lib/api.lua", path = "/home/lib/api.lua"},
    {url = "lib/draw.lua", path = "/home/lib/draw.lua"},
}

print("========================================")
print("  MainCominotor Installer")
print("  Reactor Management System")
print("========================================")
print("")

-- Check for internet card
if not component.isAvailable("internet") then
    print("ERROR: Internet Card required!")
    print("Please install an Internet Card and try again.")
    return
end

print("Internet Card: OK")
print("")

-- Create directories
print("Creating directories...")
filesystem.makeDirectory("/home/lib")
print("  /home/lib created")
print("")

-- Download files
print("Downloading files...")
local internet = require("internet")

for _, file in ipairs(files) do
    local url = baseUrl .. file.url
    print("  Downloading: " .. file.url)

    local success, err = pcall(function()
        local handle = internet.request(url)
        local content = ""
        for chunk in handle do
            content = content .. chunk
        end

        local f = io.open(file.path, "w")
        f:write(content)
        f:close()
    end)

    if success then
        print("    -> " .. file.path .. " OK")
    else
        print("    -> FAILED: " .. tostring(err))
    end
end

print("")
print("========================================")
print("  Installation Complete!")
print("========================================")
print("")
print("NEXT STEPS:")
print("")
print("1. Edit config file with your settings:")
print("   edit /home/config.lua")
print("")
print("2. Get your component addresses:")
print("   components")
print("")
print("3. Get API key from web dashboard:")
print("   https://uygunfamily.duckdns.org/portakalapi/")
print("")
print("4. Update config.lua with:")
print("   - Your API key")
print("   - Reactor address(es)")
print("   - Battery address(es)")
print("   - Redstone/Transposer addresses (optional)")
print("")
print("5. Run the controller:")
print("   /home/reactor_controller.lua")
print("")
print("6. (Optional) Auto-start on boot:")
print("   echo '/home/reactor_controller.lua' >> /home/.shrc")
print("")
print("========================================")