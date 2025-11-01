# Battle Castles - User Manual

Version 0.1.0 | Last Updated: November 1, 2025

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Game Overview](#game-overview)
3. [Core Mechanics](#core-mechanics)
4. [Unit Guide](#unit-guide)
5. [Battle Strategies](#battle-strategies)
6. [Game Modes](#game-modes)
7. [Controls Reference](#controls-reference)
8. [Tips & Tricks](#tips--tricks)
9. [Frequently Asked Questions](#frequently-asked-questions)

---

## Getting Started

### Welcome to Battle Castles!

Battle Castles is a real-time multiplayer strategy game where you deploy medieval fantasy units to destroy your opponent's castle while defending your own. Master the art of timing, placement, and resource management in fast-paced 3-minute battles.

### First Launch

1. **Start the game** - Launch Battle Castles from your applications folder
2. **Main Menu** - You'll see options for:
   - **Play vs AI** - Practice against computer opponents
   - **Multiplayer** - Challenge other players on your local network
   - **Deck Builder** - Customize your unit selection
   - **Settings** - Adjust graphics, audio, and controls

### Quick Start Tutorial

Your first battle will guide you through:
- Deploying your first unit
- Understanding the elixir system
- Attacking enemy towers
- Defending your castle
- Victory conditions

**Tip:** Complete the tutorial to unlock all game modes and earn your first rewards!

---

## Game Overview

### Battle Format

- **Duration:** 3 minutes
- **Players:** 1v1 (Player vs AI or Player vs Player)
- **Objective:** Destroy your opponent's King's Castle OR deal more tower damage when time expires
- **Arena:** Symmetric battlefield divided into two halves (yours and theirs)

### The Battlefield

```
┌─────────────────────────────────────┐
│         OPPONENT'S SIDE             │
│                                     │
│  [Left Tower]  [Castle]  [Right]   │
│         ↓         ↓         ↓       │
│ ═══════════════════════════════════ │  ← River (Center Line)
│         ↑         ↑         ↑       │
│  [Left Tower]  [Castle]  [Right]   │
│                                     │
│          YOUR SIDE                  │
└─────────────────────────────────────┘
```

**Key Areas:**
- **Deployment Zone:** Your half of the battlefield (highlighted)
- **River:** The center dividing line
- **Enemy Territory:** Opponent's half where you cannot deploy units

### Victory Conditions

1. **Instant Victory:** Destroy the opponent's King's Castle (center tower)
2. **Damage Victory:** When time expires, the player who destroyed more towers wins
3. **Tiebreaker:** If tower count is equal, total tower damage dealt determines the winner

---

## Core Mechanics

### The Elixir System

Elixir is your resource for deploying units. Understanding elixir management is key to victory!

**Elixir Basics:**
- **Starting Elixir:** 5
- **Maximum Capacity:** 10 elixir
- **Regeneration Rate:** 1 elixir every 2.8 seconds
- **Double Elixir:** Last 60 seconds of the match - regeneration DOUBLES to 1 per 1.4 seconds

**Strategy Tips:**
- Never stay at max elixir (10) - you're wasting regeneration!
- Save elixir for defensive reactions
- Spend wisely during the first 2 minutes
- Go aggressive during double elixir time

### Deploying Units

**How to Deploy:**
1. Select a unit card from your hand (bottom of screen)
2. Tap/click anywhere in YOUR deployment zone
3. Unit appears after a brief deploy animation (1 second)
4. Elixir is deducted immediately

**Deployment Rules:**
- You can only deploy in your half of the battlefield
- Must have enough elixir for the unit's cost
- Cards cycle from your deck as you use them
- Maximum of 8 units on the field per player

### Unit Behavior

All units follow AI behavior patterns:

1. **Default Movement:** Move toward the nearest enemy building
2. **Combat Engagement:** Attack enemies that come within range
3. **Target Priority:**
   - Ground units: Attack closest enemy unit, then buildings
   - Ranged units: Attack anything in range, prioritize threats
4. **Pathing:** Units automatically navigate around obstacles and allies

### Towers

**Your Towers:**
- **King's Castle (Center):** 3000 HP, 200 damage, 8 range
- **Left Princess Tower:** 1400 HP, 100 damage, 7.5 range
- **Right Princess Tower:** 1400 HP, 100 damage, 7.5 range

**Tower Behavior:**
- Automatically attack nearest enemy unit in range
- Continue attacking buildings if no units present
- Destroyed towers do NOT respawn
- King's Castle only activates after a Princess Tower is destroyed

---

## Unit Guide

### Overview of Launch Units

Battle Castles features 4 core units at launch. Each unit has a specific role and purpose in your strategy.

---

### 1. KNIGHT

**The Reliable Defender**

| Stat | Value |
|------|-------|
| Elixir Cost | 3 |
| Hitpoints | 1400 HP |
| Damage | 75 per hit |
| DPS | 62.5 |
| Speed | Medium (60 units/sec) |
| Range | Melee (0.5 tiles) |
| Targets | Ground only |
| Deploy Time | 1 second |

**Description:**
The Knight is your versatile frontline fighter. Clad in heavy armor, he can absorb significant damage while delivering consistent melee attacks. Perfect for defense and supporting larger pushes.

**Best Uses:**
- Tank for fragile units like Archers
- Counter Goblin Squad rushes
- Distract enemy towers
- Defend against solo enemy units

**Weaknesses:**
- Slow movement speed
- Vulnerable to swarms attacking from multiple angles
- Low damage output compared to cost

**Level Progression:**
- Level 1: 1400 HP, 75 damage
- Level 5: 2049 HP, 109 damage
- Level 9: 3000 HP, 160 damage

---

### 2. GOBLIN SQUAD

**The Fast Rush**

| Stat | Value (per Goblin) |
|------|--------------------|
| Elixir Cost | 2 (for all 3) |
| Hitpoints | 160 HP |
| Damage | 50 per hit |
| DPS | 62.5 |
| Speed | Very Fast (90 units/sec) |
| Range | Melee (0.5 tiles) |
| Targets | Ground only |
| Deploy Time | 1 second |
| Count | 3 goblins |

**Description:**
Deploy 3 small, fast goblins that swarm enemies with rapid attacks. Excellent for overwhelming single targets or rushing undefended towers. Very fragile but deadly in numbers.

**Best Uses:**
- Quick tower damage when opponent is low on elixir
- Destroy wounded enemy units
- Cheap elixir cycling card
- Distraction unit (deploy far from main push)

**Weaknesses:**
- Die quickly to area damage
- Weak against tanks
- Easily distracted by defending units

**Squad DPS:** 187.5 (all 3 goblins combined)

**Tactical Tip:** Split deploy goblins on different lanes to force your opponent to defend multiple threats!

---

### 3. ARCHER PAIR

**The Ranged Support**

| Stat | Value (per Archer) |
|------|--------------------|
| Elixir Cost | 3 (for both) |
| Hitpoints | 250 HP |
| Damage | 60 per hit |
| DPS | 60 |
| Speed | Medium (55 units/sec) |
| Range | Long (5.5 tiles) |
| Targets | Air & Ground |
| Deploy Time | 1 second |
| Count | 2 archers |

**Description:**
Deploy 2 skilled archers that attack from a safe distance. Their long range allows them to support pushes while staying out of melee combat. Fragile but effective.

**Best Uses:**
- Support tanks from behind
- Defend against air units (future-proofed)
- Counter melee units safely
- Apply consistent ranged pressure

**Weaknesses:**
- Very low health - die to strong attacks
- Slow movement makes them vulnerable
- Poor against swarms (single-target only)

**Pair DPS:** 120 (both archers combined)

**Tactical Tip:** Deploy archers behind your King's Castle for maximum defensive range coverage!

---

### 4. GIANT

**The Heavy Tank**

| Stat | Value |
|------|-------|
| Elixir Cost | 5 |
| Hitpoints | 3000 HP |
| Damage | 120 per hit |
| DPS | 75 |
| Speed | Slow (40 units/sec) |
| Range | Melee (0.5 tiles) |
| Targets | Buildings only |
| Deploy Time | 1 second |

**Description:**
The ultimate tank unit. This massive warrior ignores all enemy troops and walks straight toward buildings, soaking up enormous damage. Use him as the centerpiece of major pushes.

**Best Uses:**
- Absorb tower damage while other units attack
- Destroy towers with massive HP pool
- Force opponent to spend elixir on counters
- Create unstoppable pushes when supported

**Weaknesses:**
- Targets buildings ONLY - won't defend himself
- Very slow movement
- High elixir cost (5)
- Vulnerable to swarm units without support

**Special Behavior:** Giant prioritizes the King's Castle if Princess Towers are destroyed!

**Tactical Tip:** Always support your Giant with ranged units behind him. He's a bullet sponge, not a solo win condition!

---

### Unit Comparison Table

| Unit | Cost | HP | DPS | Speed | Role |
|------|------|-----|-----|-------|------|
| Goblin Squad | 2 | 480 | 187.5 | Very Fast | Rush/Cycle |
| Knight | 3 | 1400 | 62.5 | Medium | Tank/Defense |
| Archer Pair | 3 | 500 | 120 | Medium | Support/Range |
| Giant | 5 | 3000 | 75 | Slow | Heavy Tank |

---

## Battle Strategies

### Basic Strategy Concepts

#### Elixir Advantage

**The Golden Rule:** The player with more elixir available usually wins the exchange.

**How to Gain Elixir Advantage:**
1. **Efficient Trades:** Use 3 elixir to counter opponent's 5 elixir push
2. **Don't Overspend:** Minimum necessary defense
3. **Punish Mistakes:** If opponent wastes elixir, immediately counter-push
4. **Never Max Out:** Staying at 10/10 elixir means wasted regeneration

Example Trade:
- Opponent deploys Giant (5 elixir)
- You deploy Goblin Squad (2 elixir) to distract
- You're now +3 elixir advantage = you can counter-attack harder!

#### Lane Pressure

**Dual Lane Attack:**
When you damage one lane, your opponent must defend it. Use this to:
1. Attack one lane with a tank
2. While they defend, rush the opposite lane with fast units
3. Force them to split their elixir inefficiently

**Single Lane Overwhelming:**
Sometimes concentrating all your units in one lane creates an unstoppable force:
1. Deploy Giant in one lane
2. Add Knight behind him
3. Add Archers for ranged support
4. This 11 elixir push can destroy a tower if undefended!

#### Defensive Foundation

**Defense Wins Games:**
- Defending is easier than attacking (your towers help)
- A good defense often creates a counter-push
- Save 3-5 elixir for emergency defense
- Place units BEHIND your tower for maximum support

### Advanced Tactics

#### Unit Placement Matters

**Behind Your Castle:**
- Archers placed here get maximum range while towers protect them
- Allows time for elixir to regenerate before units reach river
- Creates a slow, steady push

**At the River:**
- Aggressive placement for immediate pressure
- Forces opponent to react quickly
- Risky if you don't have elixir for follow-up

**Corner Deployment:**
- Pull enemy units away from your tower
- Useful for kiting melee units
- Buys time for your towers to do damage

#### Counting Elixir

**Track Opponent's Spending:**
- Mental math: "They spent 8 elixir on that push"
- "They must be low on elixir now"
- **Attack when they're elixir-starved!**

**Know Their Cycle:**
- If they used their best counter, it won't be back for 4 more cards
- Window of opportunity = attack now!

#### The Art of the Bait

**Bait and Punish:**
1. Deploy a small threat on one side (e.g., Goblin Squad)
2. Opponent defends with their best splash unit
3. Immediately deploy your real push on the opposite lane
4. They don't have the right counter available!

### Deck Building Strategy

Your deck consists of 8 cards (4 unit types can appear multiple times):

**Balanced Deck Example:**
- 2x Knight (defense/versatility)
- 2x Archer Pair (ranged support)
- 2x Goblin Squad (cheap cycle/rush)
- 2x Giant (win condition)

**Average Elixir Cost:** 3.25 (efficient cycling)

**Aggressive Deck Example:**
- 1x Knight
- 2x Archer Pair
- 3x Goblin Squad
- 2x Giant

**Average Elixir Cost:** 3.0 (fast, aggressive)

---

## Game Modes

### Practice Mode (vs AI)

**Available AI Difficulties:**

1. **Beginner AI**
   - Slow reaction time
   - Predictable patterns
   - Makes tactical errors
   - Perfect for learning basics

2. **Intermediate AI**
   - Faster reactions
   - Better unit composition
   - Counters your moves
   - Good for strategy practice

3. **Expert AI**
   - Near-instant reactions
   - Advanced tactics
   - Efficient elixir management
   - Challenges even experienced players

**How to Play:**
1. Select "Play vs AI" from main menu
2. Choose difficulty level
3. Select your deck
4. Battle begins immediately

**Rewards:**
- Practice mode rewards are reduced
- Focus on learning, not earning
- Experiment with strategies risk-free!

### Multiplayer (LAN)

**Local Network Play:**

Battle Castles supports multiplayer over your local network (LAN), perfect for:
- Playing with friends at home
- LAN parties
- Classroom tournaments
- Offline competitions

**Hosting a Game:**
1. Select "Multiplayer" > "Host Game"
2. Game creates a room code (6 characters)
3. Share code with your opponent
4. Wait for opponent to join
5. Press "Start Battle" when ready

**Joining a Game:**
1. Select "Multiplayer" > "Join Game"
2. Enter the 6-character room code
3. OR select from auto-discovered local games
4. Press "Ready"
5. Wait for host to start

**Network Requirements:**
- All players must be on the same WiFi/LAN network
- Firewall may need to allow Battle Castles
- Recommended latency: <50ms

---

## Controls Reference

### Keyboard & Mouse (PC/Mac/Linux)

**Main Menu:**
- `Mouse Click` - Navigate menus
- `ESC` - Back/Cancel
- `Enter` - Confirm selection

**In Battle:**
- `Left Click` - Select card
- `Left Click (Hold & Drag)` - Preview unit placement
- `Left Click (Release)` - Deploy unit
- `Right Click` - Cancel card selection
- `ESC` - Pause menu
- `Space` - Quick chat (multiplayer)

**Camera:**
- `Scroll Wheel` - Zoom in/out (if enabled in settings)
- `Middle Mouse Hold` - Pan camera (if enabled)

**Debug/Development:**
- `F3` - Toggle FPS counter
- `F11` - Toggle fullscreen
- `` ` `` (backtick) - Open developer console (debug builds only)

### Touch Controls (Future Mobile Support)

**In Battle:**
- `Tap Card` - Select unit
- `Tap Battlefield` - Deploy unit at location
- `Drag Unit` - Preview deployment area
- `Pinch` - Zoom camera
- `Two-finger drag` - Pan camera

### Gamepad Support (Optional)

**Xbox/PlayStation Controller:**
- `D-Pad / Left Stick` - Navigate menus/cards
- `A / X` - Select/Confirm
- `B / Circle` - Back/Cancel
- `Left Trigger` - Zoom out
- `Right Trigger` - Zoom in

---

## Tips & Tricks

### For Beginners

1. **Start with Defense**
   - Always keep 3-5 elixir for defending
   - Let opponent attack first to see their strategy
   - Your towers are powerful - use them!

2. **Don't Rush**
   - Patience wins games
   - Wait for elixir advantage before big pushes
   - The first 2 minutes are about building advantages

3. **Learn Unit Matchups**
   - Goblin Squad destroys Giant (swarm vs tank)
   - Knight counters Goblin Squad (splash vs swarm)
   - Archers counter Knight (range vs melee)
   - Giant needs support to be effective

4. **Watch Your Elixir Bar**
   - Green = good (5-10 elixir)
   - Yellow = caution (3-4 elixir)
   - Red = danger (0-2 elixir)

5. **Placement is Everything**
   - Surround enemy units with your units
   - Place ranged units behind tanks
   - Corner placements can kite enemies

### Intermediate Strategies

6. **The Counter-Push**
   - After defending successfully, your surviving units become attackers
   - Add more units behind them
   - Often more effective than starting from scratch

7. **Cycle Your Deck**
   - Use cheap units (Goblin Squad, Knight) to cycle to your power cards faster
   - If your opponent played their counter, cycle to force them to use it again

8. **Split Lane Pressure**
   - Deploy units on both sides of the arena
   - Forces opponent to split their defense
   - Great when you have elixir advantage

9. **Building Pulls**
   - Place units so enemy units walk into tower range
   - Maximize tower damage while minimizing yours

10. **Save Elixir for Overtime**
    - Double elixir = double the chaos!
    - If winning, save elixir for final 60 seconds
    - If losing, go all-in during double elixir

### Advanced Techniques

11. **Prediction Deployment**
    - Predict where opponent will place units
    - Pre-deploy counters in that spot
    - High risk, high reward

12. **Elixir Counting**
    - Track opponent's elixir mentally
    - Know when they're low vs full
    - Attack when they can't afford defense

13. **Bait Tactics**
    - Force opponent to use their counter
    - Then deploy the unit they counter on opposite lane

14. **The Kamikaze Push**
    - When losing with <30 seconds left
    - Spend ALL elixir on one overwhelming push
    - All-or-nothing strategy

15. **Minimize Overkill**
    - Don't waste units killing a 10 HP tower
    - Redirect to new target
    - Every point of damage counts

### Common Mistakes to Avoid

- **Staying at Max Elixir** - Wasted regeneration
- **Ignoring One Lane** - Opponent will exploit it
- **Overcommitting** - Spending all elixir on one push
- **Panic Deploying** - Placing units without thinking
- **Forgetting Tower Range** - Deploy units too close to enemy towers
- **Not Defending** - Letting opponent free-push
- **Random Placement** - Not considering unit synergies

---

## Frequently Asked Questions

### General Questions

**Q: How long is a match?**
A: Every match lasts exactly 3 minutes. The last 60 seconds have double elixir generation.

**Q: Can I pause the game?**
A: In vs AI mode, yes (press ESC). In multiplayer, battles cannot be paused.

**Q: What happens if I disconnect during multiplayer?**
A: Your opponent wins automatically after 15 seconds of disconnection.

**Q: Is there a ranking system?**
A: Version 0.1.0 is local-only. Future versions will include online ranked play with ELO ratings.

**Q: Can I play on Raspberry Pi 5?**
A: Yes! Battle Castles is optimized for Raspberry Pi 5 (both 4GB and 16GB models).

### Gameplay Questions

**Q: What determines who wins if time runs out?**
A: Player with more towers destroyed. If tied, most tower damage dealt. If still tied, it's a draw.

**Q: Can units attack air targets?**
A: Currently only Archer Pair targets air units. No air units exist in v0.1.0 (planned for future).

**Q: How many units can I have on the field?**
A: Maximum 8 units per player at once.

**Q: Do destroyed towers respawn?**
A: No, destroyed towers are gone for the rest of the match.

**Q: How does the Giant decide which building to attack?**
A: Closest building. If Princess Towers are down, always targets King's Castle.

**Q: Can I customize my deck?**
A: Yes! Use the Deck Builder to create decks with your preferred unit distribution.

**Q: How do unit levels work?**
A: Units have 9 levels. Higher levels = more HP and damage. Currently, all units are level 1 in v0.1.0.

### Technical Questions

**Q: What are the system requirements?**
A:
- **Minimum:** 2GB RAM, Intel i3 or equivalent, Integrated graphics
- **Recommended:** 4GB RAM, Intel i5 or equivalent, Dedicated GPU
- **Raspberry Pi:** Pi 5 with 4GB+ RAM

**Q: What platforms are supported?**
A: PC (Windows/Mac/Linux) and Raspberry Pi 5. Mobile planned for future versions.

**Q: How do I host a LAN game?**
A: All players must be on the same local network. One player hosts, others join using the room code.

**Q: Can I play offline?**
A: Yes! Practice mode vs AI works completely offline.

**Q: How do I adjust graphics settings?**
A: Main Menu > Settings > Graphics. Options include resolution, fullscreen, VSync, and quality preset.

**Q: My game is laggy. Help?**
A:
1. Lower graphics quality in settings
2. Close background applications
3. Update graphics drivers
4. Ensure 60 FPS target in settings

**Q: Where are replays saved?**
A: Replay functionality is planned for v0.2.0 (not in initial release).

### Strategy Questions

**Q: What's the best deck?**
A: It depends on your playstyle! Try:
- Balanced: 2 of each unit (3.25 avg elixir)
- Aggressive: More Goblins and Archers (3.0 avg elixir)
- Defensive: More Knights and Giants (3.5 avg elixir)

**Q: How do I beat Goblin Squad rushes?**
A: Deploy Knight or Archers in the center to take them out. Don't overspend - 3 elixir counters 2 elixir.

**Q: My Giant always dies before reaching the tower. Why?**
A: Giant needs support! Deploy archers behind him or knight in front to tank extra damage.

**Q: Should I attack both lanes or focus one?**
A: Both strategies work:
- **Both lanes:** Splits opponent's defense
- **One lane:** Overwhelming force

**Q: When should I use double elixir mode aggressively?**
A: If you're behind on tower damage, go all-in during the last 60 seconds. If ahead, defend and pressure cautiously.

---

## Need More Help?

### Community Resources

- **Official Website:** [battlecastles.game](https://battlecastles.game) (coming soon)
- **Discord Server:** [discord.gg/battlecastles](https://discord.gg/battlecastles) (coming soon)
- **GitHub Issues:** Report bugs at [github.com/yourusername/battle-castles/issues](https://github.com/yourusername/battle-castles/issues)

### In-Game Help

Press `F1` during gameplay to access context-sensitive help tooltips.

### Report a Bug

Found a bug? Please report it with:
1. What you were doing when the bug occurred
2. What you expected to happen
3. What actually happened
4. Your system specs (OS, hardware)

Email: support@battlecastles.game

---

## Quick Reference Card

**Print this section for easy reference!**

```
┌─────────────────────────────────────────────────┐
│           BATTLE CASTLES QUICK REF              │
├─────────────────────────────────────────────────┤
│ MATCH TIME: 3 minutes                           │
│ DOUBLE ELIXIR: Last 60 seconds                  │
│ ELIXIR REGEN: 1 per 2.8s (1 per 1.4s in double)│
│ MAX ELIXIR: 10                                  │
│ STARTING ELIXIR: 5                              │
├─────────────────────────────────────────────────┤
│ UNITS:                                          │
│ • Goblin Squad: 2 elixir, fast swarm           │
│ • Knight: 3 elixir, reliable tank              │
│ • Archer Pair: 3 elixir, ranged support        │
│ • Giant: 5 elixir, heavy tank                  │
├─────────────────────────────────────────────────┤
│ CONTROLS:                                       │
│ • Left Click: Select & deploy units            │
│ • Right Click: Cancel selection                │
│ • ESC: Pause menu                              │
│ • F3: FPS counter                              │
├─────────────────────────────────────────────────┤
│ TIPS:                                           │
│ ✓ Never stay at max elixir                     │
│ ✓ Defend efficiently (min elixir)              │
│ ✓ Counter-push with surviving units            │
│ ✓ Deploy ranged units behind tanks             │
│ ✓ Track opponent's elixir spending             │
└─────────────────────────────────────────────────┘
```

---

**Version:** 0.1.0
**Last Updated:** November 1, 2025
**Document Status:** Initial Release

**Good luck in the arena, Commander!**
