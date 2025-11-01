# Technical Specifications Document

**Version:** 1.0  
**Date:** October 30, 2025  
**Document Type:** Technical Architecture & Requirements

---

## Overview

This document outlines the technical architecture, infrastructure requirements, and implementation details for Battle Castles. The system is designed for scalability, low latency, and cross-platform compatibility.

---

## Technical Requirements

### Target Specifications

**Mobile (Primary Platform):**
- **Minimum Requirements:**
  - iOS 12+ (iPhone 7 and newer)
  - Android 8.0+ (2GB RAM minimum)
  - 200MB storage space
  - WiFi or 4G connection
  
- **Recommended Requirements:**
  - iOS 14+ (iPhone 11 and newer)
  - Android 10+ (4GB RAM)
  - 300MB storage space
  - WiFi or 5G connection

**PC (Secondary Platform):**
- **Minimum Requirements:**
  - Windows 10 64-bit
  - Intel Core i3 or equivalent
  - 4GB RAM
  - Integrated graphics
  - 500MB storage
  - Broadband internet

- **Recommended Requirements:**
  - Windows 11 64-bit
  - Intel Core i5 or equivalent
  - 8GB RAM
  - Dedicated GPU
  - 1GB storage
  - High-speed broadband

### Performance Targets

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| Frame Rate (Mobile) | 60 FPS | 45 FPS | 30 FPS |
| Frame Rate (PC) | 144 FPS | 60 FPS | 30 FPS |
| Match Start Time | <15s | <30s | <45s |
| Network Latency | <50ms | <100ms | <150ms |
| Battery Drain | <3%/match | <5%/match | <8%/match |
| App Launch Time | <3s | <5s | <8s |
| Crash Rate | <0.1% | <1% | <5% |

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────┐
│                   CLIENT LAYER                   │
│  ┌─────────────┐  ┌─────────────┐              │
│  │ Mobile App  │  │   PC App    │              │
│  │  (Unity)    │  │  (Unity)    │              │
│  └─────────────┘  └─────────────┘              │
└───────────────┬─────────────────────────────────┘
                │
           ┌────▼────┐
           │   CDN   │ (Static Assets)
           └─────────┘
                │
┌───────────────▼─────────────────────────────────┐
│              API GATEWAY LAYER                   │
│  ┌─────────────────────────────────────────┐   │
│  │   Load Balancer / Rate Limiter          │   │
│  │   (NGINX + Cloudflare)                  │   │
│  └─────────────────────────────────────────┘   │
└───────────────┬─────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────┐
│              BACKEND SERVICES                    │
│  ┌────────────┐  ┌────────────┐  ┌──────────┐ │
│  │  Game      │  │ Matchmaking│  │   Chat   │ │
│  │  Server    │  │  Service   │  │ Service  │ │
│  │ (Node.js)  │  │  (Go)      │  │(Node.js) │ │
│  └────────────┘  └────────────┘  └──────────┘ │
│                                                  │
│  ┌────────────┐  ┌────────────┐  ┌──────────┐ │
│  │  Auth      │  │  Economy   │  │Analytics │ │
│  │  Service   │  │  Service   │  │ Service  │ │
│  │ (Node.js)  │  │  (Python)  │  │ (Python) │ │
│  └────────────┘  └────────────┘  └──────────┘ │
└───────────────┬─────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────┐
│               DATA LAYER                         │
│  ┌────────────┐  ┌────────────┐  ┌──────────┐ │
│  │ PostgreSQL │  │   Redis    │  │   S3     │ │
│  │ (Primary)  │  │  (Cache)   │  │ (Replays)│ │
│  └────────────┘  └────────────┘  └──────────┘ │
│                                                  │
│  ┌────────────┐  ┌────────────┐               │
│  │  MongoDB   │  │ Kafka      │               │
│  │ (Logs)     │  │ (Events)   │               │
│  └────────────┘  └────────────┘               │
└─────────────────────────────────────────────────┘
```

---

## Technology Stack

### Client-Side

**Game Engine: Unity 2022.3 LTS**
- **Why Unity:**
  - Cross-platform support (iOS, Android, PC, WebGL)
  - Robust 2D rendering pipeline
  - Large asset store ecosystem
  - Mature networking solutions
  - Strong community support

**Programming Language:**
- C# (Unity scripting)
- Shader language: HLSL/ShaderLab

**Key Frameworks & Libraries:**
- **Unity Netcode for GameObjects** - Networking layer
- **DOTween** - Animation tweening
- **TextMeshPro** - Advanced text rendering
- **Unity IAP** - In-app purchases
- **Firebase SDK** - Analytics, crash reporting
- **Addressables** - Asset management

**Build System:**
- Unity Cloud Build for CI/CD
- Git LFS for large binary files
- Automated testing with Unity Test Framework

### Server-Side

**Primary Stack:**

**Game Server: Node.js + Express**
- **Why Node.js:**
  - Non-blocking I/O for real-time games
  - Easy WebSocket integration
  - Fast iteration cycles
  - JavaScript ecosystem

**Matchmaking Service: Go (Golang)**
- **Why Go:**
  - High concurrency performance
  - Low latency
  - Efficient memory usage
  - Perfect for real-time matching algorithms

**Authentication: Node.js + Passport.js**
- JWT token-based authentication
- OAuth2 for social logins
- Session management with Redis

**Economy Service: Python + FastAPI**
- **Why Python:**
  - Excellent for data processing
  - NumPy/Pandas for economy simulations
  - ML integration for fraud detection

**Analytics: Python + Apache Spark**
- Batch processing of player data
- Real-time analytics dashboard
- Predictive modeling for churn

### Database Layer

**Primary Database: PostgreSQL 14**
- **Purpose:** Player profiles, inventory, match results
- **Why PostgreSQL:**
  - ACID compliance
  - Complex queries (leaderboards, statistics)
  - Strong consistency requirements
  - Excellent performance at scale

**Schema Overview:**
```sql
-- Core tables
players (id, username, email, created_at, trophy_count)
cards (id, name, rarity, base_stats)
player_cards (player_id, card_id, level, count)
matches (id, player1_id, player2_id, winner_id, replay_data, timestamp)
clans (id, name, badge, trophy_requirement)
purchases (id, player_id, product_id, amount, timestamp)
```

**Cache Layer: Redis 7**
- **Purpose:** Session storage, matchmaking queue, real-time leaderboards
- **Use Cases:**
  - Active player sessions (TTL: 30 minutes)
  - Matchmaking pools (sorted sets)
  - Rate limiting counters
  - Temporary battle states

**Logging & Events: MongoDB**
- **Purpose:** Application logs, player behavior events
- **Why MongoDB:**
  - Flexible schema for varied event types
  - Fast writes for high-volume logging
  - Time-series data optimization

**Event Streaming: Apache Kafka**
- **Purpose:** Real-time event processing
- **Topics:**
  - match_events (battle start, end, actions)
  - economy_events (purchases, rewards)
  - player_events (login, logout, achievements)

**Object Storage: AWS S3 / Cloudflare R2**
- **Purpose:** Replay files, player avatars, asset bundles
- **Configuration:**
  - Replay compression (gzip)
  - CDN integration for global distribution
  - Lifecycle policies (delete old replays after 30 days)

---

## Networking Architecture

### Communication Protocols

**Battle Synchronization:**
- **Protocol:** WebSocket (Socket.io)
- **Why:** Bidirectional, low-latency, real-time updates
- **Fallback:** Long-polling for restrictive networks

**API Communication:**
- **Protocol:** HTTPS REST API
- **Format:** JSON
- **Authentication:** Bearer tokens (JWT)

### Client-Server Model

**Authoritative Server (Anti-Cheat):**
- Server is the source of truth
- Client sends player inputs only
- Server validates all actions
- Server calculates game state
- Client receives state updates and renders

**Data Flow Example:**

```
1. Client: "Deploy Knight at (x:5, y:10)"
   → Server validates:
     - Has player unlocked Knight?
     - Does player have 3 elixir?
     - Is position valid (player's side)?
   
2. Server: "Approved. Knight spawned at (x:5, y:10)"
   → Both clients receive update
   
3. Client: Renders Knight spawning animation
```

**Update Frequency:**
- **Position Updates:** 10 Hz (every 100ms)
- **Combat Events:** Immediate (as they occur)
- **Elixir Updates:** 1 Hz (every second)

### Matchmaking System

**Queue Architecture:**

```
┌────────────────────────────────────────┐
│         Matchmaking Service             │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Player Queue (Redis Sorted Set) │  │
│  │  Score = Trophy Count            │  │
│  │  [Player A: 2500]                │  │
│  │  [Player B: 2480]  ← Match!      │  │
│  │  [Player C: 2460]                │  │
│  │  [Player D: 1200]                │  │
│  └──────────────────────────────────┘  │
│                                         │
│  Matching Algorithm:                    │
│  1. Find players within ±50 trophies   │
│  2. Expand search by +50 every 5s      │
│  3. Max expansion: ±200 trophies       │
│  4. Timeout: 60 seconds                │
└────────────────────────────────────────┘
```

**Matching Criteria:**
1. **Primary:** Trophy count (±50 initially)
2. **Secondary:** Card level average (prevent mismatches)
3. **Tertiary:** Region (reduce latency)
4. **Timeout:** Match any available after 60s

**Match Quality Score:**
```
Quality = 100 - (|TrophyDiff| * 0.5) - (|CardLevelDiff| * 5) - (Latency / 10)
```

**Optimal Match:** Quality score > 90  
**Acceptable Match:** Quality score > 70  
**Last Resort:** Any available match after timeout

### Network Optimization

**Latency Compensation:**
- **Client-Side Prediction:** Client predicts unit movement locally
- **Server Reconciliation:** Corrects client if prediction wrong
- **Interpolation:** Smooth movement between server updates
- **Lag Compensation:** Rewind time for hit detection (up to 150ms)

**Bandwidth Optimization:**
- **Delta Compression:** Only send changes, not full state
- **Message Batching:** Group small updates together
- **Priority System:** Critical events (death) sent immediately, positions buffered

**Regional Servers:**
- **North America:** AWS us-east-1 (Virginia), us-west-2 (Oregon)
- **Europe:** AWS eu-west-1 (Ireland)
- **Asia:** AWS ap-southeast-1 (Singapore)
- **South America:** AWS sa-east-1 (São Paulo)

**Latency Targets by Region:**
| Region Pair | Target | Acceptable |
|-------------|--------|------------|
| Same region | <30ms | <50ms |
| Adjacent | <80ms | <120ms |
| Cross-continent | <150ms | <200ms |

---

## Game Logic Implementation

### Battle State Machine

**State Flow:**

```
WAITING
  ↓
MATCHMAKING (find opponent)
  ↓
LOADING (sync game assets)
  ↓
BATTLE_START (3-2-1 countdown)
  ↓
ACTIVE (main gameplay)
  ↓ (time expires or castle destroyed)
OVERTIME (if tied)
  ↓
BATTLE_END
  ↓
RESULTS_SCREEN
  ↓
RETURN_TO_MENU
```

**Server Battle Loop (60 Hz):**

```javascript
// Pseudocode
function battleTick(deltaTime) {
  // 1. Process player inputs
  for (let input of playerInputQueue) {
    validateAndExecute(input);
  }
  
  // 2. Update game state
  updateElixir(deltaTime);
  updateUnits(deltaTime);
  processCombat();
  updateBuildings();
  
  // 3. Check victory conditions
  if (checkVictory()) {
    endBattle();
  }
  
  // 4. Send state to clients
  broadcastState();
}
```

### Unit AI System

**Behavior Tree Structure:**

```
Root: Selector
├─ IsEnemyInRange?
│  └─ AttackEnemy (Action)
├─ IsNearBuilding?
│  └─ AttackBuilding (Action)
└─ MoveForward (Action)
```

**Pathfinding:**
- **Algorithm:** A* for navigation
- **Grid Size:** 20x30 tiles (0.5 units per tile)
- **Obstacles:** Other units, rivers, buildings
- **Performance:** Max 40 units, pathfinding cached per frame

### Damage Calculation

```javascript
function calculateDamage(attacker, defender) {
  let baseDamage = attacker.damage;
  
  // Level scaling
  baseDamage *= (1 + (attacker.level - 1) * 0.1);
  
  // Type modifiers (future: rock-paper-scissors)
  let typeMultiplier = getTypeAdvantage(attacker.type, defender.type);
  
  // Building damage reduction (Giants)
  if (attacker.targetType === 'building' && defender.isBuilding) {
    baseDamage *= 0.65; // Giants take 35% less from towers
  }
  
  // Critical hits (future feature)
  let isCrit = Math.random() < 0.05; // 5% crit chance
  if (isCrit) baseDamage *= 1.5;
  
  return Math.floor(baseDamage);
}
```

### Replay System

**Data Storage:**

```javascript
// Replay data structure
{
  matchId: "abc123",
  version: "1.0",
  players: [
    { id: "player1", username: "John", deck: [...] },
    { id: "player2", username: "Jane", deck: [...] }
  ],
  events: [
    { time: 0.0, type: "match_start" },
    { time: 5.2, type: "unit_deploy", player: 0, unit: "knight", x: 5, y: 10 },
    { time: 6.8, type: "unit_spawn", unitId: 1, unit: "knight", x: 5, y: 10 },
    { time: 12.1, type: "combat", attacker: 1, defender: 5, damage: 75 },
    { time: 18.5, type: "unit_death", unitId: 5 },
    // ... all game events
    { time: 180.0, type: "match_end", winner: "player1" }
  ]
}
```

**Replay Playback:**
- Client reconstructs battle from event log
- Deterministic simulation (same input = same output)
- Can skip, pause, slow-mo
- Compressed file size: ~50KB per 3-minute match

---

## Security & Anti-Cheat

### Authentication & Authorization

**Authentication Flow:**

```
1. User Login → Server
2. Server validates credentials
3. Generate JWT token (expires in 7 days)
4. Client stores token securely (Keychain/Keystore)
5. All API requests include Authorization header
6. Server validates token on each request
```

**JWT Token Payload:**
```json
{
  "userId": "12345",
  "username": "Player1",
  "role": "player",
  "trophies": 2500,
  "iat": 1698724800,
  "exp": 1699329600
}
```

### Anti-Cheat Measures

**Server-Side Validation:**
1. **Input Validation:**
   - All player actions validated server-side
   - Impossible actions rejected (e.g., deploy without elixir)
   - Rate limiting on actions (prevent bot spam)

2. **State Integrity:**
   - Server maintains authoritative game state
   - Client rendering can't affect gameplay
   - Checksums verify data integrity

3. **Behavioral Analysis:**
   - Detect impossible reaction times (< 50ms)
   - Flag unusual win rates (> 90%)
   - Identify coordinated trophy dropping

**Client-Side Protection:**
- Code obfuscation (Unity IL2CPP)
- Memory encryption for critical values
- Certificate pinning for API requests
- Jailbreak/root detection

**Penalty System:**
| Offense | First | Second | Third |
|---------|-------|--------|-------|
| Suspicious behavior | Warning | 24h ban | 7-day ban |
| Proven exploit | 7-day ban | 30-day ban | Permanent |
| Account sharing | Warning | Reset progress | Permanent |
| Unauthorized purchases | Permanent ban | - | - |

---

## Analytics & Monitoring

### Metrics Collection

**Player Metrics:**
- DAU/MAU (Daily/Monthly Active Users)
- Session length
- Battles per session
- Retention (D1, D7, D30)
- Conversion rate (F2P to paid)

**Game Balance Metrics:**
- Win rate per unit (target: 48-52%)
- Usage rate per unit
- Elixir trade efficiency
- Average match duration
- Trophy progression curves

**Technical Metrics:**
- API response time (p50, p95, p99)
- Error rate
- Crash rate
- Network latency distribution
- Server CPU/Memory usage

**Revenue Metrics:**
- ARPU (Average Revenue Per User)
- ARPPU (Average Revenue Per Paying User)
- LTV (Lifetime Value)
- Conversion funnel analysis
- IAP success rate

### Monitoring Stack

**Application Performance:**
- **Tool:** New Relic / Datadog
- **Alerts:** Response time > 500ms, error rate > 1%

**Infrastructure:**
- **Tool:** Prometheus + Grafana
- **Metrics:** CPU, memory, disk, network
- **Alerts:** CPU > 80%, memory > 90%

**Crash Reporting:**
- **Tool:** Firebase Crashlytics
- **Integration:** Automatic crash logs with stack traces

**Logging:**
- **Tool:** ELK Stack (Elasticsearch, Logstash, Kibana)
- **Centralized logs** from all services
- **Query interface** for debugging

---

## Deployment & DevOps

### CI/CD Pipeline

**Development Workflow:**

```
1. Developer pushes code to Git
   ↓
2. GitHub Actions triggers
   ↓
3. Run automated tests
   ├─ Unit tests
   ├─ Integration tests
   └─ Performance tests
   ↓
4. Build client (Unity Cloud Build)
   ↓
5. Build server (Docker containers)
   ↓
6. Deploy to staging environment
   ↓
7. Run smoke tests
   ↓
8. Manual approval for production
   ↓
9. Blue-green deployment to production
   ↓
10. Monitor metrics for 1 hour
```

**Deployment Strategy:**
- **Blue-Green Deployment:** Zero-downtime releases
- **Canary Releases:** 5% of traffic to new version, monitor, then full rollout
- **Rollback Plan:** One-click revert to previous version

### Infrastructure as Code

**Tool:** Terraform

**Managed Services:**
- AWS ECS (Elastic Container Service) for game servers
- AWS RDS (PostgreSQL managed database)
- AWS ElastiCache (Redis managed cache)
- AWS CloudFront (CDN)
- AWS S3 (object storage)

**Auto-Scaling Configuration:**
```hcl
# Simplified Terraform example
resource "aws_autoscaling_group" "game_servers" {
  min_size = 10
  max_size = 100
  desired_capacity = 20
  
  # Scale up when CPU > 70%
  # Scale down when CPU < 30%
}
```

### Environment Setup

**Environments:**

| Environment | Purpose | URL |
|-------------|---------|-----|
| Local | Developer testing | localhost:3000 |
| Development | Feature testing | dev-api.battlecastles.com |
| Staging | Pre-production | staging-api.battlecastles.com |
| Production | Live game | api.battlecastles.com |

---

## Data Management

### Backup Strategy

**Database Backups:**
- **Frequency:** Full backup daily, incremental every 6 hours
- **Retention:** 7 days immediate, 4 weeks archived, 1 year cold storage
- **Testing:** Monthly restore tests to verify backup integrity

**Disaster Recovery:**
- **RTO (Recovery Time Objective):** 1 hour
- **RPO (Recovery Point Objective):** 6 hours (last incremental backup)
- **Failover:** Automatic to secondary region if primary fails

### GDPR Compliance

**Player Data Rights:**
- **Right to Access:** API endpoint to export all player data (JSON)
- **Right to Deletion:** Remove all personal data within 30 days
- **Right to Portability:** Export data in machine-readable format

**Data Retention:**
- **Active accounts:** Indefinite
- **Inactive accounts (2+ years):** Anonymize after notification
- **Deleted accounts:** Purge personal data, retain anonymized statistics

**Privacy by Design:**
- Minimal data collection
- Encrypted data at rest (AES-256)
- Encrypted data in transit (TLS 1.3)
- No selling of player data

---

## Testing Strategy

### Test Pyramid

```
          /\
         /  \  E2E (5%)
        /────\
       /      \ Integration (15%)
      /────────\
     /          \ Unit (80%)
    /────────────\
```

**Unit Tests:**
- Test individual functions/methods
- Mock external dependencies
- Fast execution (< 1 second per test)
- Target: 80% code coverage

**Integration Tests:**
- Test service interactions
- Use test databases
- Moderate execution time
- Target: Key user flows covered

**End-to-End Tests:**
- Test full user journeys
- Automated UI testing (Appium for mobile)
- Slow execution
- Target: Critical paths (login, battle, purchase)

### Load Testing

**Tool:** Apache JMeter / k6

**Test Scenarios:**

| Scenario | Concurrent Users | Duration | Success Rate |
|----------|------------------|----------|--------------|
| Normal Load | 10,000 | 1 hour | > 99% |
| Peak Load | 50,000 | 30 min | > 95% |
| Stress Test | 100,000 | 15 min | > 90% |
| Spike Test | 0→50,000 in 1min | 5 min | > 90% |

**Performance Benchmarks:**
- Matchmaking: < 30 seconds for 95th percentile
- API response: < 200ms for 95th percentile
- Battle latency: < 100ms for 95th percentile

---

## Launch Checklist

### Pre-Launch (4 weeks before)

- [ ] Load testing at 2x expected capacity
- [ ] Security audit (penetration testing)
- [ ] Legal review (terms of service, privacy policy)
- [ ] Payment system integration tested
- [ ] Customer support system ready
- [ ] Monitoring dashboards configured
- [ ] Incident response plan documented

### Soft Launch (2 weeks before)

- [ ] Release in 2-3 test markets (e.g., Canada, Philippines)
- [ ] Collect player feedback
- [ ] Monitor crash rates and bugs
- [ ] Tune economy based on real player data
- [ ] A/B test monetization strategies

### Global Launch (Day 0)

- [ ] Deploy to all app stores
- [ ] Enable full server capacity
- [ ] Marketing campaign live
- [ ] Community managers monitoring social
- [ ] Dev team on-call for emergencies
- [ ] Player support team staffed 24/7

### Post-Launch (Week 1)

- [ ] Daily KPI reviews
- [ ] Hotfix releases for critical bugs
- [ ] Balance patch if major issues found
- [ ] Community engagement (respond to feedback)
- [ ] Plan first content update

---

## Scalability Plan

### Current Capacity (Launch)

**Servers:**
- 20 game server instances (500 concurrent battles each)
- Total capacity: 10,000 concurrent battles
- Expected load: 5,000 concurrent battles

**Database:**
- PostgreSQL: 1 master, 2 read replicas
- Handles 10,000 transactions/second

**Storage:**
- 1TB allocated for replays and assets
- Auto-scales as needed

### Growth Scaling (6 months post-launch)

**Expected Growth:** 5x players

**Infrastructure Changes:**
- 100 game server instances (auto-scaling)
- 50,000 concurrent battle capacity
- 5 read replicas for database
- Implement database sharding by region

### Cost Estimates

**Monthly Infrastructure Costs:**

| Service | Cost (Launch) | Cost (6 months) |
|---------|---------------|------------------|
| Game Servers (AWS ECS) | $2,000 | $10,000 |
| Database (RDS) | $500 | $2,500 |
| Cache (ElastiCache) | $200 | $800 |
| Storage (S3) | $100 | $500 |
| CDN (CloudFront) | $300 | $1,500 |
| Monitoring | $100 | $300 |
| **Total** | **$3,200/month** | **$15,600/month** |

---

## Future Technical Improvements

### Version 1.1 (3 months post-launch)

- [ ] Voice chat for 2v2 mode
- [ ] Advanced replay analysis with heatmaps
- [ ] Machine learning matchmaking improvements

### Version 1.2 (6 months post-launch)

- [ ] Cross-platform progression (mobile → PC)
- [ ] Clan Wars backend systems
- [ ] Tournament bracket system

### Version 2.0 (12 months post-launch)

- [ ] 3D graphics option (Unity HD Render Pipeline)
- [ ] AR mode support
- [ ] AI opponents with realistic difficulty scaling
- [ ] Dedicated server rental for private matches

---

## Risk Mitigation

### Technical Risks

**Risk 1: Server Overload at Launch**
- **Likelihood:** High
- **Impact:** High
- **Mitigation:** Over-provision servers by 2x, implement queue system, gradual rollout

**Risk 2: Critical Bug in Production**
- **Likelihood:** Medium
- **Impact:** High
- **Mitigation:** Comprehensive testing, feature flags, rapid rollback capability

**Risk 3: DDoS Attack**
- **Likelihood:** Medium
- **Impact:** High
- **Mitigation:** Cloudflare DDoS protection, rate limiting, auto-scaling

**Risk 4: Data Breach**
- **Likelihood:** Low
- **Impact:** Critical
- **Mitigation:** Encryption, regular audits, minimal data collection, incident response plan

---

**Document Ownership:**  
Technical Lead, DevOps Engineer, Security Team

**Review Schedule:**  
Bi-weekly architecture reviews, quarterly security audits

**Version History:**
- v1.0 - Initial technical specifications (October 30, 2025)
