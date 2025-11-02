# Battle Castles - Asset Generation Guide

This document contains all DALL-E prompts and file naming conventions for generating game assets.

## Table of Contents
- [Directory Structure](#directory-structure)
- [File Naming Conventions](#file-naming-conventions)
- [DALL-E Prompts](#dall-e-prompts)
- [Post-Processing Notes](#post-processing-notes)

---

## Directory Structure

```
client/
├── assets/
│   ├── sprites/
│   │   ├── units/
│   │   ├── buildings/
│   │   ├── icons/
│   │   ├── effects/
│   │   ├── ui/
│   │   └── battlefield/
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   └── fonts/
```

---

## File Naming Conventions

### Unit Sprites → `/assets/sprites/units/`

**Player Units (Blue/Primary Color)**
- `knight_player.png` (36x52px minimum)
- `goblin_player.png` (28x40px minimum)
- `archer_player.png` (32x48px minimum)
- `giant_player.png` (50x70px minimum)

**Enemy Units (Red/Secondary Color)**
- `knight_enemy.png`
- `goblin_enemy.png`
- `archer_enemy.png`
- `giant_enemy.png`

**Animation Frames (Optional - for future implementation)**
- `knight_player_idle_01.png`, `knight_player_idle_02.png`, etc.
- `knight_player_walk_01.png`, `knight_player_walk_02.png`, etc.
- `knight_player_attack_01.png`, `knight_player_attack_02.png`, etc.
- (Same pattern for all units)

### Card Icons → `/assets/sprites/icons/`

Referenced in CardData resources (card_data.gd:9)
- `knight_icon.png` (64x64px or 128x128px)
- `goblin_icon.png`
- `archer_icon.png`
- `giant_icon.png`

### Buildings/Towers → `/assets/sprites/buildings/`

- `tower_player.png`
- `tower_enemy.png`
- `castle_player.png`
- `castle_enemy.png`

**Optional Destroyed States**
- `tower_player_destroyed.png`
- `tower_enemy_destroyed.png`
- `castle_player_destroyed.png`
- `castle_enemy_destroyed.png`

### UI Elements → `/assets/sprites/ui/`

- `card_frame.png` (background for card display)
- `card_frame_common.png`
- `card_frame_rare.png`
- `card_frame_epic.png`
- `card_frame_legendary.png`
- `elixir_icon.png` (32x32px)
- `crown_icon.png` (32x32px)
- `health_bar_fill.png` (seamless, 100x10px)
- `health_bar_bg.png`
- `elixir_bar_fill.png`
- `elixir_bar_bg.png`
- `avatar_frame.png` (64x64px or 128x128px)

### Visual Effects → `/assets/sprites/effects/`

- `impact_hit.png` (attack impact)
- `deploy_effect.png` (unit spawn)
- `tower_destroy.png` (tower destruction)
- `damage_flash.png` (hit indicator)
- `elixir_warning.png` (not enough elixir)
- `arrow.png` (arrow projectile for Archer)

**Animation Sequences (Optional)**
- `impact_01.png`, `impact_02.png`, `impact_03.png`, etc.
- `deploy_01.png`, `deploy_02.png`, etc.

### Battlefield Elements → `/assets/sprites/battlefield/`

- `river_texture.png` (tileable, 256x256px or larger)
- `grass_texture.png` (tileable, 256x256px or larger)
- `deployment_zone_player.png` (overlay, semi-transparent)
- `deployment_zone_enemy.png` (overlay, semi-transparent)
- `grid_overlay.png` (optional decorative grid)

### Audio Files → `/assets/audio/`

**Sound Effects → `/assets/audio/sfx/`**
- `card_select.ogg`
- `card_deploy.ogg`
- `knight_attack.ogg`
- `goblin_attack.ogg`
- `archer_attack.ogg`
- `giant_attack.ogg`
- `unit_death.ogg`
- `tower_hit.ogg`
- `tower_destroy.ogg`
- `button_click.ogg`
- `elixir_warning.ogg`

**Music → `/assets/audio/music/`**
- `battle_theme.ogg`
- `victory.ogg`
- `defeat.ogg`

---

## DALL-E Prompts

### 1. Unit Sprites

#### Knight (Player - Blue) [x]
```
A cartoon-style fantasy knight character sprite for a mobile game, viewed from a 45-degree top-down isometric angle, wearing blue armor and cape, holding a sword and shield, standing in an idle pose, simple and clean design with bold outlines, vibrant colors, TRANSPARENT BACKGROUND, character should be 36x52 pixels scale, Clash Royale art style, full body visible, PNG with alpha channel
```

#### Knight (Enemy - Red) [x]
```
A cartoon-style fantasy knight character sprite for a mobile game, viewed from a 45-degree top-down isometric angle, wearing red armor and cape, holding a sword and shield, standing in an idle pose, simple and clean design with bold outlines, vibrant colors, TRANSPARENT BACKGROUND, character should be 36x52 pixels scale, Clash Royale art style, full body visible, PNG with alpha channel
```

#### Goblin (Player - Green) [x]
```
A cartoon-style goblin character sprite for a mobile game, viewed from a 45-degree top-down isometric angle, bright green skin, wearing simple leather armor, holding a dagger or short sword, mischievous expression, smaller character, simple and clean design with bold outlines, vibrant colors, TRANSPARENT BACKGROUND, Clash Royale art style, full body visible, PNG with alpha channel
```

#### Goblin (Enemy - Orange) [x]
```
A cartoon-style goblin character sprite for a mobile game, viewed from a 45-degree top-down isometric angle, orange-brown skin, wearing simple leather armor, holding a dagger or short sword, mischievous expression, smaller character, simple and clean design with bold outlines, vibrant colors, TRANSPARENT BACKGROUND, Clash Royale art style, full body visible, PNG with alpha channel
```

#### Archer (Player - Purple) [x]
```
A cartoon-style archer character sprite for a mobile game, viewed from a 45-degree top-down isometric angle, wearing purple hood and archer outfit, holding a bow, quiver of arrows on back, standing in ready pose, simple and clean design with bold outlines, vibrant colors, TRANSPARENT BACKGROUND, Clash Royale art style, full body visible, PNG with alpha channel
```

#### Archer (Enemy - Pink) [x]
```
A cartoon-style archer character sprite for a mobile game, viewed from a 45-degree top-down isometric angle, wearing pink hood and archer outfit, holding a bow, quiver of arrows on back, standing in ready pose, simple and clean design with bold outlines, vibrant colors, TRANSPARENT BACKGROUND, Clash Royale art style, full body visible, PNG with alpha channel
```

#### Giant (Player - Gray) [x]
```
A cartoon-style giant character sprite for a mobile game, viewed from a 45-degree top-down isometric angle, large muscular character wearing gray stone armor, holding a massive club or hammer, powerful stance, simple and clean design with bold outlines, vibrant colors, TRANSPARENT BACKGROUND, Clash Royale art style, full body visible, much larger than other units, PNG with alpha channel
```

#### Giant (Enemy - Dark Red) [x]
```
A cartoon-style giant character sprite for a mobile game, viewed from a 45-degree top-down isometric angle, large muscular character wearing dark red armor, holding a massive club or hammer, powerful stance, simple and clean design with bold outlines, vibrant colors, TRANSPARENT BACKGROUND, Clash Royale art style, full body visible, much larger than other units, PNG with alpha channel
```

---

### 2. Card Icons

#### Knight Card Icon [x]
```
A square portrait icon of a cartoon fantasy knight character for a mobile game card, facing forward, blue armor with gold trim, sword and shield crossed, heroic expression, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Goblin Card Icon [x]
```
A square portrait icon of a cartoon goblin character for a mobile game card, facing forward, bright green skin, mischievous grin showing teeth, leather cap, holding dagger, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Archer Card Icon [x]
```
A square portrait icon of a cartoon archer character for a mobile game card, facing forward, purple hooded cloak, bow visible, focused expression, arrow fletching visible over shoulder, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Giant Card Icon [x]
```
A square portrait icon of a cartoon giant character for a mobile game card, facing forward, massive muscular build, gray stone armor, fierce but friendly expression, club or hammer visible, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

---

### 2b. Additional Troop Card Icons

#### Barbarians Card Icon []
```
A square portrait icon of a cartoon barbarian warrior for a mobile game card, facing forward, fierce bearded warrior with horned helmet, muscular build, holding large sword or axe, orange-brown fur and leather armor, fierce battle cry expression, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Musketeer Card Icon []
```
A square portrait icon of a cartoon musketeer character for a mobile game card, facing forward, elegant female musketeer with feathered hat, holding long rifle/musket, blue uniform with gold trim, confident expression, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Mini PEKKA Card Icon []
```
A square portrait icon of a cartoon robot knight character for a mobile game card, facing forward, compact armored robot with glowing eyes, metallic dark blue armor, holding large sword, menacing but cartoonish appearance, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Wizard Card Icon []
```
A square portrait icon of a cartoon wizard character for a mobile game card, facing forward, bearded wizard with purple robe and pointed hat, magical staff with glowing orb, mystical expression, magical energy swirls, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Baby Dragon Card Icon []
```
A square portrait icon of a cartoon baby dragon for a mobile game card, facing forward, cute but fierce purple dragon with small wings, breathing fire, large eyes, flying pose, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Skeleton Army Card Icon []
```
A square portrait icon of cartoon skeletons for a mobile game card, facing forward, group of 3-4 skeleton warriors with swords and shields, white bones, cartoonish and not scary, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Minions Card Icon []
```
A square portrait icon of cartoon minion creatures for a mobile game card, facing forward, small flying imp-like creatures with wings, purple-black skin, menacing grins, holding small spears, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Valkyrie Card Icon []
```
A square portrait icon of a cartoon valkyrie warrior for a mobile game card, facing forward, fierce female warrior with horned helmet, red hair in braids, holding large double-bladed axe, orange-red armor, battle-ready expression, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

---

### 2c. Spell Card Icons

#### Fireball Card Icon []
```
A square portrait icon of a fireball spell for a mobile game card, large flaming orange-red fireball with yellow flames and sparks, magical energy swirls, explosive appearance, no character just the spell effect, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Arrows Card Icon []
```
A square portrait icon of an arrows spell for a mobile game card, multiple arrows flying in formation, blue-gray metal tips, wooden shafts, motion lines, spell card aesthetic, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Lightning Card Icon []
```
A square portrait icon of a lightning spell for a mobile game card, bright yellow-white lightning bolts striking down, electric energy crackling, storm clouds, powerful magical appearance, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Freeze Card Icon []
```
A square portrait icon of a freeze spell for a mobile game card, ice crystal formation with snowflakes, blue-white frozen energy, magical frost effect radiating outward, cold mist, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Rage Card Icon []
```
A square portrait icon of a rage spell for a mobile game card, purple-pink magical energy swirl with sparkles, speed lines, energizing aura effect, glowing magical runes, no character just the spell effect, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Heal Card Icon []
```
A square portrait icon of a heal spell for a mobile game card, green-white healing energy with sparkles, medical cross or healing symbols, restorative magical light, gentle glow, no character just the spell effect, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

---

### 2d. Building Card Icons

#### Cannon Card Icon []
```
A square portrait icon of a defensive cannon for a mobile game card, small medieval cannon mounted on wooden base, brown wood and dark metal, angled upward ready to fire, compact defensive structure, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Tesla Card Icon []
```
A square portrait icon of a tesla tower for a mobile game card, electric defensive turret with copper coils, blue-white electricity crackling, retractable electric weapon, steampunk aesthetic, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Bomb Tower Card Icon []
```
A square portrait icon of a bomb tower for a mobile game card, stone defensive tower with bomb launcher on top, dark stone construction, explosive bombs visible, menacing appearance, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Inferno Tower Card Icon []
```
A square portrait icon of an inferno tower for a mobile game card, tall dark tower with glowing orange-red beam weapon, lava-like energy, single eye or targeting lens, threatening appearance, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

#### Elixir Collector Card Icon []
```
A square portrait icon of an elixir collector building for a mobile game card, purple crystal formation in stone housing, magical elixir pumping machine, glowing purple energy, gold trim on structure, simple bold outlines, vibrant colors, Clash Royale style, TRANSPARENT BACKGROUND or subtle gradient, icon format, PNG with alpha channel
```

---

### 3. Towers & Buildings

#### Player Tower (Blue) [x]
```
A cartoon-style defensive tower for a mobile game, isometric top-down view, blue stone construction with gold trim, medieval fantasy style, crenellations at top, small windows, flag with blue banner, simple bold outlines, vibrant colors, TRANSPARENT BACKGROUND, Clash Royale style architecture, compact design, PNG with alpha channel
```

#### Enemy Tower (Red) [x]
```
A cartoon-style defensive tower for a mobile game, isometric top-down view, red stone construction with dark trim, medieval fantasy style, crenellations at top, small windows, flag with red banner, simple bold outlines, vibrant colors, TRANSPARENT BACKGROUND, Clash Royale style architecture, compact design, PNG with alpha channel
```

#### Player Castle (Blue) [x]
```
A cartoon-style castle keep for a mobile game, isometric top-down view, large blue stone fortress with multiple towers, gold trim and banners, medieval fantasy style, grand entrance, flags flying, simple bold outlines, vibrant colors, TRANSPARENT BACKGROUND, Clash Royale style architecture, larger than regular towers, impressive main building, PNG with alpha channel
```

#### Enemy Castle (Red) [x]
```
A cartoon-style castle keep for a mobile game, isometric top-down view, large red stone fortress with multiple towers, dark trim and banners, medieval fantasy style, grand entrance, flags flying, simple bold outlines, vibrant colors, TRANSPARENT BACKGROUND, Clash Royale style architecture, larger than regular towers, impressive main building, PNG with alpha channel
```

---

### 4. UI Elements

#### Generic Card Frame/Background [x]
```
A decorative card frame border for a mobile game interface, ornate medieval fantasy style with gold trim, gemstone corners, inner space left empty for content, simple bold outlines, Clash Royale UI style, gradient background from dark to light, portrait orientation, elegant design, PNG format
```

#### Card Frame - Common (Gray/Silver) [x]
```
A decorative card frame border for a mobile game interface, COMMON rarity tier, simple silver-gray metal trim with subtle weathering, plain gemstone corners, ornate but modest medieval fantasy style, inner space left empty for content, portrait orientation, simple bold outlines, Clash Royale UI style, soft gray gradient background, PNG format
```

#### Card Frame - Rare (Blue) [x]
```
A decorative card frame border for a mobile game interface, RARE rarity tier, polished blue metal trim with gold accents, sapphire gemstone corners, more ornate medieval fantasy style with elegant engravings, inner space left empty for content, portrait orientation, simple bold outlines, Clash Royale UI style, blue-to-teal gradient background with subtle glow, PNG format
```

#### Card Frame - Epic (Purple) [x]
```
A decorative card frame border for a mobile game interface, EPIC rarity tier, luxurious purple and gold trim with intricate patterns, amethyst gemstone corners, highly ornate medieval fantasy style with detailed filigree, magical energy effects, inner space left empty for content, portrait orientation, bold outlines, Clash Royale UI style, purple gradient background with mystical shimmer, PNG format
```

#### Card Frame - Legendary (Gold/Orange) [x]
```
A decorative card frame border for a mobile game interface, LEGENDARY rarity tier, radiant gold trim with diamond gemstone corners, extremely ornate medieval fantasy style with elaborate engravings, glowing magical aura, light rays, sparkles, inner space left empty for content, portrait orientation, bold outlines, Clash Royale UI style, orange-to-gold gradient background with intense glow effect, most prestigious design, PNG format
```

#### Elixir Drop Icon [x]
```
A glowing purple elixir drop icon for a mobile game, shiny liquid droplet with magical sparkles, gradient from light purple to deep violet, simple bold outlines, TRANSPARENT BACKGROUND, Clash Royale style, icon format, 32x32 pixel scale, PNG with alpha channel
```

#### Crown Icon [x]
```
A golden crown icon for a mobile game score display, simple royal crown with three points, jewels embedded, shiny metallic gold texture, simple bold outlines, TRANSPARENT BACKGROUND, Clash Royale style, icon format, small and readable, PNG with alpha channel
```

#### Health Bar Fill [x]
```
A health bar fill texture for a mobile game UI, horizontal gradient from bright green on left to yellow-green on right, shiny glossy effect, simple design, seamless tileable texture, Clash Royale UI style, PNG format
```

---

### 5. Visual Effects

#### Attack Impact Effect []
```
A cartoon-style impact explosion effect for a mobile game, yellow and orange starburst with white highlights, action lines radiating outward, simple bold outlines, TRANSPARENT BACKGROUND, Clash Royale style combat effect, small compact design, PNG with alpha channel
```

#### Unit Deploy Effect []
```
A magical summoning circle effect for a mobile game, glowing blue runes in a circular pattern, sparkles and light particles, mystical energy swirls, TRANSPARENT BACKGROUND, Clash Royale style spawn effect, top-down view, PNG with alpha channel
```

#### Tower Destruction Effect []
```
A cartoon-style explosion effect for a mobile game, large rubble and stone debris, dust clouds, orange and gray colors, dramatic impact, simple bold outlines, TRANSPARENT BACKGROUND, Clash Royale style destruction effect, PNG with alpha channel
```

---

### 6. Battlefield Elements

#### River Texture [x]
```
A top-down view of a flowing river texture for a mobile game battlefield, cartoon-style water with gentle waves, blue-green colors, white foam highlights, simple repeating pattern, tileable seamless texture, Clash Royale art style, clean and vibrant, PNG format
```

#### Grass Battlefield Ground [x]
```
A top-down view of grass terrain texture for a mobile game battlefield, cartoon-style green grass with subtle variation, simple blades of grass detail, vibrant green colors, tileable seamless texture, Clash Royale art style, clean background pattern, PNG format
```

#### Deployment Zone Highlight (Player) [x]
```
A semi-transparent glowing area indicator for a mobile game, circular or rectangular boundary with pulsing blue light edges, magical energy effect, very transparent center, top-down view, Clash Royale UI style overlay, PNG with alpha channel
```

#### Deployment Zone Highlight (Enemy) [x]
```
A semi-transparent glowing area indicator for a mobile game, circular or rectangular boundary with pulsing red light edges, magical energy effect, very transparent center, top-down view, Clash Royale UI style overlay, PNG with alpha channel
```

---

### 7. Projectiles

#### Arrow Projectile [x]
```
A simple cartoon-style arrow projectile for a mobile game, wooden shaft with gray metal tip, colored fletching, viewed from a 45-degree angle, simple bold outlines, TRANSPARENT BACKGROUND, Clash Royale style, small weapon sprite, in-flight pose, PNG with alpha channel
```

---

## Post-Processing Notes

### DALL-E Transparency Limitations

**Important**: DALL-E 3 doesn't always generate perfect transparency. Post-processing is usually required.

### Background Removal Tools

1. **remove.bg** - Automatic, works great for characters (https://remove.bg)
2. **Photoshop** - Magic Wand or "Select Subject" feature
3. **GIMP** - Free alternative to Photoshop
4. **Photopea** - Free online editor (https://photopea.com)

### Recommended Workflow

1. **Generate images** with DALL-E using prompts above
2. **Download at 1024x1024** resolution
3. **Remove backgrounds** using one of the tools above
4. **Resize to target dimensions**:
   - Units: resize to specified pixel sizes (knight: 36x52px, etc.)
   - Icons: 64x64px or 128x128px
   - Effects: keep larger for quality
5. **Save as PNG** with alpha channel
6. **Place in correct directory** following naming conventions above

### Batch Processing

For processing multiple images, consider using:
- **ImageMagick** (command line tool)
- **Python PIL/Pillow** (scripting)
- **Photoshop Actions** (if using Photoshop)

### File Format Requirements

- **Format**: PNG with transparency (alpha channel)
- **Color Mode**: RGBA (32-bit)
- **Compression**: PNG-8 for simple graphics, PNG-24 for complex
- **Naming**: lowercase, underscores (snake_case)
- **Size**: Power-of-2 preferred for textures (32, 64, 128, 256, etc.)

---

## Integrating Assets Into Game

### Adding Card Icons

Card icons are referenced in the `.tres` resource files located in `/client/resources/cards/`.

**Example**: To add the knight icon, edit `knight.tres`:

```gdscript
[gd_resource type="Resource" script_class="CardData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/card_data.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/icons/knight_icon.png" id="2"]

[resource]
script = ExtResource("1")
icon = ExtResource("2")  # Add this line
card_name = "Knight"
# ... rest of properties
```

### Adding Unit Sprites

Unit sprites will need to be loaded in the `battlefield.gd` spawn system. This will require code modifications to replace the current ColorRect placeholders with Sprite2D nodes.

### Adding Building Sprites

Building sprites should be added to the Tower and Castle nodes in the scene files, or loaded programmatically in `battlefield.gd:setup_towers()`.

---

## Asset Priority

### High Priority (Most Visible)
1. Unit sprites (all 8: 4 units × 2 teams)
2. Card icons (4 icons)
3. Tower sprites (2: player + enemy tower)
4. Castle sprites (2: player + enemy castle)

### Medium Priority
5. UI elements (card frames, elixir icon, crown icon)
6. Health/elixir bar fills
7. Deploy effect

### Low Priority
8. Battlefield textures (grass, river)
9. Impact effects
10. Projectiles
11. Audio files

---

## Next Steps

1. Generate assets using DALL-E prompts above
2. Process images (remove backgrounds, resize, optimize)
3. Place files in correct directories with correct names
4. Update `.tres` resource files to reference new icons
5. Test in-game to verify proper display
6. Iterate on any assets that don't look right

---

**Document Version**: 1.0
**Last Updated**: November 2, 2025
**Game**: Battle Castles
**Engine**: Godot 4.5.1
