# Unit Specifications Document

**Version:** 1.0  
**Date:** October 30, 2025  
**Document Type:** Technical Specifications

---

## Overview

This document provides complete technical specifications for all combat units in Battle Castles, including stat progressions, AI behavior patterns, and balance rationale.

---

## Unit Design Philosophy

### Core Principles
1. **Clear Roles** - Each unit has a defined purpose (tank, DPS, support, swarm)
2. **Counterplay** - No hard counters, but soft advantages/disadvantages
3. **Elixir Efficiency** - Cost must match power level
4. **Visual Clarity** - Players instantly understand what a unit does

### Balance Framework
- **Cost-to-Value Ratio:** Higher cost = proportionally stronger, not linearly
- **DPS vs HP Balance:** Fragile units deal high DPS, tanks have low DPS
- **Range Advantage:** Ranged units are fragile to balance safety
- **Speed Trade-offs:** Fast units are typically weaker

---

## Unit Database

## 1. KNIGHT (Common)

### Identity
**Role:** Versatile Ground Melee Tank  
**Archetype:** Frontline defender, reliable mid-cost unit  
**Elixir Cost:** 3  
**Rarity:** Common

### Visual Design
- Full plate armor with blue/red team colors
- Medium height (1.8m)
- Sword and shield
- Heroic, dependable appearance

### Base Stats (Level 1)

| Attribute | Value |
|-----------|-------|
| Hitpoints | 1400 HP |
| Damage | 75 per hit |
| Damage Per Second (DPS) | 62.5 |
| Attack Speed | 1.2 seconds |
| Movement Speed | Medium (60 units/sec) |
| Range | Melee (0.5 tiles) |
| Deploy Time | 1 second |
| Target Type | Ground only |
| Count | Single unit |

### Stat Progression Per Level

| Level | HP   | Damage | DPS  |
|-------|------|--------|------|
| 1     | 1400 | 75     | 62.5 |
| 2     | 1540 | 82     | 68.3 |
| 3     | 1694 | 90     | 75.0 |
| 4     | 1863 | 99     | 82.5 |
| 5     | 2049 | 109    | 90.8 |
| 6     | 2254 | 120    | 100  |
| 7     | 2479 | 132    | 110  |
| 8     | 2727 | 145    | 120.8|
| 9     | 3000 | 160    | 133.3|

### Combat Behavior

**AI Pattern:**
1. Moves forward toward nearest enemy building
2. If enemy unit in range, engages in combat
3. Continues to target until unit dies or moves out of range
4. Resumes march to enemy building

**Special Behaviors:**
- Will not retarget to buildings while in combat with troops
- Blocks small units (goblins cannot pass through knight)
- Takes reduced damage from first hit received (5% damage reduction)

### Strategic Use

**Best Against:**
- Goblins (high HP absorbs their attacks)
- Archers (can close distance and eliminate)
- Solo units (trades efficiently)

**Weak Against:**
- Giants (outclassed in HP and damage)
- Swarms from multiple angles
- High DPS ranged units with support

**Synergies:**
- Place behind Giant as secondary tank
- Pair with Archers for balanced push
- Use to distract towers while Goblins rush opposite lane

### Balance Rationale
Knights are the baseline unit for measuring value. 3 elixir cost provides solid stats without being overpowered. Can survive 19 tower shots at level 1, making it a reliable distraction unit.

**Elixir Efficiency:** 467 HP per elixir, 25 damage per elixir

---

## 2. GOBLIN SQUAD (Common)

### Identity
**Role:** Fast Swarm DPS  
**Archetype:** Rush offense, cheap cycle unit  
**Elixir Cost:** 2  
**Rarity:** Common

### Visual Design
- Small (1m height), green skin
- Crude weapons (daggers, clubs)
- Deploy in group of 3
- Chaotic, aggressive appearance

### Base Stats (Level 1) - PER GOBLIN

| Attribute | Value |
|-----------|-------|
| Hitpoints | 160 HP (480 total for squad) |
| Damage | 50 per hit |
| Damage Per Second (DPS) | 62.5 |
| Attack Speed | 0.8 seconds |
| Movement Speed | Very Fast (90 units/sec) |
| Range | Melee (0.5 tiles) |
| Deploy Time | 1 second |
| Target Type | Ground only |
| Count | 3 goblins |

### Stat Progression (Per Goblin)

| Level | HP  | Damage | DPS per Goblin | Squad DPS |
|-------|-----|--------|----------------|-----------|
| 1     | 160 | 50     | 62.5           | 187.5     |
| 2     | 176 | 55     | 68.8           | 206.4     |
| 3     | 194 | 60     | 75.0           | 225       |
| 4     | 213 | 66     | 82.5           | 247.5     |
| 5     | 234 | 73     | 91.3           | 273.9     |
| 6     | 257 | 80     | 100            | 300       |
| 7     | 283 | 88     | 110            | 330       |
| 8     | 311 | 97     | 121.3          | 363.9     |
| 9     | 342 | 107    | 133.8          | 401.4     |

### Combat Behavior

**AI Pattern:**
1. Rush forward at high speed
2. Split slightly to surround targets
3. Attack nearest enemy unit/building
4. Very aggressive, will chase units briefly

**Special Behaviors:**
- Squad spreads out during deployment (triangle formation)
- Each goblin acts independently after spawn
- Can surround single targets for increased damage
- Die easily to splash damage

### Strategic Use

**Best Against:**
- Solo high HP units (Giant - goblins surround and DPS)
- Towers with no defending troops
- Split-pushing opposite lane (forces response)

**Weak Against:**
- Area of Effect damage (towers kill them quickly)
- Archers in groups
- Any splash damage unit

**Synergies:**
- Behind Knight (Knight tanks, goblins deal damage)
- Behind Giant (protected from tower fire)
- Split deployment (1 goblin to distract, 2 on tower)

### Balance Rationale
High risk, high reward unit. Combined DPS is excellent (187.5 at level 1) but fragile. At 2 elixir, provides cheapest cycle option and forces opponent to respond. Squad dies to 2 tower shots per goblin.

**Elixir Efficiency:** 240 HP per elixir, 93.75 DPS per elixir (best DPS:cost ratio)

---

## 3. ARCHER PAIR (Common)

### Identity
**Role:** Ranged Support DPS  
**Archetype:** Backline damage dealer  
**Elixir Cost:** 3  
**Rarity:** Common

### Visual Design
- Medium height (1.6m female, 1.75m male)
- One male, one female archer
- Longbows with quivers
- Light leather armor in team colors

### Base Stats (Level 1) - PER ARCHER

| Attribute | Value |
|-----------|-------|
| Hitpoints | 252 HP (504 total for pair) |
| Damage | 60 per arrow |
| Damage Per Second (DPS) | 54.5 |
| Attack Speed | 1.1 seconds |
| Movement Speed | Medium (60 units/sec) |
| Range | 5.5 tiles |
| Deploy Time | 1 second |
| Target Type | Air & Ground |
| Count | 2 archers |

### Stat Progression (Per Archer)

| Level | HP  | Damage | DPS per Archer | Pair DPS |
|-------|-----|--------|----------------|----------|
| 1     | 252 | 60     | 54.5           | 109      |
| 2     | 277 | 66     | 60.0           | 120      |
| 3     | 305 | 73     | 66.4           | 132.8    |
| 4     | 336 | 80     | 72.7           | 145.4    |
| 5     | 369 | 88     | 80.0           | 160      |
| 6     | 406 | 97     | 88.2           | 176.4    |
| 7     | 447 | 107    | 97.3           | 194.6    |
| 8     | 492 | 118    | 107.3          | 214.6    |
| 9     | 541 | 130    | 118.2          | 236.4    |

### Combat Behavior

**AI Pattern:**
1. Moves forward until enemy in range
2. Stops and begins attacking from range
3. Prioritizes nearest enemy (troops over buildings)
4. Maintains distance, backs away if melee unit approaches

**Special Behaviors:**
- Can attack air units (not implemented yet, future-proofing)
- Retargets quickly (0.2 second retarget delay)
- Will split fire if two targets are equidistant
- Kites backward when melee units charge

### Strategic Use

**Best Against:**
- Low HP swarms (Goblins, other Archers)
- Supporting Giants from behind
- Tower pressure without exposing to melee

**Weak Against:**
- Direct tower fire (dies in 3 shots)
- Knight charges
- Long-range tower targeting

**Synergies:**
- Behind Giant (ultimate tank + DPS combo)
- Behind Knight (protected while dealing damage)
- Split deployment (one per lane for pressure)

### Balance Rationale
Ranged advantage balanced by low HP. At 3 elixir (same as Knight), provides less durability but can attack safely. Perfect support unit that amplifies tank effectiveness. Dies to 3 tower shots per archer.

**Elixir Efficiency:** 168 HP per elixir, 36.3 DPS per elixir

---

## 4. GIANT (Rare)

### Identity
**Role:** Heavy Tank & Building Destroyer  
**Archetype:** Win condition, slow push unit  
**Elixir Cost:** 5  
**Rarity:** Rare

### Visual Design
- Massive (4m height)
- Muscular, primitive appearance
- Carries large wooden club
- Slow, lumbering animation

### Base Stats (Level 1)

| Attribute | Value |
|-----------|-------|
| Hitpoints | 3400 HP |
| Damage | 120 per hit |
| Damage Per Second (DPS) | 50 |
| Attack Speed | 2.4 seconds |
| Movement Speed | Slow (30 units/sec) |
| Range | Melee (1 tile - longer reach) |
| Deploy Time | 1 second |
| Target Type | Buildings ONLY |
| Count | Single unit |

### Stat Progression

| Level | HP   | Damage | DPS  |
|-------|------|--------|------|
| 1     | 3400 | 120    | 50   |
| 2     | 3740 | 132    | 55   |
| 3     | 4114 | 145    | 60.4 |
| 4     | 4525 | 160    | 66.7 |
| 5     | 4978 | 176    | 73.3 |
| 6     | 5476 | 194    | 80.8 |
| 7     | 6023 | 213    | 88.8 |
| 8     | 6625 | 234    | 97.5 |
| 9     | 7288 | 257    | 107.1|

### Combat Behavior

**AI Pattern:**
1. Ignores ALL enemy troops
2. Walks directly to nearest building
3. Attacks building until destroyed
4. Moves to next nearest building

**Special Behaviors:**
- NEVER attacks troops (even if blocking path)
- Takes 35% reduced damage from buildings
- Pushes through small units (they bounce off)
- Slow but unstoppable if undefended

### Strategic Use

**Best Against:**
- Towers and castles (primary purpose)
- Absorbing massive damage
- Creating pressure that MUST be answered

**Weak Against:**
- Swarm units (Goblins, Archers)
- High DPS troops
- Being ignored (reaches tower but dies before destroying it)

**Synergies:**
- Archers behind (classic tank + support)
- Knight behind (dual tank push)
- Goblin protection (kill defending troops)

### Balance Rationale
Win condition unit at 5 elixir. Massive HP pool forces response, but slow speed and building-only targeting allows counterplay. Can tank 50+ tower shots. Opponent must spend 4-6 elixir to counter effectively, but Giant alone won't destroy a tower.

**Elixir Efficiency:** 680 HP per elixir, only 10 DPS per elixir (terrible offensive efficiency, but tanking value is high)

**Tower Interaction:**
- Survives 51 tower shots at level 1
- Deals 600 damage to tower if uncontested (needs 8 hits)
- Typical supported push destroys tower

---

## Unit Interaction Matrix

### Combat Matchups (1v1, Equal Levels)

|           | Knight | Goblin Squad | Archer Pair | Giant |
|-----------|--------|--------------|-------------|-------|
| **Knight** | Draw (50/50) | Knight wins | Knight wins | Giant wins |
| **Goblin Squad** | Goblins lose | Draw | Goblins win | Goblins win (if no tower) |
| **Archer Pair** | Archers lose | Archers win | Draw | Archers win (over time) |
| **Giant** | Giant wins | Giant loses | Giant loses | N/A (both target buildings) |

### Elixir Trade Efficiency

**Positive Trades (Good for you):**
- Use 2 elixir Goblins to kill 5 elixir Giant (+3 elixir advantage)
- Use 3 elixir Archers to kill 2 elixir Goblins (+1 advantage, but risky)
- Use 3 elixir Knight to tank for your 5 elixir Giant

**Negative Trades (Bad for you):**
- Use 5 elixir Giant against 2 elixir Goblins (-3 disadvantage, Giant dies)
- Use 3 elixir Knight alone against defended tower
- Deploy units without purpose (elixir wasted)

---

## Unit Unlock Progression

### Arena Unlock Schedule

| Arena | Arena Name | New Unit Unlocked |
|-------|------------|-------------------|
| 0 | Training Grounds | Knight, Goblin Squad, Archer Pair |
| 1 | Wooden Arena | Giant |
| 2 | Stone Arena | Spearman (future) |
| 3 | Iron Arena | Wizard (future) |
| 4 | Bronze Arena | Mini Dragon (future) |
| 5 | Silver Arena | Valkyrie (future) |
| 6 | Gold Arena | Ballista (future) |
| 7 | Crystal Arena | Healer (future) |
| 8 | Champion Arena | Dark Knight (future) |
| 9 | Legendary Arena | Hero Units (future) |

---

## Balance Tuning Guidelines

### When to Nerf a Unit
- Win rate with unit in deck > 60% across all trophy ranges
- Usage rate > 80% (appears in most decks)
- Single counter costs significantly more elixir than unit
- Dominates tournament meta for 3+ weeks

### When to Buff a Unit
- Win rate with unit in deck < 35%
- Usage rate < 5% (never used)
- Hard countered by multiple cheap units
- Outclassed by similar cost alternatives

### Balance Change Process
1. **Data Collection** - 2 weeks of match data post-change
2. **Analysis** - Compare win rates, usage, trophy distribution
3. **Adjustment** - 5-10% stat changes maximum per patch
4. **Iteration** - Rebalance after another 2 weeks if needed

### Historical Balance Changes (Example Format)

**Patch 1.1 - Example**
- **Knight:** HP 1400 → 1260 (10% decrease) - *Too tanky for 3 elixir*
- **Goblins:** Count 4 → 3 - *Too much value for 2 elixir*
- **Giant:** Cost 6 → 5 elixir - *Underused, needed cost reduction*

---

## Future Unit Concepts

### In Development

**Spearman** (3 elixir, Common)
- Role: Long melee range anti-Knight
- 2 unit deploy
- Counters melee, weak to ranged

**Wizard** (5 elixir, Rare)
- Role: Area damage dealer
- Targets ground only
- Splash damage destroys swarms

**Mini Dragon** (4 elixir, Epic)
- Role: Flying unit
- Low HP, ranged attack
- Weak to archers, strong vs ground melee

### Future Expansion Ideas
- Hero units with active abilities
- Building cards (spawn structures)
- Spell cards (instant effects)
- Legendary units with unique mechanics

---

## Testing & QA Requirements

### Unit Testing Checklist
- [ ] Movement speed matches specification
- [ ] Attack range correct in all scenarios
- [ ] AI targeting priority functions properly
- [ ] HP/Damage values match level progression
- [ ] Visual effects sync with damage timing
- [ ] Audio cues play correctly
- [ ] Collision detection works with all units
- [ ] Pathfinding navigates around obstacles

### Balance Testing
- [ ] 100+ matches per unit across skill levels
- [ ] Win rate within 45-55% range
- [ ] Cost-to-value ratio comparable to baseline (Knight)
- [ ] Counterplay options exist at all elixir costs
- [ ] Fun factor rated 7+ by playtesters

---

## Technical Implementation Notes

### Unit State Machine

**States:**
1. SPAWNING - Deployment animation (1 second)
2. MOVING - Pathfinding toward target
3. ATTACKING - In combat with target
4. DYING - Death animation (0.5 seconds)

### Network Sync Requirements
- Position sync: Every 0.1 seconds
- Attack event: Immediate broadcast
- HP updates: On damage taken
- Death event: Immediate broadcast

### Performance Optimization
- Max 40 units on battlefield simultaneously
- LOD system for distant units
- Particle effects reduced on low-end devices
- Animation frame skipping under 30 FPS

---

**Document Ownership:**  
Lead Game Designer, Balance Team

**Review Schedule:**  
Bi-weekly balance review meetings, major updates quarterly

**Version History:**
- v1.0 - Initial unit specifications (October 30, 2025)
