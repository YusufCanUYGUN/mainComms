#!/bin/bash

echo "========================================"
echo "  MainCominotor Test Client"
echo "  Development Testing Tool"
echo "========================================"
echo ""

# Load config
source <(grep -v '^#' config.properties | sed 's/ *= */=/g')

# Check if API_KEY is set
if [ "$API_KEY" == "YOUR_API_KEY_HERE" ]; then
    echo "ERROR: Please set your API_KEY in config.properties"
    echo ""
    echo "1. Start the server: ./mvnw spring-boot:run"
    echo "2. Go to $BASE_URL/auth/register"
    echo "3. Register an account"
    echo "4. Go to $BASE_URL/dashboard/api-keys"
    echo "5. Create an API key and copy it"
    echo "6. Edit config.properties and paste your key"
    exit 1
fi

echo "Base URL: $BASE_URL"
echo ""

show_menu() {
    echo ""
    echo "Choose an action:"
    echo "  1. Test Health Endpoint"
    echo "  2. Register Test Reactor"
    echo "  3. Update Test Reactor"
    echo "  4. List All Reactors"
    echo "  5. Register Test Battery"
    echo "  6. Update Test Battery"
    echo "  7. Get Reactor Recommendation"
    echo "  8. Run All Tests"
    echo "  9. Simulate Reactor Loop"
    echo "  0. Exit"
    echo ""
    read -p "Enter choice: " choice
}

test_health() {
    echo ""
    echo "Testing health endpoint..."
    curl -s "$BASE_URL/health"
    echo ""
}

register_reactor() {
    echo ""
    echo "Registering test reactor..."
    curl -s -X POST "$BASE_URL/opencomputers/reactormenagementV1/reactors" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$REACTOR_NAME\",\"address\":\"$REACTOR_ADDRESS\"}"
    echo ""
}

update_reactor() {
    echo ""
    read -p "Enter heat level (0-100): " heat
    read -p "Enter EU output: " eu
    read -p "Enter status (ONLINE/OFFLINE/ERROR): " status
    echo "Updating reactor..."
    curl -s -X PUT "$BASE_URL/opencomputers/reactormenagementV1/reactors/address/$REACTOR_ADDRESS" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"heatLevel\":$heat,\"euOutput\":$eu,\"status\":\"$status\"}"
    echo ""
}

list_reactors() {
    echo ""
    echo "Listing all reactors..."
    curl -s "$BASE_URL/opencomputers/reactormenagementV1/reactors" \
        -H "X-API-Key: $API_KEY" | python3 -m json.tool 2>/dev/null || cat
    echo ""
}

register_battery() {
    echo ""
    echo "Registering test battery..."
    curl -s -X POST "$BASE_URL/opencomputers/batterymanagement/register" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$BATTERY_NAME\",\"address\":\"$BATTERY_ADDRESS\"}"
    echo ""
}

update_battery() {
    echo ""
    read -p "Enter current EU: " current
    read -p "Enter max EU: " max
    echo "Updating battery..."
    curl -s -X PUT "$BASE_URL/opencomputers/batterymanagement/status/address/$BATTERY_ADDRESS" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"currentEU\":$current,\"maxEU\":$max}"
    echo ""
}

get_recommendation() {
    echo ""
    echo "Getting reactor recommendation..."
    curl -s "$BASE_URL/opencomputers/batterymanagement/reactor-recommendation" \
        -H "X-API-Key: $API_KEY" | python3 -m json.tool 2>/dev/null || cat
    echo ""
}

run_all_tests() {
    echo ""
    echo "Running all tests..."
    echo ""

    echo "[1/5] Testing health..."
    curl -s "$BASE_URL/health"
    echo ""

    echo "[2/5] Registering reactor..."
    curl -s -X POST "$BASE_URL/opencomputers/reactormenagementV1/reactors" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$REACTOR_NAME\",\"address\":\"$REACTOR_ADDRESS\"}"
    echo ""

    echo "[3/5] Updating reactor..."
    curl -s -X PUT "$BASE_URL/opencomputers/reactormenagementV1/reactors/address/$REACTOR_ADDRESS" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"heatLevel":42,"euOutput":420,"status":"ONLINE"}'
    echo ""

    echo "[4/5] Registering battery..."
    curl -s -X POST "$BASE_URL/opencomputers/batterymanagement/register" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$BATTERY_NAME\",\"address\":\"$BATTERY_ADDRESS\"}"
    echo ""

    echo "[5/5] Updating battery..."
    curl -s -X PUT "$BASE_URL/opencomputers/batterymanagement/status/address/$BATTERY_ADDRESS" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"currentEU":5000000,"maxEU":10000000}'
    echo ""

    echo "All tests complete!"
}

simulate_loop() {
    echo ""
    echo "Simulating reactor/battery loop (Ctrl+C to stop)..."
    echo ""

    while true; do
        # Random values
        heat=$((RANDOM % 60))
        eu=$((400 + RANDOM % 100))
        battery=$((RANDOM % 100))
        current=$((battery * 100000))

        # Update reactor
        curl -s -X PUT "$BASE_URL/opencomputers/reactormenagementV1/reactors/address/$REACTOR_ADDRESS" \
            -H "X-API-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"heatLevel\":$heat,\"euOutput\":$eu,\"status\":\"ONLINE\"}" > /dev/null

        # Update battery
        curl -s -X PUT "$BASE_URL/opencomputers/batterymanagement/status/address/$BATTERY_ADDRESS" \
            -H "X-API-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"currentEU\":$current,\"maxEU\":10000000}" > /dev/null

        echo "Updated: Heat=${heat}%, EU=$eu, Battery=${battery}%"
        sleep 2
    done
}

# Main loop
while true; do
    show_menu
    case $choice in
        1) test_health ;;
        2) register_reactor ;;
        3) update_reactor ;;
        4) list_reactors ;;
        5) register_battery ;;
        6) update_battery ;;
        7) get_recommendation ;;
        8) run_all_tests ;;
        9) simulate_loop ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option" ;;
    esac
done