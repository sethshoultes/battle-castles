# Battle Castles - Game Design Document

**Version:** 1.0  
**Date:** October 30, 2025  
**Document Type:** Core Game Design Document

---

## Executive Summary

Battle Castles is a real-time multiplayer strategy battle game where players deploy medieval fantasy units to destroy their opponent's castle while defending their own. Inspired by Clash Royale, the game combines fast-paced tactical decision-making with deck building and unit management.

---

## Game Overview

### Core Concept
Players face off in 1v1 battles on a vertical battlefield, deploying units (Knights, Goblins, Archers, Giants) that automatically march and attack enemy structures. Strategic elixir management, unit placement, and counter-play determine victory.

### Target Platform
- Primary: Mobile (iOS/Android)
- Secondary: PC (Steam)
- Cross-platform multiplayer support

### Target Audience
- Primary: Ages 13-35
- Casual to mid-core strategy gamers
- Fans of real-time tactical games
- Players who enjoy competitive multiplayer with quick match times

### Unique Selling Points
1. **3-Minute Battles** - Quick, intense matches perfect for mobile
2. **Strategic Depth** - Simple to learn, difficult to master
3. **Fair Progression** - Skill-based matchmaking with balanced monetization
4. **Medieval Fantasy Theme** - Knights, castles, and mythical creatures

---

## Core Gameplay Loop

### Match Flow
1. **Matchmaking** (10-30 seconds) - Players matched by trophy count
2. **Deck Selection** (5 seconds) - Choose pre-built deck
3. **Battle Start** (3 minutes) - Deploy units and destroy towers
4. **Victory/Defeat** - Gain/lose trophies and rewards
5. **Progression** - Unlock cards, upgrade units, advance arenas

### Session Loop
Players engage in multiple 3-5 minute sessions throughout the day:
- Play 2-5 battles per session
- Open earned chests
- Upgrade cards with collected resources
- Adjust deck strategy

---

## Game Modes

### Primary Modes

#### 1v1 Ranked Battle (Core Mode)
- 3-minute timed matches
- Trophy-based matchmaking
- Win = +30 trophies, Loss = -25 trophies
- Climb through 10 arenas
- Season resets every 4 weeks

#### Tournament Mode
- 8-16 player single elimination
- Entry fee: gold or gems
- Prize pool distributed to top 3
- Special tournament rules (double elixir, draft mode)

#### Practice Mode
- Battle against AI
- No trophy loss/gain
- Test new decks
- Perfect for learning

### Secondary Modes (Future Content)

#### 2v2 Cooperative
- Team with a friend
- Shared elixir pool
- Communication emotes
- Separate 2v2 ranking

#### Special Challenges
- Weekend events with unique rules
- Draft mode (pick from rotating units)
- Mirror mode (both players have same deck)
- Triple elixir chaos mode

---

## Core Mechanics

### Elixir System
**Function:** Resource management mechanic that controls unit deployment pace

- **Starting Elixir:** 5 units
- **Maximum Capacity:** 10 units
- **Regeneration Rate:** 1 elixir per 2.8 seconds (standard)
- **Double Elixir:** Last 60 seconds of match = 2x generation rate
- **Strategic Importance:** Forces players to make efficient trades

### Unit Deployment
**Function:** Spatial strategy and timing

- **Deployment Zones:** Your half of the battlefield only
- **Deployment Range:** Anywhere behind the river/center line
- **Instant Spawn:** Units appear immediately when placed
- **No Cancel:** Once placed, elixir is spent
- **Queue System:** Can queue next unit before having full elixir

### Tower Targeting AI
**Function:** Automated defense that players must strategize around

**Priority System:**
1. Nearest enemy troop within range
2. If no troops, targets nearest building (enemy towers only)
3. Switches targets if closer unit enters range

**Tower Stats:**
- Detection Range: 7 tiles
- Attack Speed: 0.8 seconds
- Damage Type: Single target projectile

### King's Castle Activation
**Special Mechanic:** Defensive power spike

- Castle does NOT attack until a supporting tower is destroyed
- Once activated, provides additional defensive firepower
- Attacks independently from towers
- Creates strategic decision: rush one tower or spread damage?

---

## Victory Conditions

### Standard Victory
**Destroy the enemy King's Castle** - Main objective, instant win regardless of time remaining

### Tower Advantage Victory
**Most tower damage when timer expires:**
- Destroyed Castle = 1 Crown
- Destroyed Tower = 1 Crown each
- Most crowns wins
- Tie = Draw (both gain reduced rewards)

### Three Crown Victory
**Destroy Castle + Both Towers:**
- Bonus trophy gain (+5)
- Better chest rewards
- Prestigious achievement

### Overtime
**If tied when timer expires:**
- 1 minute sudden death
- Next tower/castle destroyed wins immediately
- If still tied, match is a draw

---

## Progression Systems

### Trophy System
**Function:** Skill rating and arena advancement

**Arena Structure:**
1. Training Grounds (0-300 trophies)
2. Wooden Arena (300-600)
3. Stone Arena (600-1000)
4. Iron Arena (1000-1500)
5. Bronze Arena (1500-2000)
6. Silver Arena (2000-2500)
7. Gold Arena (2500-3000)
8. Crystal Arena (3000-3500)
9. Champion Arena (3500-4000)
10. Legendary Arena (4000+)

**Trophy Gain/Loss:**
- Win: +25 to +35 (based on opponent trophies)
- Loss: -20 to -30
- Draw: ±0

### Card Collection System
**Function:** Unlock and upgrade units

**Card Rarity Tiers:**
- **Common** (Grey) - Knights, Goblins, Archers
- **Rare** (Orange) - Giants, Elite Knights
- **Epic** (Purple) - Dragons, Wizards (future units)
- **Legendary** (Gold) - Hero units (future content)

**Upgrade Requirements:**
| Level | Common Cards | Gold Cost |
|-------|--------------|-----------|
| 1→2   | 2            | 20        |
| 2→3   | 4            | 50        |
| 3→4   | 10           | 150       |
| 4→5   | 20           | 400       |
| 5→6   | 50           | 1000      |
| 6→7   | 100          | 2000      |
| 7→8   | 200          | 4000      |
| 8→9   | 400          | 8000      |

### Player Level System
**Function:** Long-term progression separate from trophies

- Gain XP from donations, upgrades, and battles
- Higher level = Can upgrade cards further
- Unlock new arenas at trophy milestones, not player level
- Max level: 50

### Chest System
**Function:** Reward delivery mechanism

**Chest Types:**
1. **Wooden Chest** (Common) - 3 hour unlock, 10-15 cards
2. **Silver Chest** (Uncommon) - 3 hour unlock, 15-25 cards  
3. **Golden Chest** (Rare) - 8 hour unlock, 50-100 cards, guaranteed rare
4. **Giant Chest** (Epic) - 12 hour unlock, 100-200 cards
5. **Magical Chest** (Epic) - 12 hour unlock, guaranteed epic card
6. **Super Magical** (Legendary) - 24 hour unlock, multiple epics/legendary

**Chest Cycle:**
- Fixed rotation of 240 chests
- 1 guaranteed Magical and Giant per cycle
- Win battles to earn next chest in cycle
- Max 4 chests in queue, must unlock to progress

---

## Monetization Strategy

### Currency System

#### Gold (Soft Currency)
- Earned through: Battles, chests, donations
- Used for: Card upgrades, buying cards from shop
- No direct purchase (earned through gameplay)

#### Gems (Hard Currency)
- Earned through: Achievements, free daily rewards (small amounts)
- Purchased with: Real money ($4.99 = 500 gems)
- Used for: Speed up chests, buy gold, special offers

### Monetization Points

**Non-Intrusive:**
1. **Battle Pass** ($4.99/month)
   - Bonus rewards for playing
   - Exclusive emotes and tower skins
   - Does NOT grant power advantage
   
2. **Chest Speed-Up** (Optional)
   - Pay gems to unlock chests instantly
   - OR wait for timer (never forced)

3. **Cosmetics**
   - Tower skins
   - Unit skins
   - Battle emotes
   - Victory animations

**Fair Play Focus:**
- No "pay to win" units
- Matchmaking based on trophy AND card levels
- Can reach top ranks as F2P (takes longer)
- Spending reduces grind time, not skill cap

---

## Social Features

### Clan System
- Join/create clans (50 members max)
- Clan chat
- Request/donate cards (gain gold for donations)
- Clan wars (future feature)
- Leaderboards (personal, clan, global)

### Friend System
- Add friends via friend code
- Friendly battles (no trophy impact)
- Spectate friend battles
- Challenge friends

### Communication
- Pre-set emotes only (prevent toxicity)
- 6 emote slots
- Unlock emotes through progression
- No text chat in 1v1 (prevents harassment)

---

## Technical Requirements

### Performance Targets
- **Frame Rate:** 60 FPS minimum on mid-range devices
- **Match Start Time:** < 30 seconds from queue to battle
- **Network:** < 100ms latency for optimal experience
- **Battery Usage:** < 5% per 10 minute session

### Server Architecture
- **Authoritative Server:** All game logic on server (prevent cheating)
- **Client Prediction:** Smooth unit movement despite latency
- **Replay System:** Store match data for replays and analysis

---

## Success Metrics

### Key Performance Indicators (KPIs)

**Engagement:**
- Daily Active Users (DAU)
- Average session length: Target 15-20 minutes
- Battles per day: Target 8-12
- Day 1/7/30 retention rates

**Monetization:**
- Average Revenue Per User (ARPU)
- Conversion rate to paying user: Target 5-8%
- Battle Pass attach rate: Target 15%

**Health:**
- Match balance: Win rates between 48-52% per unit
- Match completion rate: Target >95%
- Matchmaking time: Target <30 seconds

---

## Risk Assessment

### Technical Risks
- **Server load during launch** - Mitigation: Stress testing, scalable infrastructure
- **Cheating/Hacking** - Mitigation: Server-authoritative, anti-cheat systems
- **Connection quality** - Mitigation: Reconnect feature, lag compensation

### Design Risks
- **Unit balance issues** - Mitigation: Frequent balance patches, data-driven adjustments
- **Stale meta** - Mitigation: Regular new unit releases, seasonal balance changes
- **Progression too slow** - Mitigation: Playtesting, adjustable reward rates

### Business Risks
- **Low retention** - Mitigation: Compelling daily rewards, social features
- **Pay-to-win perception** - Mitigation: Skill-based matchmaking, fair monetization
- **Market saturation** - Mitigation: Unique IP, superior polish and balance

---

## Development Roadmap

### Phase 1: Core Development (6 months)
- Basic unit types (4 units)
- Core gameplay loop
- 1v1 ranked mode
- Basic progression system

### Phase 2: Beta Testing (2 months)
- Soft launch in select regions
- Balance adjustments
- Bug fixes and polish

### Phase 3: Global Launch (Month 9)
- 10 arenas
- 8 unit types
- Clan system
- Social features

### Phase 4: Live Ops (Ongoing)
- Monthly new unit releases
- Seasonal events
- Balance patches every 2 weeks
- Clan Wars feature (Month 12)
- 2v2 mode (Month 15)

---

## Appendix

### Competitive Scene Vision
- Official tournaments with prize pools
- Esports-ready spectator mode
- Ranked seasons with exclusive rewards
- Partner with content creators

### Accessibility Features
- Colorblind modes
- Adjustable UI scaling
- Sound effect alternatives
- One-handed play support

### Localization Strategy
- Launch languages: English, Spanish, Portuguese, French, German, Japanese, Korean, Chinese
- Full text localization
- Voice-over for tutorial only
- Region-specific events

---

**Document Version Control:**
- v1.0 - Initial draft (October 30, 2025)
- Next review: November 15, 2025
