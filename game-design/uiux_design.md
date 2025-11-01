# UI/UX Design Document

**Version:** 1.0  
**Date:** October 30, 2025  
**Document Type:** Interface Design Specifications

---

## Overview

This document defines the user interface, user experience, and interaction design for Battle Castles. The goal is to create an intuitive, responsive, and visually appealing interface that works seamlessly on mobile and PC platforms.

---

## Design Principles

### Core UX Pillars

1. **Immediate Clarity** - Players understand what to do within 3 seconds
2. **Responsive Feedback** - Every action has immediate visual/audio response
3. **Minimal Friction** - Remove unnecessary steps between intent and action
4. **Progressive Disclosure** - Show complexity gradually as players advance
5. **Consistent Language** - Same terms, icons, and patterns throughout

### Mobile-First Philosophy
- Touch targets minimum 44x44 pixels
- Critical actions thumb-reachable (bottom third of screen)
- Minimize text input
- Single-hand operation where possible
- Fast loading (< 3 seconds to gameplay)

### Accessibility Standards
- Color blind friendly (never use color alone to convey info)
- Text minimum 16pt
- High contrast options
- Audio cues for visual feedback
- Haptic feedback support

---

## Screen Architecture

### Main Menu Hub (Home Screen)

**Layout Structure:**

```
┌─────────────────────────────┐
│  [Player Info]    [Settings]│
│  Avatar | Name | Level       │
│  Trophy: 2450  [Trophy Icon] │
├─────────────────────────────┤
│                             │
│    [BATTLE Button]          │ ← Primary CTA
│    Large, Pulsing           │
│                             │
├─────────────────────────────┤
│ [Deck] [Shop] [Clan] [Cards]│ ← Navigation
├─────────────────────────────┤
│  Active Chests (Carousel)   │
│  [Chest 1] [Chest 2] [...]  │
│  3h:24m    Unlocking        │
├─────────────────────────────┤
│  Daily Quest Banner         │
│  "Win 5 Battles" [Progress] │
├─────────────────────────────┤
│  [News]  [Events]  [Social] │
└─────────────────────────────┘
```

**Key Elements:**

**1. Player Info Bar (Top)**
- Avatar (circular, 60x60px)
- Name (truncated if > 12 characters)
- Level (badge overlay on avatar)
- Trophy count (large, prominent number)
- Gem count (top-right corner)
- Gold count (top-right corner, below gems)

**2. Battle Button (Center)**
- Size: 200x80px on mobile, 300x100px on PC
- Color: Bright orange/red with glow effect
- Animation: Pulse every 2 seconds
- Text: "BATTLE" in bold, white text
- Single tap to queue for match

**3. Bottom Navigation Bar**
- 4-5 icons with labels
- Active tab highlighted with color
- Badges show notifications (red dot)

**4. Chest Carousel**
- Horizontal scrollable
- Shows chest artwork + unlock timer
- Tap to view details or speed up
- Empty slots show "+Win battles to earn"

**5. Quest Banner**
- Shows current daily quest
- Progress bar (visual, percentage)
- Tap to expand full quest list

### Battle Screen

**Pre-Battle (Matchmaking Phase)**

```
┌─────────────────────────────┐
│        FINDING OPPONENT...  │
│                             │
│    [Loading Animation]      │
│                             │
│    [Your Avatar] vs [?]     │
│                             │
│    [Cancel] (10 sec timer)  │
└─────────────────────────────┘
```

**In-Battle Layout**

```
┌─────────────────────────────┐
│ 3:00  [You] 1 ↔ 0 [Enemy]  │ ← Timer & Crowns
├─────────────────────────────┤
│                             │
│     Enemy Towers            │
│     │ Tower │ │ Tower │     │
│        Castle               │
│─────────────────────────────│
│     BATTLEFIELD             │
│     [Units moving]          │
│─────────────────────────────│
│        Your Castle          │
│     │ Tower │ │ Tower │     │
│                             │
├─────────────────────────────┤
│  Elixir: ████████░░ (8/10) │ ← Resource bar
├─────────────────────────────┤
│ [Knight] [Goblin] [Archer]  │ ← Card hand
│    3      2         3       │
│ [Giant] [Next Card]         │
│    5      [?]               │
└─────────────────────────────┘
```

**Battle UI Elements:**

**1. Top HUD**
- Match timer (center, large font)
- Crown count (yours vs opponent)
- Player names/avatars (small)
- Emote button (top-left corner)
- Options/pause (top-right corner)

**2. Battlefield (Main View)**
- Vertical orientation (portrait mode)
- Enemy side (top 40% of screen)
- Your side (bottom 40% of screen)
- Middle river/divider (center 20%)
- Background shows arena theme
- Grid overlay (subtle, visible during unit placement)

**3. Elixir Bar**
- Horizontal bar above card hand
- Purple/pink color fills left-to-right
- Number display "8/10"
- Pulsing glow when full

**4. Card Hand (Bottom)**
- 4 cards visible at once
- 5th card queued (partially visible, right side)
- Each card shows:
  - Unit illustration
  - Elixir cost (corner badge)
  - Level (small number)
- Cards disabled (greyed) if insufficient elixir
- Drag-and-drop to deploy
- Alternate: Tap card, tap battlefield position

**5. Deployment Zone Indicator**
- Your half of battlefield highlights blue when card selected
- Invalid zones (enemy side) show red X
- Placement shadow appears where you're dragging

**6. Unit Status Indicators**
- HP bar above each unit (green → yellow → red)
- Elixir cost floats up when unit deployed
- Death animation + particle effects
- Targeting indicators (red line to target)

### Victory/Defeat Screen

```
┌─────────────────────────────┐
│                             │
│        VICTORY!             │ ← Animated
│    ★ ★ ★ (3 Crowns)         │
│                             │
│    +30 Trophies 🏆          │
│    +120 Gold 🪙             │
│                             │
│    Chest Earned:            │
│    [Golden Chest]           │
│    8:00:00 to unlock        │
│                             │
│  [Battle Again] [Home]      │
│                             │
│  [Share] [Replay] [Stats]   │
└─────────────────────────────┘
```

**Post-Match Elements:**

**Victory:**
- Large "VICTORY!" text with gold/yellow colors
- Crown animation (stars appear)
- Trophy gain/loss displayed prominently
- Rewards (gold, chest) shown with icons
- Progression bar for next arena (if applicable)

**Defeat:**
- "DEFEAT" text in darker colors
- No crown animation
- Trophy loss in red
- Encouragement message: "Try a different deck!"
- Quick rematch button

**Common Elements:**
- Battle statistics (damage dealt, units deployed, etc.)
- Replay button (watch match again)
- Share replay (social features)
- Return to main menu
- Battle again (quick rematch)

---

## Secondary Screens

### Card Collection Screen

**Layout:**

```
┌─────────────────────────────┐
│  [Filter: All▾] [Search 🔍] │
├─────────────────────────────┤
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐│
│  │Card│ │Card│ │Card│ │Card││ ← Grid
│  │Lvl8│ │Lvl5│ │Lvl3│ │Lvl1││
│  │150/│ │50/ │ │10/ │ │0/  ││ ← Progress
│  │200 │ │100 │ │20  │ │2   ││
│  └────┘ └────┘ └────┘ └────┘│
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐│
│  │    │ │    │ │    │ │Lock││ ← Locked
│  └────┘ └────┘ └────┘ └────┘│
├─────────────────────────────┤
│  [Sort: Level▾] [Rarity▾]   │
└─────────────────────────────┘
```

**Card Detail View (Tap a card):**

```
┌─────────────────────────────┐
│         [Card Art]          │ ← Large image
│                             │
│   Knight                    │
│   Level 8 → 9               │
│                             │
│   HP: 2727 → 3000 (+273)   │
│   Damage: 145 → 160 (+15)  │
│   DPS: 120.8 → 133.3       │
│                             │
│   Upgrade Cost:             │
│   200 Cards | 4,000 Gold   │
│                             │
│   [150/200] ████████░░      │ ← Progress
│                             │
│   [UPGRADE] (if available)  │
│   [INFO] [REQUEST] (clan)   │
└─────────────────────────────┘
```

### Deck Builder Screen

```
┌─────────────────────────────┐
│  Deck Name: "Main Deck"     │
│  Average Elixir: 3.5        │
├─────────────────────────────┤
│  Selected Cards (8 slots):  │
│  ┌────┐┌────┐┌────┐┌────┐  │
│  │Kngt││Gobl││Arch││Gnt │  │
│  │ 3  ││ 2  ││ 3  ││ 5  │  │
│  └────┘└────┘└────┘└────┘  │
│  ┌────┐┌────┐┌────┐┌────┐  │
│  │ +  ││ +  ││ +  ││ +  │  │ ← Empty slots
│  └────┘└────┘└────┘└────┘  │
├─────────────────────────────┤
│  All Cards (scrollable):    │
│  ┌────┐┌────┐┌────┐┌────┐  │
│  │Card││Card││Card││Card│  │
│  └────┘└────┘└────┘└────┘  │
├─────────────────────────────┤
│  [Copy Deck] [Reset] [Save] │
└─────────────────────────────┘
```

**Deck Builder Features:**
- Drag-drop or tap to add cards
- Visual elixir average indicator
- Warning if deck incomplete
- Multiple deck slots (3 decks)
- Quick swap between decks
- Copy decks from friends/pros

### Shop Screen

```
┌─────────────────────────────┐
│  [Daily] [Offers] [Chests]  │ ← Tabs
├─────────────────────────────┤
│  DAILY DEALS (Refresh 12h)  │
│                             │
│  Knight x10      Rare x3    │
│  [   100g   ]   [ 300g  ]  │
│                             │
│  Epic x1         Chest Pack │
│  [ 1,000g  ]    [ 500💎 ]  │
│                             │
│  [Refresh Shop] (10 gems)   │
├─────────────────────────────┤
│  SPECIAL OFFER!             │
│  🔥 LIMITED TIME 🔥          │
│  [Legendary Chest Pack]     │
│  50% OFF - $19.99 $9.99    │
└─────────────────────────────┘
```

### Clan Screen

```
┌─────────────────────────────┐
│  [Clan Badge] Clan Name     │
│  #ABC123 | 45/50 Members    │
│  Trophy Requirement: 2000   │
├─────────────────────────────┤
│  [Info] [Members] [Chat]    │
├─────────────────────────────┤
│  Member List:               │
│  ┌──────────────────────┐   │
│  │ [Avatar] PlayerName  │   │
│  │ Leader | 4500 🏆     │   │
│  │ Last seen: 2h ago    │   │
│  └──────────────────────┘   │
│  ┌──────────────────────┐   │
│  │ [Avatar] Player2     │   │
│  │ Co-Leader | 3200 🏆  │   │
│  └──────────────────────┘   │
├─────────────────────────────┤
│  [Donate] [Request Cards]   │
└─────────────────────────────┘
```

---

## Interaction Patterns

### Card Deployment Mechanic

**Method 1: Drag & Drop (Primary)**
1. Player touches card in hand
2. Card follows finger with visual feedback
3. Battlefield shows valid placement zone (blue highlight)
4. Drop finger to deploy
5. Unit spawns with animation
6. Elixir cost deducted visually

**Method 2: Tap & Place (Alternate)**
1. Tap card to select
2. Card highlights/lifts
3. Tap battlefield position
4. Unit deploys
5. Useful for precise placement

**Feedback Elements:**
- Haptic vibration on card pickup
- Audio "whoosh" when dragging
- Visual trail behind card
- Elixir cost floats up from bar
- Spawn particle effects
- Unit spawn sound effect

### Chest Opening Sequence

**Interaction Flow:**
1. Tap chest to initiate unlock
2. If locked: Shows timer OR "Speed Up" gem option
3. If unlocked: Chest animates (shakes, glows)
4. Tap to open OR auto-opens after 2 seconds
5. Chest explodes with particles
6. Cards fly out one by one (0.3s intervals)
7. Gold/gems display last
8. "Tap to Continue" after sequence
9. Return to home with updated inventory

**Psychological Design:**
- Build anticipation with animations
- Reward reveal paced (not instant)
- Satisfying audio/visual feedback
- Special effects for rare cards (golden glow, longer animation)

### Battle Emotes

**Emote Wheel:**
- Swipe from left edge to open radial menu
- 6-8 emotes arranged in circle
- Release on desired emote to send
- 2-second cooldown between emotes
- Opponent sees emote animation + sound

**Emote Categories:**
- Greeting (Wave, Thumbs up)
- Taunting (Laughing, Crying)
- Strategic (Good game, Well played, Oops!)
- Seasonal/Event exclusive

### Tutorial & Onboarding

**First Time User Experience (FTUE):**

**Step 1: Intro (30 seconds)**
- Cinematic showing battlefield
- Voice-over: "Welcome to Battle Castles!"
- Skip button available (top-right)

**Step 2: First Battle (2 minutes)**
- Pre-configured deck (4 cards only)
- AI opponent (very easy)
- Forced tutorial prompts:
  - "Drag Knight to battlefield"
  - "Deploy Archers behind Knight"
  - "Attack enemy tower!"
- Victory guaranteed

**Step 3: Rewards Introduction**
- Chest earned screen
- "Open your first chest!"
- Cards revealed with explanation
- Gold introduction

**Step 4: Home Screen Tour**
- Highlights main features with arrows
- "Battle again", "View cards", "Build deck"
- Each interaction completes step

**Step 5: Deck Building Basics**
- Guided deck creation
- "Add 8 cards to your deck"
- Explains elixir cost

**Total FTUE Time:** 5-7 minutes  
**Skip Option:** Available after Step 2

### Progression Feedback

**Level Up Animation:**
- Fullscreen burst effect
- "LEVEL UP!" text
- New features unlocked shown
- Can't be skipped (important milestone)

**Trophy Milestones:**
- Arena advancement: Special animation
- Confetti effects
- New cards unlocked displayed
- Arena artwork reveal

**Card Upgrade:**
- Stats increase animation (numbers grow)
- Visual "power up" effect on card
- Audio cue (power chord)
- Before/after comparison shown

---

## Visual Design System

### Color Palette

**Primary Colors:**
- Arena Blue: #2E5CFF (Your side indicator)
- Enemy Red: #FF3B3B (Opponent side)
- Elixir Purple: #A855F7 (Resource bar)
- Gold Yellow: #FFD700 (Currency)
- Gem Cyan: #00D9FF (Premium currency)

**Rarity Colors:**
- Common: #A0A0A0 (Grey)
- Rare: #FF8C00 (Orange)
- Epic: #A020F0 (Purple)
- Legendary: #FFD700 (Gold)

**UI Elements:**
- Background: #1A1A2E (Dark blue-grey)
- Cards/Panels: #252542 (Lighter grey)
- Text Primary: #FFFFFF (White)
- Text Secondary: #B0B0B0 (Light grey)
- Success: #00C853 (Green)
- Warning: #FF6F00 (Orange)
- Error: #D50000 (Red)

### Typography

**Font Family:**
- Primary: "Roboto Condensed" (mobile-optimized)
- Headings: "Bebas Neue" (impact/strength)
- Numbers: "Roboto Mono" (clarity)

**Text Hierarchy:**
| Element | Size | Weight | Usage |
|---------|------|--------|-------|
| H1 | 36pt | Bold | Screen titles |
| H2 | 24pt | Bold | Section headers |
| H3 | 18pt | Semibold | Card names |
| Body | 16pt | Regular | Descriptions |
| Small | 12pt | Regular | Metadata |
| Tiny | 10pt | Regular | Disclaimer |

### Iconography

**Icon Style:**
- Flat design with subtle gradients
- 2pt stroke weight
- Rounded corners (4px radius)
- Consistent sizing (24x24, 48x48, 96x96)

**Standard Icons:**
- Trophy: 🏆 (Victory/ranking)
- Gem: 💎 (Premium currency)
- Coin: 🪙 (Gold)
- Swords: ⚔️ (Battle/attack)
- Shield: 🛡️ (Defense)
- Clock: ⏰ (Time remaining)
- Star: ⭐ (Rating/quality)
- Crown: 👑 (Victory crowns)

### Animation Principles

**Timing Standards:**
- Micro-interactions: 100-200ms (button press)
- Transitions: 300-500ms (screen change)
- Feedback: Immediate (<16ms response)
- Celebrations: 1000-2000ms (victory)

**Easing Functions:**
- Buttons: Ease-out (snappy feel)
- Panels: Ease-in-out (smooth motion)
- Explosions: Ease-out + bounce
- UI elements: Ease-out cubic

**Animation Budget:**
- Mobile: Max 60 FPS during battle
- Reduce particles on low-end devices
- Disable non-essential animations if FPS drops

---

## Responsive Design

### Mobile (Portrait - Primary)

**Screen Sizes Supported:**
- Small: 320x568 (iPhone SE)
- Medium: 375x667 (iPhone 8)
- Large: 414x896 (iPhone 11)
- Extra Large: 428x926 (iPhone 13 Pro Max)

**Scaling Strategy:**
- Fixed layout ratios (not pixel-perfect)
- UI scales proportionally
- Touch targets remain minimum 44x44pt
- Text scales with device size

### Mobile (Landscape - Secondary)

**Layout Changes:**
- Battlefield rotates 90°
- UI elements move to sides (left: cards, right: info)
- Not recommended for gameplay
- Supported for accessibility

### Tablet (Optional)

**iPad/Android Tablets:**
- Larger card preview on tap
- More cards visible in collection (grid)
- Split-screen friendly
- Enhanced clan chat space

### PC (Steam - Secondary)

**Desktop Adaptations:**
- Mouse cursor replaces touch
- Click + drag for card deployment
- Keyboard shortcuts:
  - Number keys (1-4): Select cards
  - Space: Deploy selected card at cursor
  - ESC: Cancel/pause
- Larger UI elements (16:9 aspect)
- Higher resolution assets
- Uncapped frame rate

---

## Accessibility Features

### Visual Accessibility

**Colorblind Modes:**
- Protanopia (Red-blind): Blue vs Yellow team colors
- Deuteranopia (Green-blind): Blue vs Orange
- Tritanopia (Blue-blind): Red vs Green
- High contrast mode: Brighter outlines

**Text Accessibility:**
- Scalable text (100%, 125%, 150%)
- Dyslexia-friendly font option (OpenDyslexic)
- High contrast text backgrounds

### Audio Accessibility

**Audio Cues:**
- Unit deployment sound (helps blind/low-vision)
- Enemy unit spawn warning sound
- Tower destruction fanfare
- Elixir full notification sound

**Visual Alternatives:**
- Closed captions for voice lines
- Visual indicators for audio cues (flash screen edge)

### Motor Accessibility

**Simplified Controls:**
- Tap-only mode (no dragging required)
- Slower tap timing tolerance
- Auto-aim assist for card placement
- Larger touch targets mode (+50% size)

**Input Options:**
- Swipe gestures optional (can disable)
- Hold-to-confirm option (prevent accidents)
- One-handed mode (shifts UI to preferred side)

---

## Performance Optimization

### Loading Strategies

**Lazy Loading:**
- Load main menu assets first
- Battle assets load during matchmaking
- Card images load progressively
- Low-res placeholders until full-res loads

**Asset Bundles:**
- Core UI: ~5MB (always loaded)
- Per-arena assets: ~2MB each
- Unit animations: ~500KB per unit
- Total install size target: <150MB

### Network Optimization

**Bandwidth Usage:**
- Battle state sync: ~10KB/second
- Replay data: ~50KB per match
- Chat messages: <1KB per message
- Asset updates: Progressive downloads in background

### Battery Optimization

**Power Saving Modes:**
- Reduce particle effects
- Lower frame rate (30 FPS option)
- Dim background animations
- Disable shadows

---

## Error States & Edge Cases

### Network Issues

**Connection Lost:**
```
┌─────────────────────────────┐
│    CONNECTION LOST          │
│                             │
│    [Reconnecting...]        │
│    (Spinner animation)      │
│                             │
│    Battle will resume...    │
│    [Cancel Battle]          │
└─────────────────────────────┘
```

- Auto-reconnect attempts (3x)
- Battle pauses for both players
- 60-second grace period
- If timeout: Draw (no trophy change)

### Full Chest Slots

**Warning Message:**
```
┌─────────────────────────────┐
│    CHEST SLOTS FULL!        │
│                             │
│  You won't earn chests      │
│  from victories until you   │
│  unlock a chest.            │
│                             │
│  [Unlock Chest] [Speed Up]  │
│  [Continue Anyway]          │
└─────────────────────────────┘
```

### Insufficient Resources

**Can't Upgrade Card:**
```
┌─────────────────────────────┐
│  INSUFFICIENT GOLD          │
│                             │
│  Need: 4,000 gold           │
│  You have: 1,200 gold       │
│                             │
│  [Buy Gold] [Cancel]        │
│  [Earn Gold - Tips]         │
└─────────────────────────────┘
```

---

## Future UX Improvements

### Planned Features

**Version 1.1:**
- Replay theater mode (watch saved replays)
- Advanced statistics dashboard
- Deck recommendations based on AI

**Version 1.2:**
- Spectator mode (watch friends live)
- Clan chat emotes and stickers
- Battle highlights (auto-generated clips)

**Version 2.0:**
- 3D battlefield option
- AR mode (view battle on table)
- Voice chat for 2v2 mode

---

**Document Ownership:**  
UI/UX Designer, Creative Director

**Review Schedule:**  
Weekly UX testing sessions, monthly usability audits

**Version History:**
- v1.0 - Initial UI/UX specifications (October 30, 2025)
