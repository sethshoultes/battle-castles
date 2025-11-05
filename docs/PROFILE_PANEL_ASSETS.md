# Profile Panel Asset Generation Guide

## Overview
This document contains prompts for generating visual assets for the main menu profile panel. The profile panel displays player information, resources, and progression in the top-left corner of the main menu.

## Style Guidelines
- **Art Style**: Clash Royale-inspired, cartoon/stylized medieval fantasy
- **Color Palette**:
  - Gold/Orange borders (#FFB84D, #FF9500)
  - Dark backgrounds (#2C2C3E, #1C1C28)
  - Blue accents for information (#4A90E2, #357ABD)
- **Border Style**: Thick golden borders with corner embellishments
- **Size**: All icons should be exported at 2x resolution for crisp display

---

## Required Assets

### 1. Profile Panel Background []
**File**: `client/assets/sprites/ui/profile_panel_bg.png`
**Dimensions**: 320px × 400px (or similar rectangular)
**Prompt**:
```
A medieval fantasy game UI panel background with dark blue-gray center (#2C2C3E) and thick golden ornate border, decorative corner pieces with subtle embossing, slight inner shadow for depth, polished wood or stone appearance with gold trim, cartoon style, clean and professional design, TRANSPARENT BACKGROUND, panel should be 320x400 pixels, Clash Royale UI aesthetic, suitable for displaying player profile information, PNG with alpha channel.
```

### 2. Player Avatar Frame []
**File**: `client/assets/sprites/ui/avatar_frame.png`
**Dimensions**: 80px × 80px (circular frame)
**Prompt**:
```
A circular golden frame for player avatar icon with ornate decorative elements, thick golden border with corner flourishes, dark inner circle where avatar will be displayed, prestigious appearance, subtle highlights and shadows for dimensional look, medieval fantasy theme, TRANSPARENT BACKGROUND, frame should be 80x80 pixels, Clash Royale style, PNG with alpha channel.
```

### 3. Default Player Avatar []
**File**: `client/assets/sprites/ui/default_avatar.png`
**Dimensions**: 64px × 64px (circular, fits inside frame)
**Prompt**:
```
A default player avatar icon showing a generic knight or warrior character with simple friendly face and helmet, front view, bold colors and simple shapes, gender-neutral and appealing design, works well at small sizes, TRANSPARENT BACKGROUND, icon should be 64x64 pixels, Clash Royale cartoon style, fits inside circular frame, PNG with alpha channel.
```

### 4. Trophy Icon []
**File**: `client/assets/sprites/ui/icons/trophy_icon.png`
**Dimensions**: 32px × 32px
**Prompt**:
```
A small trophy icon with golden trophy cup and purple/blue gemstone in center, shiny and prestigious-looking appearance, wide base and decorative handles, bold outlines and vibrant colors, simple enough to read at small sizes, TRANSPARENT BACKGROUND, icon should be 32x32 pixels, Clash Royale style, PNG with alpha channel.
```

### 5. Gold Coin Icon []
**File**: `client/assets/sprites/ui/icons/gold_icon.png`
**Dimensions**: 32px × 32px
**Prompt**:
```
A small gold coin icon showing round gold coin at slight angle for depth, simple emblem or star in center, bright gold color (#FFD700) with darker gold shading, white shine/highlight for shiny valuable appearance, simple and clear at small sizes, TRANSPARENT BACKGROUND, coin should be 32x32 pixels, Clash Royale cartoon style, PNG with alpha channel.
```

### 6. Gem Icon []
**File**: `client/assets/sprites/ui/icons/gem_icon.png`
**Dimensions**: 32px × 32px
**Prompt**:
```
A small gem/diamond icon with purple or pink gemstone and faceted cuts, shown from 3/4 view angle, sparkles with white highlights and magical appearance, vibrant colors (magenta, purple, pink), clearly distinguishable from gold coin, subtle glow effect, TRANSPARENT BACKGROUND, gem should be 32x32 pixels, Clash Royale style, PNG with alpha channel.
```

### 7. Level Badge Background []
**File**: `client/assets/sprites/ui/level_badge.png`
**Dimensions**: 48px × 48px
**Prompt**:
```
A small hexagonal or shield-shaped badge background for displaying player level with gradient from light blue to darker blue (#4A90E2 to #2C5AA0), golden border, achievement badge or military rank insignia appearance, center clear for level number display, TRANSPARENT BACKGROUND, badge should be 48x48 pixels, Clash Royale style, PNG with alpha channel.
```

### 8. Arena Badge Frame []
**File**: `client/assets/sprites/ui/arena_badge_frame.png`
**Dimensions**: 64px × 64px
**Prompt**:
```
A decorative frame for arena/league badges with shield or crest shape, golden ornate border and dark center, prestigious appearance matching medieval fantasy theme, subtle details like rivets, engravings, or decorative flourishes, center clear for arena icons, TRANSPARENT BACKGROUND, frame should be 64x64 pixels, Clash Royale style, PNG with alpha channel.
```

### 9. Chest Slot Frame (Empty) []
**File**: `client/assets/sprites/ui/chest_slot_empty.png`
**Dimensions**: 64px × 64px
**Prompt**:
```
An empty chest slot frame with square frame and rounded corners, golden border, dark/gray interior indicating empty state, subtle "plus" or "empty" indicator in center, matches profile panel aesthetic, clearly indicates where chest appears when earned, TRANSPARENT BACKGROUND, frame should be 64x64 pixels, Clash Royale style, PNG with alpha channel.
```

### 10. Chest Slot Frame (Filled) []
**File**: `client/assets/sprites/ui/chest_slot_filled.png`
**Dimensions**: 64px × 64px
**Prompt**:
```
A filled chest slot frame with same dimensions as empty slot but golden glow or highlight effect indicating chest present, more vibrant border, subtle animation-ready glow effect, used as background when chest icon displayed, TRANSPARENT BACKGROUND, frame should be 64x64 pixels, Clash Royale style, PNG with alpha channel.
```

### 11. Resource Container Background []
**File**: `client/assets/sprites/ui/resource_counter_bg.png`
**Dimensions**: 120px × 36px (horizontal pill shape)
**Prompt**:
```
A small horizontal pill-shaped background for resource counters (gold, gems, trophies) with dark background (#1C1C28) and golden border, rounded ends, compact and clearly readable design, slight gradient and inner shadow for depth, holds icon on left and numbers on right, TRANSPARENT BACKGROUND, background should be 120x36 pixels, Clash Royale style, PNG with alpha channel.
```

---

## Arena Badge Icons (Future Enhancement) []
These can be created later but are referenced in the profile panel:

### Training Camp Arena
**File**: `client/assets/sprites/ui/arenas/training_camp.png`
**Dimensions**: 48px × 48px
**Prompt**:
```
An arena badge icon for "Training Camp" showing simple wooden training dummy or practice target with crossed swords, brown and tan colors, clearly indicates beginner/starting arena, cartoon style with bold outlines, TRANSPARENT BACKGROUND, icon should be 48x48 pixels, Clash Royale style, PNG with alpha channel.
```

---

## File Structure
After creating these assets, your file structure should look like:

```
client/assets/sprites/ui/
├── profile_panel_bg.png          # Main panel background
├── avatar_frame.png               # Frame for player avatar
├── default_avatar.png             # Default player icon
├── level_badge.png                # Level number background
├── arena_badge_frame.png          # Arena icon frame
├── chest_slot_empty.png           # Empty chest slot
├── chest_slot_filled.png          # Filled chest slot indicator
├── resource_counter_bg.png        # Background for resource counters
└── icons/
    ├── trophy_icon.png            # Trophy/rank icon
    ├── gold_icon.png              # Gold coin icon
    └── gem_icon.png               # Premium currency icon
```

---

## Implementation Notes

Once you've generated these assets:

1. **Export Settings**:
   - PNG format with transparency
   - 2x resolution for retina displays
   - Optimize file size (use tools like TinyPNG)

2. **Testing**:
   - View at actual size (50% zoom) to ensure clarity
   - Test on dark and light backgrounds
   - Verify icons are distinguishable from each other

3. **Godot Import Settings**:
   - Set texture filter to "Linear" for smooth scaling
   - Enable mipmaps for icons that may scale
   - Set compression to "Lossless" for UI elements

4. **Next Steps**: Once assets are created, I'll update the profile panel scene and script to use them properly.

---

## Color Reference

**Primary Gold**: `#FFB84D` (light) to `#FF9500` (dark)
**Dark Backgrounds**: `#2C2C3E` (light) to `#1C1C28` (dark)
**Blue Accents**: `#4A90E2` (light) to `#357ABD` (dark)
**Resource Colors**:
- Gold: `#FFD700`
- Gems: `#E91E63` (pink/magenta)
- Trophies: `#FFB84D` (gold)

---

**Created**: November 4, 2025
**Last Updated**: November 4, 2025
