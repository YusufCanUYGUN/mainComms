# MainCominotor - Future Sections & Development Roadmap

This file tracks planned features and where to continue development.

---

## Completed Sections

### 1. Reactor Management (v1.0) ✅
- **Status**: Active
- **Path**: `/dashboard/reactors`
- **API**: `/opencomputers/reactormenagementV1/*`
- **Features**:
  - [x] Reactor registration and tracking
  - [x] Heat level monitoring
  - [x] EU output tracking
  - [x] Remote enable/disable
  - [x] Overheat protection
  - [x] Lua client integration

### 2. Battery Management (v1.0) ✅
- **Status**: Active
- **Path**: `/dashboard/battery`
- **API**: `/opencomputers/batterymanagement/*`
- **Features**:
  - [x] Battery registration
  - [x] EU storage tracking
  - [x] Charge percentage monitoring
  - [x] Gradual reactor scaling (20-90%)
  - [x] Reactor recommendation endpoint

### 3. API Key Management ✅
- **Status**: Active
- **Path**: `/dashboard/api-keys`
- **Features**:
  - [x] Secure key generation
  - [x] Multiple keys per user
  - [x] Key regeneration
  - [x] Key revocation

---
## Sections in need fixing ✅
- **Status**: Completed
- **Priority**: High (Done)

#### Server-Side Changes (Completed):
- [x] Reactor model updated with ControlMode (DISABLED/AUTO/FORCE_ACTIVE)
- [x] Server can disable reactors (DISABLED mode - never runs)
- [x] Server can force-active reactors (FORCE_ACTIVE mode - ignores battery)
- [x] Server auto mode (AUTO - battery-based gradual scaling 20-90%)
- [x] Manual reactor entry with redstone controller info (address, side)
- [x] Fuel slot configuration (slots and item type)
- [x] Cooling slot configuration (slots and item type)
- [x] Transposer configuration for refueling (address, reactor side, storage side)
- [x] Web UI updated with control mode buttons

#### Lua Client Changes (Completed):
- [x] Local config.lua for reactor/battery definitions (NOT fetched from server)
- [x] Update reactor control logic to use server control modes
- [x] Implement fuel rod replacement in configured slots
- [x] Implement cooling cell replacement in configured slots
- [x] Use transposer for item transfer (reactor side / storage side)
- [x] Safety checks before reactor operations
- [x] Handle DISABLED/AUTO/FORCE_ACTIVE control modes
- [x] Touch-capable GUI matching web dashboard functionality
- [x] Dashboard view with reactor list, battery status, stats
- [x] Reactor detail view with control mode buttons
- [x] Send status updates to server, receive control modes
- [x] Graceful operation when server is offline

---

## Planned Sections

### 4. AE2 Monitoring
- **Status**: Coming Soon
- **Priority**: none
- **Planned Path**: `/dashboard/ae2`
- **Planned API**: `/opencomputers/ae2/*`

#### Features to Implement:
- [ ] ME Controller connection
- [ ] Item storage monitoring
- [ ] Fluid storage monitoring
- [ ] Crafting CPU status
- [ ] Crafting job queue
- [ ] Pattern storage info
- [ ] Low stock alerts

#### Files to Create:
```
src/main/java/com/portakal/maincominotor/model/AE2System.java
src/main/java/com/portakal/maincominotor/model/AE2Item.java
src/main/java/com/portakal/maincominotor/repository/AE2Repository.java
src/main/java/com/portakal/maincominotor/service/AE2Service.java
src/main/java/com/portakal/maincominotor/controller/AE2Controller.java
src/main/resources/templates/ae2.html
lua/ae2_monitor.lua
```

---

### 5. GT Machine Control
- **Status**: Planned
- **Priority**: none
- **Planned Path**: `/dashboard/gt-machines`
- **Planned API**: `/opencomputers/gtmachines/*`

#### Features to Implement:
- [ ] Machine registration
- [ ] Processing status
- [ ] Input/output monitoring
- [ ] Recipe tracking
- [ ] Efficiency metrics
- [ ] Multi-block status
- [ ] Machine grouping

#### Files to Create:
```
src/main/java/com/portakal/maincominotor/model/GTMachine.java
src/main/java/com/portakal/maincominotor/model/GTMachineType.java
src/main/java/com/portakal/maincominotor/repository/GTMachineRepository.java
src/main/java/com/portakal/maincominotor/service/GTMachineService.java
src/main/java/com/portakal/maincominotor/controller/GTMachineController.java
src/main/resources/templates/gt-machines.html
lua/gt_monitor.lua
```

---

### 6. Alerts & Notifications
- **Status**: Planned
- **Priority**: low
- **Planned Path**: `/dashboard/alerts`
- **Planned API**: `/api/alerts/*`

#### Features to Implement:
- [ ] Alert rule configuration
- [ ] Email notifications
- [ ] Discord webhook integration
- [ ] In-game chat integration (via OC)
- [ ] Alert history log
- [ ] Severity levels (info, warning, critical)

#### Alert Types:
- Reactor overheat (>80% heat)
- Battery low (<10%)
- Battery critical (<5%)
- Reactor offline unexpectedly
- Machine stopped/errored
- AE2 storage full
- Item stock low

#### Files to Create:
```
src/main/java/com/portakal/maincominotor/model/Alert.java
src/main/java/com/portakal/maincominotor/model/AlertRule.java
src/main/java/com/portakal/maincominotor/service/AlertService.java
src/main/java/com/portakal/maincominotor/service/NotificationService.java
src/main/java/com/portakal/maincominotor/controller/AlertController.java
src/main/resources/templates/alerts.html
```

---

### 7. Statistics & Graphs
- **Status**: Planned
- **Priority**: Low
- **Planned Path**: `/dashboard/stats`

#### Features to Implement:
- [ ] Historical EU production graphs
- [ ] Battery charge history
- [ ] Reactor uptime statistics
- [ ] Peak usage times
- [ ] Export data (CSV/JSON)

---

### 8. Multi-Base Support
- **Status**: Planned
- **Priority**: Low

#### Features to Implement:
- [ ] Multiple base locations
- [ ] Base-specific dashboards
- [ ] Cross-base statistics
- [ ] Base switching in UI

---

## Production Deployment

### application.properties Changes for Production

```properties
# MySQL Database (replace H2 settings)
spring.datasource.url=jdbc:mysql://localhost:3306/maincominotor?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
spring.datasource.driverClassName=com.mysql.cj.jdbc.Driver
spring.datasource.username=maincominotor
spring.datasource.password=YOUR_PASSWORD_HERE

# JPA/Hibernate
spring.jpa.database-platform=org.hibernate.dialect.MySQLDialect
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false

# Disable H2 Console
spring.h2.console.enabled=false

# Enable Thymeleaf caching
spring.thymeleaf.cache=true

# Logging
logging.file.name=logs/maincominotor.log
```

### MySQL Setup

```sql
CREATE DATABASE maincominotor CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'maincominotor'@'localhost' IDENTIFIED BY 'YOUR_PASSWORD_HERE';
GRANT ALL PRIVILEGES ON maincominotor.* TO 'maincominotor'@'localhost';
FLUSH PRIVILEGES;
```

### Build & Run

```bash
# Build JAR
./mvnw clean package -DskipTests

# Run
java -jar target/mainCominotor-0.0.1-SNAPSHOT.jar
```

### Nginx Reverse Proxy (Optional)

```nginx
location /portakalapi/ {
    proxy_pass http://localhost:8081/portakalapi/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

---

## Development Notes

### Current State
- **Last Updated**: 2024
- **Current Version**: 1.0.0
- **Spring Boot**: 4.0.1
- **Java**: 21

### Next Steps
1. Implement AE2 Monitoring (highest priority)
2. Add historical data storage for graphs
3. Implement alert system foundation
4. Add GT machine monitoring

### API Versioning
- Reactor API: `reactormenagementV1` (current)
- Battery API: `batterymanagement` (current)
- Future APIs should follow pattern: `{feature}V{version}`

### Database Considerations
- Currently using H2 for development
- MySQL connector ready for production
- Consider adding migration scripts (Flyway/Liquibase) before adding more tables

---

## Quick Resume Guide

To continue development:

1. **Pick a section** from "Planned Sections" above
2. **Create model entities** first
3. **Create repository** interfaces
4. **Implement service** layer
5. **Create controller** (REST for API, MVC for dashboard)
6. **Create templates** for web UI
7. **Create Lua client** for OpenComputers
8. **Update home.html** to enable the section card
9. **Update this file** to mark as completed

---

## File Structure Reference

```
src/main/java/com/portakal/maincominotor/
├── config/          # Spring configuration
├── controller/      # Web & API controllers
├── dto/             # Data transfer objects
├── model/           # JPA entities
├── repository/      # Spring Data repositories
├── security/        # Security filters & services
└── service/         # Business logic

src/main/resources/
├── static/
│   ├── css/         # Stylesheets
│   └── js/          # JavaScript
├── templates/       # Thymeleaf templates
│   └── auth/        # Login/register pages
└── application.properties

lua/                 # OpenComputers Lua scripts
├── lib/             # Lua libraries
├── config.lua       # Client configuration
├── gui.lua          # Display module
└── reactor_controller.lua  # Main script
```

---

## Claude AI Assistance Guide

This section helps Claude (or any AI assistant) understand and continue development on this project.

### Project Context
MainCominotor is a web server for managing Minecraft GregTech New Horizons (GTNH) IC2 reactors via OpenComputers. It consists of:
1. **Spring Boot Backend** - REST API + Thymeleaf web dashboard
2. **OpenComputers Lua Client** - Runs in-game, controls reactors autonomously

### Key Architecture Decisions
- **Dual Authentication**: Form login for web UI, API key header (`X-API-Key`) for Lua clients
- **Multi-User**: Each user owns their reactors/batteries, isolated data
- **Gradual Battery Management**: Reactors scale proportionally between 20-90% battery
- **Autonomous Lua Client**: Works without server, server provides remote override

### Important Patterns
1. **Controllers**: Web views in `DashboardController`, REST API in feature-specific controllers
2. **DTOs**: Use DTOs for API responses, entities for JPA
3. **Security**: `ApiKeyAuthenticationFilter` validates Lua client requests
4. **Templates**: Thymeleaf with `dashboard.css` for consistent styling

### When Continuing Development
1. Read this file first for context
2. Check "Sections in need fixing" for urgent tasks
3. Check "Planned Sections" for new features
4. Follow the "Quick Resume Guide" pattern
5. Update this file when completing sections

### Common Tasks
- **Add new dashboard page**: Create template, add route in `DashboardController`, update navbar
- **Add new API endpoint**: Create controller with `@RestController`, secure with API key
- **Add new entity**: Create model -> repository -> service -> controller
- **Update Lua client**: Modify files in `lua/` directory

### URLs Reference
- **Production**: `https://uygunfamily.duckdns.org/portakalapi/`
- **Development**: `http://localhost:8081/portakalapi/`
- **Reactor API**: `/opencomputers/reactormenagementV1/*`
- **Battery API**: `/opencomputers/batterymanagement/*`

### Plan File Location
Detailed implementation plan: `.claude/plans/abundant-strolling-lollipop.md`
