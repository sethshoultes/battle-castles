# Economy & Progression Systems Document

**Version:** 1.0  
**Date:** October 30, 2025  
**Document Type:** Systems Design

---

## Overview

This document outlines the complete economic systems, progression mechanics, and monetization strategy for Battle Castles. All systems are designed to be fair, rewarding, and sustainable for both F2P and paying players.

---

## Core Economy Principles

### Design Philosophy
1. **Skill Over Money** - Paying accelerates progress but doesn't guarantee wins
2. **Generous F2P Path** - Non-paying players can reach top ranks (takes longer)
3. **No Pay Walls** - Every feature accessible through gameplay
4. **Meaningful Choices** - Multiple ways to progress (cards, levels, strategy)
5. **Respect Player Time** - Daily engagement rewarded, not required

### Economic Health Metrics
- **Conversion Rate:** 5-8% of players make purchases
- **ARPU (Average Revenue Per User):** $1.50-2.50 per month
- **ARPPU (Paying Users):** $20-35 per month
- **F2P Progression:** Reach mid-tier arenas in 2-3 months
- **Paying Progression:** Reach mid-tier arenas in 2-4 weeks

---

## Currency Systems

## Gold (Soft Currency)

### Purpose
Primary currency for card upgrades and shop purchases. Cannot be directly bought with real money.

### Sources

| Source | Gold Amount | Frequency | Daily Potential |
|--------|-------------|-----------|-----------------|
| Battle Victory | 10-30 | Per win | 200-400 (10-15 wins) |
| Chests (Wooden) | 20-40 | 3 hour cycle | 160-320 (4 chests) |
| Chests (Silver) | 50-100 | 3 hour cycle | 200-400 |
| Chests (Golden) | 200-400 | 8 hour cycle | 400-800 (2 chests) |
| Daily Quests | 100-300 | Daily | 200 average |
| Donations | 5 per card | Unlimited | 50-200 (10-40 donations) |
| Achievements | 50-500 | One-time | N/A |
| Season Rewards | 500-5000 | End of season | N/A |

**Daily F2P Earning Potential:** 1,000-2,000 gold  
**Monthly F2P Total:** ~35,000-50,000 gold

### Sinks (How Gold is Spent)

| Sink | Cost | Purpose |
|------|------|---------|
| Card Upgrade (Common 1→2) | 20 | Minimal early gate |
| Card Upgrade (Common 5→6) | 1,000 | Mid-tier progression gate |
| Card Upgrade (Common 8→9) | 8,000 | Late game progression |
| Shop Purchase (Common) | 10 | Accelerate collection |
| Shop Purchase (Rare) | 100 | Target specific cards |
| Shop Purchase (Epic) | 1,000 | Expensive but valuable |

### Balance Rationale
Gold scarcity increases with progression. Early game: Plenty of gold, few cards. Late game: Plenty of cards, need more gold. Creates natural progression curve and monetization opportunity.

---

## Gems (Hard Currency)

### Purpose
Premium currency that accelerates progress. Can be earned slowly through gameplay or purchased with real money.

### Sources (F2P)

| Source | Gem Amount | Frequency | Monthly Potential |
|--------|------------|-----------|-------------------|
| Daily Login Bonus | 5-20 | Daily | 300-450 |
| Achievements | 10-100 | One-time | N/A |
| Free Battle Pass | 50-100 | Weekly | 200-400 |
| Tournament Prizes | 50-500 | Weekly (if win) | 200-2000 |
| Season Chest | 100-300 | Monthly | 100-300 |

**Monthly F2P Total:** 800-1,150 gems

### Purchase Packages

| Package | Gems | Price USD | Bonus | Value/Dollar |
|---------|------|-----------|-------|--------------|
| Pile | 80 | $0.99 | - | 81 gems/$1 |
| Sack | 500 | $4.99 | +20% | 100 gems/$1 |
| Bucket | 1,200 | $9.99 | +25% | 120 gems/$1 |
| Chest | 2,600 | $19.99 | +30% | 130 gems/$1 |
| Vault | 6,500 | $49.99 | +35% | 130 gems/$1 |
| Mountain | 14,000 | $99.99 | +40% | 140 gems/$1 |

**First Purchase Bonus:** Double gems on first purchase (any tier)

### Uses (Sinks)

| Use | Gem Cost | Purpose |
|-----|----------|---------|
| Speed Up Chest (3hr) | 18 | Instant gratification |
| Speed Up Chest (8hr) | 48 | Moderate convenience |
| Speed Up Chest (12hr) | 72 | High convenience |
| Speed Up Chest (24hr) | 144 | Premium convenience |
| Buy Gold (1000) | 60 | Accelerate upgrades |
| Buy Gold (10,000) | 500 | Significant boost |
| Shop Refresh | 10 | Target specific cards |
| Tournament Entry | 100 | Competitive entry fee |
| Battle Pass | 500 (~$4.99) | Season-long value |
| Emote Pack | 250 | Cosmetic |

### Balance Rationale
Gems provide convenience and acceleration, not power. F2P players earn ~1,000 gems monthly, enough for 1-2 chest speed-ups or partial Battle Pass. Pricing follows industry standards with diminishing returns at high tier.

---

## Card Collection System

## Card Rarity Tiers

### Common Cards
- **Units:** Knight, Goblin Squad, Archer Pair, Spearman (future)
- **Drop Rate:** 70% of chest contents
- **Upgrade Cost:** Low (20-8,000 gold across 9 levels)
- **Purpose:** Core deck staples, accessible to all

### Rare Cards
- **Units:** Giant, Elite Knight (future), Wizard (future)
- **Drop Rate:** 25% of chest contents
- **Upgrade Cost:** Medium (100-20,000 gold)
- **Purpose:** Specialized units, moderate progression gate

### Epic Cards
- **Units:** Mini Dragon (future), Valkyrie (future), P.E.K.K.A (future)
- **Drop Rate:** 4.5% of chest contents
- **Upgrade Cost:** High (1,000-100,000 gold)
- **Purpose:** Game-changing units, long-term goals

### Legendary Cards
- **Units:** Hero units (future implementation)
- **Drop Rate:** 0.5% of chest contents
- **Upgrade Cost:** Very High (5,000-200,000 gold)
- **Purpose:** Prestige units, collection targets

## Card Upgrade Progression

### Common Card Upgrade Path

| Level | Cards Needed | Gold Cost | Cumulative Cards | Cumulative Gold |
|-------|--------------|-----------|------------------|-----------------|
| 1 | - | - | 0 | 0 |
| 2 | 2 | 20 | 2 | 20 |
| 3 | 4 | 50 | 6 | 70 |
| 4 | 10 | 150 | 16 | 220 |
| 5 | 20 | 400 | 36 | 620 |
| 6 | 50 | 1,000 | 86 | 1,620 |
| 7 | 100 | 2,000 | 186 | 3,620 |
| 8 | 200 | 4,000 | 386 | 7,620 |
| 9 | 400 | 8,000 | 786 | 15,620 |

**Total to Max:** 786 cards, 15,620 gold per common card

### Rare Card Upgrade Path

| Level | Cards Needed | Gold Cost | Cumulative Cards | Cumulative Gold |
|-------|--------------|-----------|------------------|-----------------|
| 1 | - | - | 0 | 0 |
| 2 | 2 | 50 | 2 | 50 |
| 3 | 4 | 150 | 6 | 200 |
| 4 | 10 | 400 | 16 | 600 |
| 5 | 20 | 1,000 | 36 | 1,600 |
| 6 | 50 | 2,000 | 86 | 3,600 |
| 7 | 100 | 4,000 | 186 | 7,600 |
| 8 | 200 | 8,000 | 386 | 15,600 |
| 9 | 400 | 20,000 | 786 | 35,600 |

**Total to Max:** 786 cards, 35,600 gold per rare card

### Epic Card Upgrade Path

| Level | Cards Needed | Gold Cost | Cumulative Cards | Cumulative Gold |
|-------|--------------|-----------|------------------|-----------------|
| 1 | - | - | 0 | 0 |
| 2 | 2 | 400 | 2 | 400 |
| 3 | 4 | 1,000 | 6 | 1,400 |
| 4 | 10 | 2,000 | 16 | 3,400 |
| 5 | 20 | 4,000 | 36 | 7,400 |
| 6 | 50 | 8,000 | 86 | 15,400 |
| 7 | 100 | 20,000 | 186 | 35,400 |
| 8 | 200 | 50,000 | 386 | 85,400 |
| 9 | 400 | 100,000 | 786 | 185,400 |

**Total to Max:** 786 cards, 185,400 gold per epic card

### Progression Timeline Estimates

**F2P Player:**
- Single Common to max: 4-6 months
- Single Rare to max: 8-12 months
- Single Epic to max: 18-24 months
- Competitive deck (level 7 commons/rares): 3-4 months

**Battle Pass Player ($5/month):**
- Single Common to max: 2-3 months
- Single Rare to max: 5-7 months
- Single Epic to max: 12-15 months
- Competitive deck: 1.5-2 months

**Heavy Spender ($50+/month):**
- Single Common to max: 2-4 weeks
- Single Rare to max: 1-2 months
- Single Epic to max: 3-6 months
- Competitive deck: 2-3 weeks

---

## Chest System

### Chest Types & Contents

#### Wooden Chest (Common)
- **Unlock Time:** 3 hours
- **Gem Skip Cost:** 18 gems
- **Gold:** 20-40
- **Cards:** 10-15
- **Rarity Distribution:** 90% Common, 10% Rare
- **Drop Chance:** 60% of wins

#### Silver Chest (Uncommon)
- **Unlock Time:** 3 hours
- **Gem Skip Cost:** 18 gems
- **Gold:** 50-100
- **Cards:** 20-30
- **Rarity Distribution:** 70% Common, 28% Rare, 2% Epic
- **Drop Chance:** 30% of wins

#### Golden Chest (Rare)
- **Unlock Time:** 8 hours
- **Gem Skip Cost:** 48 gems
- **Gold:** 200-400
- **Cards:** 50-100
- **Guaranteed:** At least 1 Rare
- **Rarity Distribution:** 60% Common, 35% Rare, 5% Epic
- **Drop Chance:** 8% of wins

#### Giant Chest (Epic)
- **Unlock Time:** 12 hours
- **Gem Skip Cost:** 72 gems
- **Gold:** 500-1,000
- **Cards:** 150-250
- **Guaranteed:** At least 5 Rares
- **Rarity Distribution:** 55% Common, 40% Rare, 5% Epic
- **Drop Chance:** Every 50 chests in cycle

#### Magical Chest (Epic)
- **Unlock Time:** 12 hours
- **Gem Skip Cost:** 72 gems
- **Gold:** 400-800
- **Cards:** 40-80
- **Guaranteed:** At least 1 Epic
- **Rarity Distribution:** 40% Common, 50% Rare, 10% Epic
- **Drop Chance:** Every 80 chests in cycle

#### Super Magical Chest (Legendary)
- **Unlock Time:** 24 hours
- **Gem Skip Cost:** 144 gems
- **Gold:** 2,000-4,000
- **Cards:** 200-400
- **Guaranteed:** Multiple Epics, chance of Legendary
- **Rarity Distribution:** 30% Common, 40% Rare, 28% Epic, 2% Legendary
- **Drop Chance:** Every 500 chests in cycle

### Chest Cycle System

**How It Works:**
- Fixed sequence of 240 chests repeats forever
- Position in cycle advances with each battle win
- Cycle is fixed but hidden from players (prevents gaming system)

**Cycle Composition:**
- 180 Wooden Chests
- 52 Silver Chests
- 4 Golden Chests
- 3 Giant Chests
- 1 Magical Chest

**Super Magical:** Separate super cycle every 500 wins

### Chest Queue Rules
- Maximum 4 chests in queue
- Must unlock a chest to earn another
- Chests unlock based on time (can have 4 unlocking simultaneously)
- Victory without queue space = no chest earned (encourages regular play)

### Balance Rationale
Chest timers create natural session breaks and encourage daily return. Gem skip costs designed so F2P gems can rush 1-2 chests per week. Chest cycle guarantees good rewards eventually, preventing extreme bad luck.

---

## Trophy System & Arena Progression

### Trophy Mechanics

**Earning Trophies:**
- **Victory:** +25 to +35 trophies (based on opponent's trophy count)
- **Defeat:** -20 to -30 trophies
- **Draw:** ±0 trophies

**Trophy Scaling:**
- Fight higher trophy opponent: Gain more, lose less
- Fight lower trophy opponent: Gain less, lose more
- System encourages fair matchmaking

### Arena Structure & Rewards

| Arena # | Name | Trophy Range | Unlock | Season Reward |
|---------|------|--------------|--------|---------------|
| 0 | Training Grounds | 0-300 | All units | 500 gold |
| 1 | Wooden Arena | 300-600 | Giant | 1,000 gold |
| 2 | Stone Arena | 600-1,000 | Spearman | 2,000 gold, 50 gems |
| 3 | Iron Arena | 1,000-1,500 | Wizard | 3,000 gold, 100 gems |
| 4 | Bronze Arena | 1,500-2,000 | Mini Dragon | 4,000 gold, 150 gems |
| 5 | Silver Arena | 2,000-2,500 | Valkyrie | 5,000 gold, 200 gems |
| 6 | Gold Arena | 2,500-3,000 | Ballista | 6,000 gold, 250 gems |
| 7 | Crystal Arena | 3,000-3,500 | Healer | 8,000 gold, 300 gems |
| 8 | Champion Arena | 3,500-4,000 | Dark Knight | 10,000 gold, 400 gems |
| 9 | Legendary Arena | 4,000+ | Hero Units | 15,000 gold, 500 gems |

### Season System

**Duration:** 4 weeks (28 days)

**Season Rewards:**
- Distributed based on highest arena reached
- Soft trophy reset (lose 50% of trophies above 4,000)
- Keeps competitive scene fresh
- Gives lower players chance to climb

**Trophy Reset Example:**
- Player at 5,000 trophies
- 1,000 above threshold (5,000 - 4,000)
- Lose 50% of excess: -500
- New season start: 4,500 trophies

---

## Daily & Weekly Systems

### Daily Quests

**Quest Pool (Random 2 per day):**

| Quest | Requirement | Reward |
|-------|-------------|--------|
| Warrior's Path | Win 5 battles | 100 gold, 10 gems |
| Tower Destroyer | Destroy 10 towers | 150 gold |
| Unit Master | Play 30 units | 100 gold |
| Giant Slayer | Defeat 3 Giants | 200 gold |
| Perfect Victory | Win with 3 crowns | 50 gems |
| Generous Soul | Donate 10 cards | 100 gold |
| Arena Champion | Win 3 battles in a row | 200 gold, 20 gems |

**Reroll System:**
- 1 free quest reroll per day
- Additional rerolls cost 10 gems
- Prevents frustrating quest requirements

### Daily Login Rewards

**7-Day Cycle:**
- Day 1: 100 gold
- Day 2: 200 gold
- Day 3: 10 gems
- Day 4: 300 gold
- Day 5: Silver Chest
- Day 6: 20 gems
- Day 7: Golden Chest + 500 gold

**Streak Bonus:**
- 7-day streak complete: +50 gems
- 30-day streak: +200 gems bonus
- Encourages daily engagement without punishment for missing days

### Weekly Chest

**Earned Through Crown Collection:**
- Every destroyed tower/castle = 1 crown
- Chest tiers unlock at crown milestones

| Milestone | Reward |
|-----------|--------|
| 10 Crowns | Wooden Chest |
| 30 Crowns | Silver Chest |
| 60 Crowns | Golden Chest |
| 100 Crowns | Giant Chest |

**Resets:** Every Monday at 00:00 UTC

---

## Shop System

### Daily Shop Rotation

**Refreshes:** Every 24 hours (free) or 10 gems (instant)

**Shop Slots (6 total):**
- 2 Common cards (10 gold each, limit 10)
- 2 Rare cards (100 gold each, limit 3)
- 1 Epic card (1,000 gold each, limit 1)
- 1 Special offer (varies daily)

### Special Offers

**Rotating Deals:**
- 10x Chest Bundle (20% discount)
- Gold packs (bonus gold per gem)
- Card bundles for specific units
- Limited-time cosmetics

**Offer Types:**
- Daily Deal (24 hours)
- Weekly Special (7 days)
- Event Exclusive (duration of event)

---

## Battle Pass System

### Free Track (All Players)

**30 Tiers, Rewards Include:**
- Tier 1-5: Gold (100-500 per tier)
- Tier 10: Silver Chest
- Tier 15: 50 gems
- Tier 20: Golden Chest
- Tier 25: 100 gems
- Tier 30: Giant Chest

**Total Free Value:** ~5,000 gold, 150 gems, 5 chests

### Premium Track ($4.99)

**Same 30 Tiers, Enhanced Rewards:**
- 3x gold rewards
- Exclusive emotes (4 total)
- Tower skin (cosmetic)
- Epic card wild card (choose any epic)
- Legendary chest at tier 30

**Total Premium Value:** ~20,000 gold, 500 gems, 10 chests, cosmetics ($40+ value)

### Battle Pass Progression
- Earn Crown Tokens from battles (1 token per crown)
- 10 Crown Tokens = 1 Battle Pass tier
- Complete all 30 tiers with ~300 crowns
- Achievable with 30-50 battles per week

---

## Clan Systems & Economy

### Clan Donations

**How It Works:**
- Request specific cards (once per 8 hours)
- Clan members donate from their collection
- Donator receives gold reward

**Request Limits:**
- Common: Request 40 cards
- Rare: Request 4 cards
- Epic: Request 1 card

**Donation Rewards:**
- Common: 5 gold, 1 XP per card
- Rare: 50 gold, 10 XP per card
- Epic: 500 gold, 100 XP per card

**Clan Benefits:**
- Social rewards encourage engagement
- Helps players collect specific cards faster
- Gold generation for active clan members

### Clan Chest (Future Feature)

**Community Goal:**
- All clan members contribute crowns
- Unlock progressive reward tiers
- Better rewards for active clans

---

## Player Level System

### Experience (XP) Sources

| Source | XP Gained |
|--------|-----------|
| Card Donation | 1-100 (based on rarity) |
| Card Upgrade | 10-1,000 (based on level) |
| Achievement Complete | 50-500 |

### Level Benefits

**Primary Purpose:** Gate card level cap

| Player Level | Max Card Level | Unlock |
|--------------|----------------|--------|
| 1-3 | 3 | Starting levels |
| 4-5 | 5 | Early progression |
| 6-7 | 7 | Mid-tier competitive |
| 8-9 | 9 | End game content |
| 10+ | 9 | Prestige only |

**Max Player Level:** 50 (mostly for prestige)

---

## Monetization Model

### Revenue Streams

**Primary (70% of revenue):**
1. Chest speed-ups (gems)
2. Shop gold purchases
3. Special offers

**Secondary (25% of revenue):**
1. Battle Pass subscriptions
2. Tournament entries
3. Cosmetic purchases

**Tertiary (5% of revenue):**
1. Direct gem purchases (top-up)
2. Gift system (future)

### Monetization Psychology

**Gentle Nudges:**
- Chest timers create waiting pain point → gems solve it
- Gold scarcity at high levels → gems provide relief
- Battle Pass shows value clearly → one-time decision
- Cosmetics = pure self-expression, no pressure

**Avoided Dark Patterns:**
- ❌ No surprise charges
- ❌ No confusing currency conversion
- ❌ No time-limited "mandatory" purchases
- ❌ No power-locked behind paywall

### Whale Protection

**Spending Limits:**
- Daily shop purchase limits prevent runaway spending
- Card level caps (based on player level) prevent instant max
- Matchmaking considers card levels to avoid stomp matches

---

## Economy Simulation Results

### Player Archetypes

**Dolphin Player ($10-20/month):**
- Buys Battle Pass ($5)
- Occasional chest speed-ups ($10-15)
- Reaches competitive level 30% faster than F2P
- Can compete in mid-high arenas comfortably

**Whale Player ($100+/month):**
- Maxes battle passes immediately
- Buys all special offers
- Speeds up all chests
- Reaches max card levels 3-4x faster
- Still requires skill to win at top ranks

### Economic Balance Testing

**Tests Conducted:**
- 10,000 simulated F2P players over 6 months
- Average trophy progression: 2,500-3,000 (Gold/Crystal Arena)
- Competitive deck achieved in 3-4 months
- Conclusion: F2P viable, monetization provides convenience

**Metrics Monitored:**
- F2P vs Paid win rates (target: 48-52% for both)
- Time to competitive (F2P target: 3-4 months)
- Churn rate after paywall frustration (target: <5%)

---

## Anti-Cheat & Fair Play

### Protection Systems
- Server-authoritative game logic (no client-side hacks)
- Account verification required (phone/email)
- Suspicious spending patterns flagged
- Bot detection algorithms
- Report system for unfair play

### Consequences
- Cheating: Permanent ban
- Exploitation: Trophy reset + temp ban
- Refund abuse: Account restriction

---

## Future Economy Features

### Under Consideration
- **Trade System** - Player-to-player card trading (heavily restricted)
- **Gifting** - Send cosmetics/chests to friends
- **Clan Wars** - Guild-based economy with special currency
- **Seasons Passes** - Themed content drops every season
- **VIP Subscription** - $9.99/month for continuous benefits

---

**Document Ownership:**  
Monetization Team, Economy Designer, Product Manager

**Review Schedule:**  
Monthly economy health check, quarterly deep analysis

**Version History:**
- v1.0 - Initial economy design (October 30, 2025)
