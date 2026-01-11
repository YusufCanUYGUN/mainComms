# MainCominotor - Deployment & Usage Guide

## Table of Contents
1. [Requirements](#requirements)
2. [Development Setup](#development-setup)
3. [Production Deployment](#production-deployment)
4. [OpenComputers Setup](#opencomputers-setup)
5. [API Reference](#api-reference)
6. [Troubleshooting](#troubleshooting)

---

## Requirements

### Server Requirements
- Java 21 or higher
- Maven 3.8+ (included via Maven Wrapper)
- 512MB RAM minimum (1GB recommended)
- Port 8081 (configurable)

### For Production
- MySQL 8.0+ (optional, H2 works for single-user)
- Reverse proxy (nginx/Apache) for HTTPS
- SSL certificate (Let's Encrypt recommended)

### Minecraft Requirements
- OpenComputers mod
- Internet Card component
- Screen + GPU (for graphical display)
- IC2 reactors connected via cables/adapters

---

## Development Setup

### 1. Clone & Build

```bash
# Clone the repository
git clone <repository-url>
cd mainCominotor

# Build the project
./mvnw clean compile

# Run in development mode
./mvnw spring-boot:run
```

### 2. Access Development Server

- **Home Page**: http://localhost:8081/portakalapi/
- **Login**: http://localhost:8081/portakalapi/auth/login
- **Register**: http://localhost:8081/portakalapi/auth/register
- **Dashboard**: http://localhost:8081/portakalapi/dashboard
- **H2 Console**: http://localhost:8081/portakalapi/h2-console

### 3. H2 Console Access (Development)

```
JDBC URL: jdbc:h2:file:./data/maincominotor
Username: sa
Password: (empty)
```

### 4. Test with Dummy Client

```bash
# Run the test client
cd test-client
# On Windows:
test-client.bat

# Or use curl directly:
curl -X POST http://localhost:8081/portakalapi/opencomputers/reactormenagementV1/reactors \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Reactor","address":"test-001"}'
```

---

## Production Deployment

### 1. Configure MySQL (Optional)

Create database and user:
```sql
CREATE DATABASE maincominotor;
CREATE USER 'maincominotor'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON maincominotor.* TO 'maincominotor'@'localhost';
FLUSH PRIVILEGES;
```

### 2. Create Production Properties

Create `application-prod.properties`:
```properties
spring.application.name=mainCominotor
server.port=8081
server.servlet.context-path=/portakalapi
server.forward-headers-strategy=native

# MySQL Database
spring.datasource.url=jdbc:mysql://localhost:3306/maincominotor?useSSL=true&serverTimezone=UTC
spring.datasource.username=maincominotor
spring.datasource.password=your_secure_password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA/Hibernate
spring.jpa.database-platform=org.hibernate.dialect.MySQLDialect
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false

# Disable H2 console in production
spring.h2.console.enabled=false

# Thymeleaf
spring.thymeleaf.cache=true

# Logging
logging.level.com.portakal.maincominotor=INFO
logging.file.name=/var/log/maincominotor/app.log
```

### 3. Build JAR

```bash
./mvnw clean package -DskipTests
```

The JAR will be in `target/mainCominotor-0.0.1-SNAPSHOT.jar`

### 4. Run as Service (Linux)

Create systemd service `/etc/systemd/system/maincominotor.service`:
```ini
[Unit]
Description=MainCominotor Reactor Management
After=network.target mysql.service

[Service]
User=maincominotor
WorkingDirectory=/opt/maincominotor
ExecStart=/usr/bin/java -jar -Dspring.profiles.active=prod mainCominotor.jar
SuccessExitStatus=143
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable maincominotor
sudo systemctl start maincominotor
```

### 5. Nginx Reverse Proxy

```nginx
server {
    listen 443 ssl http2;
    server_name uygunfamily.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/uygunfamily.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/uygunfamily.duckdns.org/privkey.pem;

    location /portakalapi/ {
        proxy_pass http://127.0.0.1:8081/portakalapi/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name uygunfamily.duckdns.org;
    return 301 https://$server_name$request_uri;
}
```

---

## OpenComputers Setup

### 1. Required Components

Your OpenComputers computer needs:
- **CPU** (Tier 2+ recommended)
- **Memory** (Tier 2+ recommended)
- **Internet Card** (required for server communication)
- **Hard Disk** (for storing scripts)
- **EEPROM** (with Lua BIOS)
- **Screen + GPU** (optional, for graphical display)
- **Adapter** (to connect to IC2 reactors)

### 2. Install Lua Scripts

Copy the files from the `lua/` folder to your OpenComputers computer:

```
/home/
├── reactor_controller.lua
├── gui.lua
├── config.lua
└── lib/
    ├── api.lua
    └── draw.lua
```

You can use `wget` if your OC computer has internet:
```lua
-- From OpenComputers shell:
wget https://your-server/lua/reactor_controller.lua /home/reactor_controller.lua
wget https://your-server/lua/config.lua /home/config.lua
-- etc.
```

### 3. Configure

Edit `/home/config.lua`:
```lua
local config = {
    server = {
        url = "https://uygunfamily.duckdns.org/portakalapi",
        apiKey = "YOUR_API_KEY_HERE",  -- Get from web dashboard
        timeout = 10
    },
    battery = {
        lowThreshold = 20,
        highThreshold = 90,
    },
    -- ... rest of config
}
```

### 4. Get Your API Key

1. Go to https://uygunfamily.duckdns.org/portakalapi/
2. Register an account or login
3. Go to **API Keys** section
4. Create a new API key
5. Copy the key immediately (it won't be shown again)
6. Paste into your `config.lua`

### 5. Run the Controller

```lua
-- From OpenComputers shell:
/home/reactor_controller.lua
```

Or set it to auto-start by adding to `/home/.shrc`:
```lua
/home/reactor_controller.lua
```

---

## API Reference

### Base URLs
- **Development**: `http://localhost:8081/portakalapi`
- **Production**: `https://uygunfamily.duckdns.org/portakalapi`

### Authentication
All API endpoints require the `X-API-Key` header:
```
X-API-Key: your-api-key-here
```

### Reactor Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/opencomputers/reactormenagementV1/reactors` | List all reactors |
| GET | `/opencomputers/reactormenagementV1/reactors/{id}` | Get reactor by ID |
| POST | `/opencomputers/reactormenagementV1/reactors` | Register new reactor |
| PUT | `/opencomputers/reactormenagementV1/reactors/{id}` | Update reactor data |
| PUT | `/opencomputers/reactormenagementV1/reactors/address/{address}` | Update by address |
| POST | `/opencomputers/reactormenagementV1/reactors/{id}/enable` | Enable reactor |
| POST | `/opencomputers/reactormenagementV1/reactors/{id}/disable` | Disable reactor |
| DELETE | `/opencomputers/reactormenagementV1/reactors/{id}` | Delete reactor |

#### Register Reactor
```bash
curl -X POST http://localhost:8081/portakalapi/opencomputers/reactormenagementV1/reactors \
  -H "X-API-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Reactor 1","address":"abc-123-def"}'
```

#### Update Reactor
```bash
curl -X PUT http://localhost:8081/portakalapi/opencomputers/reactormenagementV1/reactors/1 \
  -H "X-API-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"heatLevel":45,"euOutput":420,"status":"ONLINE"}'
```

### Battery Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/opencomputers/batterymanagement/status` | Get all batteries |
| GET | `/opencomputers/batterymanagement/status/{id}` | Get battery by ID |
| POST | `/opencomputers/batterymanagement/register` | Register new battery |
| PUT | `/opencomputers/batterymanagement/status/{id}` | Update battery data |
| PUT | `/opencomputers/batterymanagement/status/address/{address}` | Update by address |
| GET | `/opencomputers/batterymanagement/reactor-recommendation` | Get reactor scaling recommendation |

#### Get Reactor Recommendation
```bash
curl http://localhost:8081/portakalapi/opencomputers/batterymanagement/reactor-recommendation \
  -H "X-API-Key: YOUR_KEY"
```

Response:
```json
{
  "success": true,
  "data": {
    "avgChargePercent": 55,
    "totalReactors": 5,
    "recommendedActiveReactors": 3
  }
}
```

---

## Troubleshooting

### Server Issues

**Application won't start**
- Check Java version: `java -version` (must be 21+)
- Check port availability: `netstat -an | grep 8081`
- Check logs: `tail -f /var/log/maincominotor/app.log`

**Database connection failed**
- Verify MySQL is running: `systemctl status mysql`
- Check credentials in `application-prod.properties`
- Test connection: `mysql -u maincominotor -p maincominotor`

**502 Bad Gateway (nginx)**
- Check if app is running: `systemctl status maincominotor`
- Check nginx config: `nginx -t`
- Check proxy_pass URL matches app port

### OpenComputers Issues

**"Internet card not found"**
- Make sure Internet Card is installed in the computer
- Restart the computer after adding the card

**"Connection refused" or timeout**
- Verify server URL in config.lua
- Check if server is accessible from Minecraft server's network
- Test with: `wget <server-url>/health`

**"Invalid API key"**
- Regenerate API key from web dashboard
- Make sure there are no extra spaces in config.lua
- Check key is enabled (not revoked)

**Reactors not being detected**
- Connect reactors via Adapter blocks
- Check cable connections
- Use `components` command in OC shell to list available components

### Common API Errors

| Code | Meaning | Solution |
|------|---------|----------|
| 401 | Unauthorized | Check X-API-Key header |
| 403 | Forbidden | API key valid but user lacks permission |
| 404 | Not Found | Check endpoint URL and resource ID |
| 500 | Server Error | Check server logs |

---

## Useful Commands

```bash
# View logs
tail -f /var/log/maincominotor/app.log

# Restart service
sudo systemctl restart maincominotor

# Check service status
sudo systemctl status maincominotor

# Rebuild and deploy
./mvnw clean package -DskipTests
sudo cp target/mainCominotor*.jar /opt/maincominotor/
sudo systemctl restart maincominotor
```
