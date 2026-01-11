# Test Client for MainCominotor

A command-line tool for testing the MainCominotor API during development.

## Setup

1. **Start the server first:**
   ```bash
   cd ..
   ./mvnw spring-boot:run
   ```

2. **Get an API Key:**
   - Go to http://localhost:8081/portakalapi/auth/register
   - Register an account
   - Go to http://localhost:8081/portakalapi/dashboard/api-keys
   - Create a new API key
   - Copy the key

3. **Configure the test client:**
   Edit `config.properties` and set your API key:
   ```properties
   API_KEY=your-actual-api-key-here
   ```

## Usage

### Windows
```cmd
test-client.bat
```

### Linux/Mac
```bash
chmod +x test-client.sh
./test-client.sh
```

## Available Commands

| # | Command | Description |
|---|---------|-------------|
| 1 | Test Health | Check if server is running |
| 2 | Register Reactor | Create a test reactor |
| 3 | Update Reactor | Update reactor heat/EU/status |
| 4 | List Reactors | Show all registered reactors |
| 5 | Register Battery | Create a test battery |
| 6 | Update Battery | Update battery EU levels |
| 7 | Get Recommendation | Get reactor scaling recommendation |
| 8 | Run All Tests | Execute all tests in sequence |
| 9 | Simulate Loop | Continuously update with random data |

## Simulate Mode

Option 9 runs a continuous loop that:
- Updates reactor with random heat (0-60%) and EU (400-500)
- Updates battery with random charge (0-100%)
- Refreshes every 2 seconds

This is useful for testing the dashboard's real-time display. Press Ctrl+C to stop.

## Manual cURL Examples

### Register a reactor
```bash
curl -X POST http://localhost:8081/portakalapi/opencomputers/reactormenagementV1/reactors \
  -H "X-API-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Reactor 1","address":"reactor-001"}'
```

### Update reactor status
```bash
curl -X PUT http://localhost:8081/portakalapi/opencomputers/reactormenagementV1/reactors/address/reactor-001 \
  -H "X-API-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"heatLevel":45,"euOutput":420,"status":"ONLINE"}'
```

### Update battery
```bash
curl -X PUT http://localhost:8081/portakalapi/opencomputers/batterymanagement/status/address/battery-001 \
  -H "X-API-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"currentEU":5000000,"maxEU":10000000}'
```