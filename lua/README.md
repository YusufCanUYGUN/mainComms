# MainCominotor - OpenComputers Client

Lua client for managing IC2 reactors via OpenComputers.

## Requirements

### Hardware (In-Game)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Case | Tier 2 | Tier 3 |
| CPU | Tier 2 | Tier 3 |
| RAM | 2x Tier 1.5 | 2x Tier 2 |
| Hard Drive | Tier 1 | Tier 2 |
| Graphics Card | Tier 2 | Tier 3 |
| Screen | Tier 2 | Tier 2 |
| Internet Card | **Required** | **Required** |
| Keyboard | Required | Required |

### Optional Components

- **Redstone I/O** - For redstone reactor control
- **Transposer** - For automatic refueling/cooling
- **Adapter** - To connect to IC2 reactor

## Quick Install

**1. Boot OpenComputers and run:**

```
wget https://raw.githubusercontent.com/YusufCanUYGUN/mainComms/main/lua/install.lua install.lua && install.lua
```

**2. Get component addresses:**

```
components
```

Write down the addresses for:
- `reactor` or `reactor_chamber`
- `gt_machine` (for GregTech batteries) or `ic2_te_*`
- `redstone` (if using redstone control)
- `transposer` (if using auto-refuel)

**3. Get your API key:**

- Go to: https://uygunfamily.duckdns.org/portakalapi/
- Register/Login
- Go to Dashboard -> API Keys
- Create a new API key
- Copy the key

**4. Edit config:**

```
edit /home/config.lua
```

Update these values:
```lua
server = {
    url = "https://uygunfamily.duckdns.org/portakalapi",
    apiKey = "PASTE_YOUR_API_KEY_HERE",
    timeout = 10
},

reactors = {
    {
        name = "Reactor 1",
        address = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  -- from components
        -- Optional: redstone control
        redstoneAddress = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
        redstoneSide = 2,  -- 0=bottom,1=top,2=north,3=south,4=west,5=east
    },
},

batteries = {
    {
        name = "Main Battery",
        address = "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz",  -- from components
        type = "gt"  -- "gt" for GregTech, "ic2" for IC2
    },
},
```

**5. Run:**

```
/home/reactor_controller.lua
```

**6. Auto-start (optional):**

```
echo '/home/reactor_controller.lua' >> /home/.shrc
```

## Manual Install

If wget doesn't work, create files manually:

```
mkdir /home/lib
edit /home/config.lua
edit /home/lib/api.lua
edit /home/lib/draw.lua
edit /home/gui.lua
edit /home/reactor_controller.lua
```

Copy content from this repository's `lua/` folder.

## Controls

### GUI Controls

| Key/Action | Function |
|------------|----------|
| Touch reactor | View details |
| Touch AUTO | Set auto mode (battery-based) |
| Touch OFF | Disable reactor |
| Touch FORCE | Force reactor on |
| Q | Quit |
| B | Back to dashboard |

### Control Modes

| Mode | Description |
|------|-------------|
| AUTO | Reactor runs based on battery level (20-90%) |
| DISABLED | Reactor never runs |
| FORCE_ACTIVE | Reactor always runs (if safe) |

## Troubleshooting

### "Internet Card required"
Install an Internet Card in your computer.

### "Connection failed"
- Check server URL in config
- Verify API key is correct
- Check if server is running

### "Reactor not found"
- Run `components` to get correct address
- Make sure Adapter is connected to reactor

### GUI not showing
- Check Graphics Card is Tier 2+
- Check Screen is connected
- Set `display.enabled = true` in config

## File Structure

```
/home/
├── config.lua           # Your configuration
├── reactor_controller.lua  # Main script
├── gui.lua              # Touch GUI
└── lib/
    ├── api.lua          # Server communication
    └── draw.lua         # GPU drawing utilities
```