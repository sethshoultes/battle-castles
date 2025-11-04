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

### 1. Profile Panel Background
**File**: `client/assets/sprites/ui/profile_panel_bg.png`
**Dimensions**: 320px × 400px (or similar rectangular)
**Prompt**:
```
Create a 320x400 pixel medieval fantasy game UI panel background with a dark blue-gray center (#2C2C3E) and thick golden ornate border. The border should have decorative corner pieces with subtle embossing. The style should match Clash Royale's UI aesthetic - cartoon style, clean, and professional. Include a slight inner shadow to give depth. The panel should look like it's made of polished wood or stone with gold trim. Make it suitable for displaying player profile information. PNG with transparency.
```

### 2. Player Avatar Frame
**File**: `client/assets/sprites/ui/avatar_frame.png`
**Dimensions**: 80px × 80px (circular frame)
**Prompt**:
```
Create an 80x80 pixel circular golden frame for a player avatar icon in Clash Royale style. The frame should have ornate decorative elements, a thick golden border with corner flourishes, and a dark inner circle where the avatar will be displayed. The frame should look prestigious and match the medieval fantasy theme. Include subtle highlights and shadows to make it look dimensional. PNG with transparency.
```

### 3. Default Player Avatar
**File**: `client/assets/sprites/ui/default_avatar.png`
**Dimensions**: 64px × 64px (circular, fits inside frame)
**Prompt**:
```
Create a 64x64 pixel default player avatar icon showing a generic knight or warrior character in Clash Royale cartoon style. Should be a simple, friendly face with a helmet, shown from the front. Use bold colors and simple shapes. The icon should fit inside a circular frame and work well at small sizes. Make it gender-neutral and appealing. PNG with transparency.
```

### 4. Trophy Icon
**File**: `client/assets/sprites/ui/icons/trophy_icon.png`
**Dimensions**: 32px × 32px
**Prompt**:
```
Create a 32x32 pixel small trophy icon in Clash Royale style. Golden trophy cup with purple/blue gemstone in the center. Should be shiny and prestigious-looking but simple enough to read at small sizes. Use bold outlines and vibrant colors. The trophy should have a wide base and decorative handles. PNG with transparency.
```

### 5. Gold Coin Icon
**File**: `client/assets/sprites/ui/icons/gold_icon.png`
**Dimensions**: 32px × 32px
**Prompt**:
```
Create a 32x32 pixel small gold coin icon in Clash Royale cartoon style. Round gold coin shown at a slight angle to show depth, with a simple emblem or star in the center. Use bright gold color (#FFD700) with darker gold shading. Include a white shine/highlight to make it look shiny and valuable. Simple and clear at small sizes. PNG with transparency.
```

### 6. Gem Icon
**File**: `client/assets/sprites/ui/icons/gem_icon.png`
**Dimensions**: 32px × 32px
**Prompt**:
```
Create a 32x32 pixel small gem/diamond icon in Clash Royale style. Purple or pink gemstone with faceted cuts, shown from a 3/4 view. The gem should sparkle with white highlights and have a magical appearance. Use vibrant colors (magenta, purple, pink) and make it clearly distinguishable from the gold coin icon. Include a subtle glow effect. PNG with transparency.
```

### 7. Level Badge Background
**File**: `client/assets/sprites/ui/level_badge.png`
**Dimensions**: 48px × 48px
**Prompt**:
```
Create a 48x48 pixel small hexagonal or shield-shaped badge background for displaying player level in Clash Royale style. Use a gradient from light blue to darker blue (#4A90E2 to #2C5AA0). Include a golden border and make it look like an achievement badge or military rank insignia. The center should be clear for displaying a level number. PNG with transparency.
```

### 8. Arena Badge Frame
**File**: `client/assets/sprites/ui/arena_badge_frame.png`
**Dimensions**: 64px × 64px
**Prompt**:
```
Create a 64x64 pixel decorative frame for arena/league badges in Clash Royale style. Shield or crest shape with golden ornate border and dark center. The frame should look prestigious and match the medieval fantasy theme. Include subtle details like rivets, engravings, or decorative flourishes. The center should be clear for displaying arena icons. PNG with transparency.
```

### 9. Chest Slot Frame (Empty)
**File**: `client/assets/sprites/ui/chest_slot_empty.png`
**Dimensions**: 64px × 64px
**Prompt**:
```
Create a 64x64 pixel empty chest slot frame in Clash Royale style. A square frame with rounded corners, golden border, and dark/gray interior to indicate it's empty. Include a subtle "plus" or "empty" indicator in the center. The frame should match the profile panel aesthetic and clearly indicate this is where a chest would appear when earned. PNG with transparency.
```

### 10. Chest Slot Frame (Filled)
**File**: `client/assets/sprites/ui/chest_slot_filled.png`
**Dimensions**: 64px × 64px
**Prompt**:
```
Create a 64x64 pixel filled chest slot frame in Clash Royale style. Same dimensions as empty slot but with a golden glow or highlight effect to indicate a chest is present. The border should be more vibrant and include a subtle animation-ready glow effect. This will be used as background when a chest icon is displayed. PNG with transparency.
```

### 11. Resource Container Background
**File**: `client/assets/sprites/ui/resource_counter_bg.png`
**Dimensions**: 120px × 36px (horizontal pill shape)
**Prompt**:
```
Create a 120x36 pixel small horizontal pill-shaped background for resource counters (gold, gems, trophies) in Clash Royale style. Dark background (#1C1C28) with golden border, rounded ends. Should be compact and clearly readable. Include a slight gradient and inner shadow for depth. This will hold an icon on the left and numbers on the right. PNG with transparency.
```

---

## Arena Badge Icons (Future Enhancement)
These can be created later but are referenced in the profile panel:

### Training Camp Arena
**File**: `client/assets/sprites/ui/arenas/training_camp.png`
**Dimensions**: 48px × 48px
**Prompt**:
```
Create a 48x48 pixel arena badge icon for "Training Camp" in Clash Royale style. Simple wooden training dummy or practice target with crossed swords. Use brown and tan colors. Should clearly indicate this is the beginner/starting arena. Cartoon style with bold outlines. PNG with transparency.
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
