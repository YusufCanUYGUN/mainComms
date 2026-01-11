@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   MainCominotor Test Client
echo   Development Testing Tool
echo ========================================
echo.

REM Load config
for /f "tokens=1,2 delims==" %%a in (config.properties) do (
    if not "%%a"=="" if not "%%a:~0,1%"=="#" (
        set "%%a=%%b"
    )
)

REM Check if API_KEY is set
if "%API_KEY%"=="YOUR_API_KEY_HERE" (
    echo ERROR: Please set your API_KEY in config.properties
    echo.
    echo 1. Start the server: mvnw spring-boot:run
    echo 2. Go to %BASE_URL%/auth/register
    echo 3. Register an account
    echo 4. Go to %BASE_URL%/dashboard/api-keys
    echo 5. Create an API key and copy it
    echo 6. Edit config.properties and paste your key
    echo.
    pause
    exit /b 1
)

echo Base URL: %BASE_URL%
echo.

:menu
echo.
echo Choose an action:
echo   1. Test Health Endpoint
echo   2. Register Test Reactor
echo   3. Update Test Reactor
echo   4. List All Reactors
echo   5. Register Test Battery
echo   6. Update Test Battery
echo   7. Get Reactor Recommendation
echo   8. Run All Tests
echo   9. Simulate Reactor Loop
echo   0. Exit
echo.
set /p choice="Enter choice: "

if "%choice%"=="1" goto health
if "%choice%"=="2" goto register_reactor
if "%choice%"=="3" goto update_reactor
if "%choice%"=="4" goto list_reactors
if "%choice%"=="5" goto register_battery
if "%choice%"=="6" goto update_battery
if "%choice%"=="7" goto recommendation
if "%choice%"=="8" goto all_tests
if "%choice%"=="9" goto simulate
if "%choice%"=="0" goto end
goto menu

:health
echo.
echo Testing health endpoint...
curl -s "%BASE_URL%/health"
echo.
goto menu

:register_reactor
echo.
echo Registering test reactor...
curl -s -X POST "%BASE_URL%/opencomputers/reactormenagementV1/reactors" ^
    -H "X-API-Key: %API_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{\"name\":\"%REACTOR_NAME%\",\"address\":\"%REACTOR_ADDRESS%\"}"
echo.
goto menu

:update_reactor
echo.
set /p heat="Enter heat level (0-100): "
set /p eu="Enter EU output: "
set /p status="Enter status (ONLINE/OFFLINE/ERROR): "
echo Updating reactor...
curl -s -X PUT "%BASE_URL%/opencomputers/reactormenagementV1/reactors/address/%REACTOR_ADDRESS%" ^
    -H "X-API-Key: %API_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{\"heatLevel\":%heat%,\"euOutput\":%eu%,\"status\":\"%status%\"}"
echo.
goto menu

:list_reactors
echo.
echo Listing all reactors...
curl -s "%BASE_URL%/opencomputers/reactormenagementV1/reactors" ^
    -H "X-API-Key: %API_KEY%"
echo.
goto menu

:register_battery
echo.
echo Registering test battery...
curl -s -X POST "%BASE_URL%/opencomputers/batterymanagement/register" ^
    -H "X-API-Key: %API_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{\"name\":\"%BATTERY_NAME%\",\"address\":\"%BATTERY_ADDRESS%\"}"
echo.
goto menu

:update_battery
echo.
set /p current="Enter current EU: "
set /p max="Enter max EU: "
echo Updating battery...
curl -s -X PUT "%BASE_URL%/opencomputers/batterymanagement/status/address/%BATTERY_ADDRESS%" ^
    -H "X-API-Key: %API_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{\"currentEU\":%current%,\"maxEU\":%max%}"
echo.
goto menu

:recommendation
echo.
echo Getting reactor recommendation...
curl -s "%BASE_URL%/opencomputers/batterymanagement/reactor-recommendation" ^
    -H "X-API-Key: %API_KEY%"
echo.
goto menu

:all_tests
echo.
echo Running all tests...
echo.

echo [1/5] Testing health...
curl -s "%BASE_URL%/health"
echo.

echo [2/5] Registering reactor...
curl -s -X POST "%BASE_URL%/opencomputers/reactormenagementV1/reactors" ^
    -H "X-API-Key: %API_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{\"name\":\"%REACTOR_NAME%\",\"address\":\"%REACTOR_ADDRESS%\"}"
echo.

echo [3/5] Updating reactor...
curl -s -X PUT "%BASE_URL%/opencomputers/reactormenagementV1/reactors/address/%REACTOR_ADDRESS%" ^
    -H "X-API-Key: %API_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{\"heatLevel\":42,\"euOutput\":420,\"status\":\"ONLINE\"}"
echo.

echo [4/5] Registering battery...
curl -s -X POST "%BASE_URL%/opencomputers/batterymanagement/register" ^
    -H "X-API-Key: %API_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{\"name\":\"%BATTERY_NAME%\",\"address\":\"%BATTERY_ADDRESS%\"}"
echo.

echo [5/5] Updating battery...
curl -s -X PUT "%BASE_URL%/opencomputers/batterymanagement/status/address/%BATTERY_ADDRESS%" ^
    -H "X-API-Key: %API_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{\"currentEU\":5000000,\"maxEU\":10000000}"
echo.

echo All tests complete!
goto menu

:simulate
echo.
echo Simulating reactor/battery loop (Ctrl+C to stop)...
echo.
:simulate_loop
REM Simulate reactor data
set /a "heat=%RANDOM% %% 60"
set /a "eu=400 + %RANDOM% %% 100"
curl -s -X PUT "%BASE_URL%/opencomputers/reactormenagementV1/reactors/address/%REACTOR_ADDRESS%" ^
    -H "X-API-Key: %API_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{\"heatLevel\":%heat%,\"euOutput\":%eu%,\"status\":\"ONLINE\"}" > nul

REM Simulate battery data with slow drain/charge
set /a "battery=%RANDOM% %% 100"
set /a "current=battery * 100000"
curl -s -X PUT "%BASE_URL%/opencomputers/batterymanagement/status/address/%BATTERY_ADDRESS%" ^
    -H "X-API-Key: %API_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{\"currentEU\":%current%,\"maxEU\":10000000}" > nul

echo Updated: Heat=%heat%%%, EU=%eu%, Battery=%battery%%%
timeout /t 2 > nul
goto simulate_loop

:end
echo.
echo Goodbye!
endlocal