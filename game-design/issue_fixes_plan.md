# Battle Castles - Issue Fixes Planning Document

**Date:** November 3, 2025
**Status:** Planning Phase
**Priority:** Medium (Quality of Life Improvements)

---

## Overview

This document outlines fixes for three issues identified during the elixir system and AI balancing implementation. These are non-critical quality-of-life improvements that will enhance the player experience and code maintainability.

---

## Issue 1: Attack Timer Debug Output Spam

### Problem Description
**Location:** `/client/scripts/battle/simple_unit.gd:240, 244`

```gdscript
print("[ATTACK] ", unit_type, " hit ", target.name, " for ", damage, " damage (cooldown: ", attack_speed, "s)")
print("[COOLDOWN] ", unit_type, " attack timer reset to ", attack_speed, "s")
```

**Impact:**
- Console spam during battles (every attack generates 2 print statements)
- With 10+ units attacking, generates 20+ messages per second
- Makes debugging other issues difficult
- Performance impact (minimal but unnecessary)

**Severity:** Low
**Priority:** High (Easy fix, clean code)

### Proposed Solution

**Option A: Remove Debug Prints (Recommended)**
- Simply delete the debug print statements
- Keep functionality intact
- Clean console output

**Option B: Add Debug Flag**
- Add `const DEBUG_COMBAT = false` at top of file
- Wrap prints in `if DEBUG_COMBAT:` checks
- Allows easy re-enabling for future debugging

**Option C: Use Godot's Built-in Debug System**
- Use `@warning_ignore` or custom logger
- More sophisticated but overkill for this case

### Implementation Plan

**Recommended Approach:** Option A (simplest, cleanest)

**Steps:**
1. Open `/client/scripts/battle/simple_unit.gd`
2. Navigate to `attack_target()` function (line ~230)
3. Remove or comment out lines:
   ```gdscript
   # REMOVE:
   print("[ATTACK] ", unit_type, " hit ", target.name, " for ", damage, " damage (cooldown: ", attack_speed, "s)")
   print("[COOLDOWN] ", unit_type, " attack timer reset to ", attack_speed, "s")
   ```
4. Keep the original useful print (if exists):
   ```gdscript
   # KEEP (if it exists):
   print(unit_type, " attacked ", target.name, " for ", damage, " damage")
   ```

**Alternative (Option B):**
```gdscript
# At top of file (line ~10)
const DEBUG_COMBAT: bool = false

# In attack_target()
if DEBUG_COMBAT:
    print("[ATTACK] ", unit_type, " hit ", target.name, " for ", damage)
```

**Testing:**
- Start a battle with 10+ units
- Verify console is clean (no spam)
- Verify combat still works correctly

**Time Estimate:** 5 minutes
**Risk Level:** Very Low (no functional change)

---

## Issue 2: Missing Double Elixir Visual Indicator

### Problem Description
**Location:** `/client/scripts/ui/battle_ui.gd:113`

```gdscript
func _start_double_elixir() -> void:
    is_double_elixir = true
    elixir_rate = 1.0 / 1.4
    print("DOUBLE ELIXIR STARTED!")
    # TODO: Show visual indicator on UI  <-- THIS
```

**Impact:**
- Players don't know when double elixir starts
- Critical gameplay information missing
- Creates confusion about elixir generation speed
- Reduces strategic awareness

**Severity:** Medium
**Priority:** Medium (Important UX feature)

### Proposed Solution

**Visual Indicators to Add:**

1. **Elixir Bar Glow Effect**
   - Change elixir bar color from purple to bright pink/red
   - Add pulsing glow animation
   - Most visible indicator

2. **"2X ELIXIR" Text Badge**
   - Display badge near elixir bar
   - Similar to Clash Royale's implementation
   - Animated entrance (scale/fade in)

3. **Timer Color Change**
   - Change timer background from dark to orange/yellow
   - Indicates special game phase

4. **Screen Flash Effect (Optional)**
   - Brief white flash when double elixir starts
   - Audio cue (if sound effects exist)

### Implementation Plan

**Phase 1: Elixir Bar Visual Change (Essential)**

**Files to Modify:**
- `/client/scripts/ui/battle_ui.gd`
- `/client/scenes/ui/battle_ui.tscn` (if needed)

**Code Changes:**

```gdscript
# In battle_ui.gd

# Add reference to elixir bar background/stylebox
@onready var elixir_bar_container: Control = $ElixirContainer

# Store original colors
var elixir_bar_normal_color: Color = Color(0.6, 0.2, 0.8)  # Purple
var elixir_bar_double_color: Color = Color(1.0, 0.3, 0.4)  # Bright pink/red

func _start_double_elixir() -> void:
    is_double_elixir = true
    elixir_rate = 1.0 / 1.4
    print("DOUBLE ELIXIR STARTED!")

    # Change elixir bar color
    _animate_double_elixir_visual()

func _animate_double_elixir_visual() -> void:
    # Animate color change
    var tween = create_tween()
    tween.set_parallel(true)

    # Change bar color
    if elixir_bar:
        var stylebox = elixir_bar.get_theme_stylebox("fill")
        if stylebox:
            tween.tween_property(stylebox, "bg_color", elixir_bar_double_color, 0.5)

    # Add pulsing glow effect
    _add_pulsing_effect()

func _add_pulsing_effect() -> void:
    # Create repeating pulse animation
    var pulse_tween = create_tween()
    pulse_tween.set_loops()  # Infinite loop
    pulse_tween.tween_property(elixir_bar, "modulate:a", 0.7, 0.5)
    pulse_tween.tween_property(elixir_bar, "modulate:a", 1.0, 0.5)
```

**Phase 2: "2X ELIXIR" Text Badge (Important)**

**Code Changes:**

```gdscript
# In battle_ui.gd

# Add label for 2x indicator
var double_elixir_label: Label = null

func _ready() -> void:
    _setup_ui()
    _connect_signals()
    _load_initial_cards()
    _create_double_elixir_label()  # NEW

func _create_double_elixir_label() -> void:
    # Create label
    double_elixir_label = Label.new()
    double_elixir_label.text = "2X ELIXIR"
    double_elixir_label.add_theme_font_size_override("font_size", 28)
    double_elixir_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))  # Gold
    double_elixir_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    double_elixir_label.add_theme_constant_override("outline_size", 3)

    # Position above elixir bar
    double_elixir_label.position = Vector2(
        elixir_bar.global_position.x + elixir_bar.size.x / 2 - 60,
        elixir_bar.global_position.y - 40
    )

    # Start hidden
    double_elixir_label.modulate.a = 0.0
    double_elixir_label.scale = Vector2(0.5, 0.5)

    add_child(double_elixir_label)

func _animate_double_elixir_visual() -> void:
    # ... existing code ...

    # Animate label entrance
    if double_elixir_label:
        var label_tween = create_tween()
        label_tween.set_parallel(true)
        label_tween.tween_property(double_elixir_label, "modulate:a", 1.0, 0.3)
        label_tween.tween_property(double_elixir_label, "scale", Vector2.ONE, 0.3)\
            .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
```

**Phase 3: Timer Visual Change (Nice to Have)**

```gdscript
func _start_double_elixir() -> void:
    is_double_elixir = true
    elixir_rate = 1.0 / 1.4

    # Visual indicators
    _animate_double_elixir_visual()
    _change_timer_appearance()  # NEW

func _change_timer_appearance() -> void:
    # Add orange/yellow glow to timer
    if timer_label:
        var timer_tween = create_tween()
        timer_tween.tween_property(timer_label, "modulate", Color(1.0, 0.8, 0.2), 0.5)
```

**Phase 4: Screen Flash & Audio (Optional)**

```gdscript
func _start_double_elixir() -> void:
    is_double_elixir = true
    elixir_rate = 1.0 / 1.4

    # Visual indicators
    _animate_double_elixir_visual()
    _change_timer_appearance()
    _screen_flash_effect()  # NEW
    _play_double_elixir_sound()  # NEW

func _screen_flash_effect() -> void:
    # Create white flash overlay
    var flash = ColorRect.new()
    flash.color = Color(1, 1, 1, 0)
    flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(flash)

    var tween = create_tween()
    tween.tween_property(flash, "color:a", 0.5, 0.1)
    tween.tween_property(flash, "color:a", 0.0, 0.3)
    tween.finished.connect(func(): flash.queue_free())

func _play_double_elixir_sound() -> void:
    # Play audio cue if AudioManager exists
    if AudioManager:
        AudioManager.play_ui_sound("double_elixir_start")
```

### Testing Requirements

**Manual Testing:**
1. Start a battle
2. Wait until timer reaches 2:00
3. Verify visual indicators appear:
   - [ ] Elixir bar changes color to pink/red
   - [ ] Elixir bar has pulsing effect
   - [ ] "2X ELIXIR" label appears with animation
   - [ ] Timer background changes color (if implemented)
   - [ ] Screen flash effect works (if implemented)
4. Verify elixir regenerates at 2x speed
5. Test in different screen resolutions

**Edge Cases:**
- Game starts with < 60 seconds remaining
- Overtime triggers (should keep double elixir)
- Player quits during double elixir

**Time Estimate:** 1-2 hours
**Risk Level:** Low (purely visual, no gameplay logic change)

---

## Issue 3: AI Strategy Improvement

### Problem Description
**Location:** `/client/scripts/battle/battlefield.gd:595-620`

**Current AI Behavior:**
```gdscript
# AI just picks random affordable card
var chosen_card: CardData = affordable_cards[randi() % affordable_cards.size()]

# AI places randomly in deployment zone
var random_x = randf_range(...)
var random_y = randf_range(...)
```

**Impact:**
- AI has no strategy or tactics
- Doesn't respond to player actions
- Doesn't counter specific threats
- Doesn't defend properly
- Doesn't pressure effectively
- Makes game too easy/predictable

**Severity:** Medium (Gameplay quality)
**Priority:** Low (Works fine for initial development, improve later)

### Proposed Solution (Multi-Phase)

This is a complex feature requiring significant development. Break into phases:

#### Phase 1: Basic Decision Making (Simple AI)

**Goal:** Add basic logic to AI card selection

**Strategy Rules:**
1. **Defend when threatened**
   - If enemy units near tower/castle, spawn defensive units nearby
   - Prioritize high-HP units (Knight, Giant) for defense

2. **Counter units**
   - Track enemy unit types
   - Spawn counters (e.g., Archer vs Knight, Goblin vs Giant)

3. **Save elixir when low**
   - Don't spam all elixir at once
   - Keep reserve for defense

**Implementation:**

```gdscript
# In battlefield.gd

# AI difficulty levels
enum AIDifficulty {
    EASY,
    MEDIUM,
    HARD
}

var ai_difficulty: AIDifficulty = AIDifficulty.EASY

func _on_ai_timer_timeout() -> void:
    # Stop if game over
    if game_over:
        if ai_timer:
            ai_timer.stop()
        return

    if ai_cards.is_empty():
        return

    # NEW: Analyze battlefield situation
    var threat_level = _analyze_threat_level()
    var chosen_card = _choose_ai_card_strategic(threat_level)

    if not chosen_card:
        return  # No good option right now

    # Deduct elixir
    ai_elixir -= chosen_card.elixir_cost
    ai_elixir = max(0, ai_elixir)

    # NEW: Choose strategic position
    var spawn_pos = _choose_spawn_position(chosen_card, threat_level)

    # Spawn unit
    var unit = spawn_unit(chosen_card.unit_type, spawn_pos, TEAM_OPPONENT)

    if unit:
        print("AI deployed: ", chosen_card.card_name, " (strategic placement)")

func _analyze_threat_level() -> Dictionary:
    """
    Returns:
    {
        "threat_level": int (0-10),
        "threatened_tower": Node2D or null,
        "enemy_units_near_tower": Array,
        "our_units_alive": int
    }
    """
    var threat_data = {
        "threat_level": 0,
        "threatened_tower": null,
        "enemy_units_near_tower": [],
        "our_units_alive": 0
    }

    # Count our units
    var units_container = get_node_or_null("Units")
    if units_container:
        for unit in units_container.get_children():
            if unit.has_method("get_team") and unit.get_team() == TEAM_OPPONENT:
                threat_data.our_units_alive += 1

    # Find enemy units near our towers
    var towers_container = get_node_or_null("Towers")
    if not towers_container or not units_container:
        return threat_data

    for tower in towers_container.get_children():
        if not tower.has_method("get") or not ("team" in tower):
            continue
        if tower.team != TEAM_OPPONENT:
            continue  # Not our tower

        # Check for enemy units near this tower
        var nearby_enemies = []
        for unit in units_container.get_children():
            if not unit.has_method("get_team"):
                continue
            if unit.get_team() == TEAM_OPPONENT:
                continue  # Same team

            var distance = tower.global_position.distance_to(unit.global_position)
            if distance < 400:  # Within threat range
                nearby_enemies.append(unit)

        # Calculate threat level
        if nearby_enemies.size() > 0:
            threat_data.threat_level = nearby_enemies.size() * 2  # 2 points per enemy
            threat_data.threatened_tower = tower
            threat_data.enemy_units_near_tower = nearby_enemies
            break  # Focus on most threatened tower

    return threat_data

func _choose_ai_card_strategic(threat_data: Dictionary) -> CardData:
    """
    Choose card based on situation and AI difficulty
    """
    var affordable_cards = []
    for card in ai_cards:
        if card.elixir_cost <= ai_elixir:
            affordable_cards.append(card)

    if affordable_cards.is_empty():
        return null

    # EASY AI: Random (current behavior)
    if ai_difficulty == AIDifficulty.EASY:
        return affordable_cards[randi() % affordable_cards.size()]

    # MEDIUM AI: Basic strategy
    if ai_difficulty == AIDifficulty.MEDIUM:
        # Defend if threatened
        if threat_data.threat_level > 3:
            # Prefer defensive cards
            var defensive_cards = affordable_cards.filter(func(card):
                return card.unit_type in ["knight", "giant", "valkyrie"]
            )
            if not defensive_cards.is_empty():
                return defensive_cards[randi() % defensive_cards.size()]

        # Otherwise random attack
        return affordable_cards[randi() % affordable_cards.size()]

    # HARD AI: Advanced strategy (TODO: Implement later)
    # - Counter specific unit types
    # - Timing attacks
    # - Elixir advantage calculation

    return affordable_cards[randi() % affordable_cards.size()]

func _choose_spawn_position(card: CardData, threat_data: Dictionary) -> Vector2:
    """
    Choose strategic spawn position based on situation
    """
    # If defending, spawn near threatened tower
    if threat_data.threat_level > 3 and threat_data.threatened_tower:
        var tower_pos = threat_data.threatened_tower.global_position
        # Spawn between tower and enemies
        var avg_enemy_x = 0.0
        for enemy in threat_data.enemy_units_near_tower:
            avg_enemy_x += enemy.global_position.x
        avg_enemy_x /= threat_data.enemy_units_near_tower.size()

        # Place unit between tower and enemies
        var spawn_x = (tower_pos.x + avg_enemy_x) / 2.0
        var spawn_y = randf_range(
            opponent_deploy_area.position.y + 100,
            opponent_deploy_area.position.y + opponent_deploy_area.size.y - 100
        )

        return Vector2(spawn_x, spawn_y)

    # Otherwise, random placement (current behavior)
    var random_x = randf_range(
        opponent_deploy_area.position.x + 100,
        opponent_deploy_area.position.x + opponent_deploy_area.size.x - 100
    )
    var random_y = randf_range(
        opponent_deploy_area.position.y + 100,
        opponent_deploy_area.position.y + opponent_deploy_area.size.y - 100
    )

    return Vector2(random_x, random_y)
```

#### Phase 2: Unit Counter System (Medium AI)

**Goal:** AI recognizes and counters specific unit types

**Counter Matrix:**
| Enemy Unit | Best Counter | Reason |
|------------|--------------|--------|
| Knight | Skeleton Army | Cheap swarm |
| Giant | Mini PEKKA | High DPS |
| Goblin | Arrows/Wizard | Splash damage |
| Archer | Knight | Tank rush |

**Implementation:** Expand `_choose_ai_card_strategic()` with counter logic

#### Phase 3: Advanced Tactics (Hard AI)

**Goal:** AI uses advanced strategies

**Features:**
- **Timing attacks** - Wait for elixir advantage
- **Split pushing** - Attack multiple lanes
- **Elixir counting** - Estimate player's elixir
- **Card cycling** - Track what cards player has used
- **Combo plays** - Deploy multiple units together

**Implementation:** New AI controller class with state machine

### Implementation Priority

**Immediate (This Session):**
- ✅ None - AI works fine for now

**Short Term (Next 1-2 Weeks):**
- Phase 1: Basic Decision Making

**Medium Term (1-2 Months):**
- Phase 2: Unit Counter System

**Long Term (Post-Launch):**
- Phase 3: Advanced Tactics
- Multiple AI difficulty settings
- AI personality types (aggressive, defensive, balanced)

**Time Estimate:**
- Phase 1: 4-6 hours
- Phase 2: 8-12 hours
- Phase 3: 20+ hours

**Risk Level:** Low (can iterate gradually)

---

## Implementation Order

### Immediate (Now)
1. ✅ **Issue 1: Remove debug output** (5 minutes)
   - Quick win, clean console

### Short Term (This Week)
2. ✅ **Issue 2: Add double elixir visual** (1-2 hours)
   - Important UX feature
   - Easy to implement
   - High player impact

### Future (Post-MVP)
3. 🔄 **Issue 3: Improve AI** (Iterative, 10+ hours total)
   - Not blocking for initial release
   - Can improve gradually
   - Requires playtesting to balance

---

## Testing Checklist

### Issue 1 (Debug Output)
- [ ] Start battle with multiple units
- [ ] Verify no console spam
- [ ] Verify combat works correctly

### Issue 2 (Double Elixir Visual)
- [ ] Timer reaches 2:00
- [ ] Elixir bar changes color
- [ ] Pulsing effect works
- [ ] "2X ELIXIR" label appears
- [ ] Label animates smoothly
- [ ] Visual persists until match end
- [ ] Works in overtime
- [ ] Responsive on different screen sizes

### Issue 3 (AI Improvement)
- [ ] AI defends threatened towers
- [ ] AI doesn't waste all elixir instantly
- [ ] AI spawns in strategic positions
- [ ] AI counters player units (Phase 2)
- [ ] Different difficulty levels work (Phase 3)

---

## Success Criteria

### Issue 1
✅ Console is clean during battles
✅ Combat functionality unchanged

### Issue 2
✅ Players can clearly see when double elixir starts
✅ Visual indicator is clear and professional-looking
✅ No performance impact

### Issue 3
✅ AI feels more challenging and engaging
✅ AI makes strategic decisions
✅ Game remains balanced and fun

---

## Notes

- **Issue 1** should be fixed immediately (trivial)
- **Issue 2** should be implemented this week (important UX)
- **Issue 3** can wait until after core gameplay is solid
- All issues are non-blocking for MVP launch

**Document Version:** 1.0
**Last Updated:** November 3, 2025
**Next Review:** After implementing Issues 1 & 2
