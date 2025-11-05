# Profile Screen Testing Guide

**Feature:** Player Profile & Stats UI
**Branch:** `feature/profile-stats-ui`
**Date:** November 5, 2025

---

## Overview

New full-screen player profile UI that displays comprehensive player statistics and information. Accessible by clicking the profile panel on the main menu.

## What Was Implemented

### Files Created
1. **`scenes/ui/profile_screen.tscn`** - Complete profile screen scene
2. **`scripts/ui/profile_screen_ui.gd`** - Profile UI controller script
3. **`scripts/ui/profile_screen_ui.gd.uid`** - Godot UID file

### Files Modified
1. **`scripts/ui/main_menu_ui.gd`**
   - Added profile panel click handler
   - Integrated with PlayerProfile system
   - Added smooth navigation to profile screen

## Features to Test

### 1. Navigation
- [ ] **Main Menu → Profile Screen**
  - Click on the profile panel (left side of main menu)
  - Profile panel should animate (slight scale down/up)
  - Scene should transition to profile screen after 0.15s
  - No errors in console

- [ ] **Profile Screen → Main Menu**
  - Click "← Back" button in top-left
  - Should return to main menu
  - No errors in console

### 2. Player Information Display

#### Left Column - Profile Card
- [ ] **Avatar**
  - Avatar image displays in golden frame
  - Frame size: 200×200 pixels
  - Properly centered

- [ ] **Player Name**
  - Displays player's username
  - Default: "Player" (if no profile)
  - Font size: 28px

- [ ] **Player ID**
  - Shows "ID: PLAYER_XXXXX" format
  - Gray color (0.7, 0.7, 0.8)
  - Font size: 16px

#### Level Section
- [ ] **Level Badge**
  - Shows level number inside badge
  - Badge size: 50×50 pixels
  - Level displayed next to badge

- [ ] **XP Progress Bar**
  - Shows current XP / XP needed for next level
  - Progress bar fills proportionally
  - Label below shows "X / Y XP"
  - At max level (50): shows "MAX LEVEL"

#### Arena Section
- [ ] **Arena Display**
  - Shows current arena name
  - Arena names match trophy thresholds:
    - 0-299: Training Camp
    - 300-599: Goblin Stadium
    - 600-999: Bone Pit
    - 1000-1299: Barbarian Bowl
    - 1300-1599: Spell Valley
    - 1600-1999: Builder's Workshop
    - 2000-2299: Royal Arena
    - 2300-2599: Frozen Peak
    - 2600-2999: Jungle Arena
    - 3000+: Hog Mountain

- [ ] **Trophy Display**
  - Shows current trophies
  - Shows highest trophies (personal best)
  - Format: "X / Y" with separator
  - Highest trophies in lighter color

### 3. Battle Statistics (Right Column)

#### Stats Grid
- [ ] **Total Battles**
  - Shows total battles played
  - Blue color (0.4, 0.8, 1)
  - Font size: 24px

- [ ] **Wins**
  - Shows total wins
  - Green color (0.3, 1, 0.3)

- [ ] **Losses**
  - Shows total losses
  - Red color (1, 0.3, 0.3)

- [ ] **Draws**
  - Shows total draws
  - Yellow color (0.8, 0.8, 0.4)

- [ ] **Win Rate**
  - Calculated as (wins / total) × 100
  - Shows percentage with 1 decimal (e.g., "65.5%")
  - Gold color (1, 0.843, 0)
  - Shows "0%" if no battles played

- [ ] **3-Crown Wins**
  - Shows count of 3-crown victories
  - Orange color (1, 0.5, 0)

#### Collection Stats
- [ ] **Cards Collected**
  - Shows number from stats
  - Blue color (0.4, 0.8, 1)

- [ ] **Donations**
  - Shows donation count
  - Pink color (1, 0.6, 1)

### 4. Data Integration

- [ ] **PlayerProfile Loading**
  - Profile data loads from GameManager.player_profile
  - Falls back to defaults if no profile exists
  - No null reference errors

- [ ] **Real-Time Data**
  - After completing a battle, stats should update
  - Level ups should reflect immediately
  - Trophy changes should show

### 5. Visual Polish

- [ ] **Layout**
  - Two-column layout: Left (profile info), Right (stats)
  - Proper spacing and padding
  - No overlapping elements
  - Responsive on different resolutions

- [ ] **Cards/Panels**
  - Dark background with borders
  - Sections clearly separated
  - Text is readable (good contrast)

- [ ] **Colors**
  - Background: Dark blue-gray (0.05, 0.05, 0.08)
  - Stat colors match design (green wins, red losses)
  - Labels are white or light gray

- [ ] **Typography**
  - Title: 36px
  - Section headers: 28px, 24px
  - Stats labels: 20px
  - Stats values: 24px
  - All text legible

### 6. Edge Cases

- [ ] **New Player (No Battles)**
  - All stats show "0"
  - Win rate shows "0%"
  - Level shows 1
  - XP bar at 0
  - No errors

- [ ] **Max Level Player (Level 50)**
  - XP bar full
  - Label shows "MAX LEVEL"
  - No XP value shown

- [ ] **No PlayerProfile**
  - Falls back to default values
  - Shows "Player" as name
  - Shows "ID: UNKNOWN"
  - No crashes

- [ ] **Different Arenas**
  - Test with various trophy counts
  - Ensure correct arena names display
  - Arena icon matches arena (if loaded)

### 7. Performance

- [ ] **Loading Time**
  - Scene loads quickly (< 0.5s)
  - No lag or stuttering

- [ ] **Memory**
  - No memory leaks
  - Scene unloads properly when leaving

- [ ] **Navigation**
  - Smooth transitions both ways
  - No duplicate scenes in memory

---

## Testing Procedure

### Manual Testing Steps

1. **Start Game**
   ```
   Open project in Godot 4.3+
   Run main scene (F5 or Play button)
   ```

2. **Test New Player Flow**
   - If existing save, delete: `user://player_profile.json`
   - Launch game, verify defaults display
   - Click profile panel
   - Verify all fields show default values
   - Click Back button

3. **Test With Battle Data**
   - Complete 3-5 battles from main menu
   - Return to main menu
   - Click profile panel
   - Verify:
     - Battles count increased
     - Win/loss stats correct
     - Win rate calculated correctly
     - Trophies updated (if implemented)

4. **Test Arena Progression**
   - Manually edit save file or use debug commands
   - Set different trophy values
   - Verify arena names change correctly

5. **Test Max Level**
   - Edit save: Set level to 50
   - Open profile
   - Verify "MAX LEVEL" displays

6. **Test Repeated Navigation**
   - Navigate: Menu → Profile → Menu → Profile
   - Repeat 5 times
   - Check for memory leaks or issues

### Console Checks

Watch for these in output:
- ✅ "Profile panel clicked - Loading profile screen..."
- ✅ "Profile loaded successfully" (on profile screen load)
- ❌ No errors about missing nodes
- ❌ No null reference errors
- ❌ No missing resource warnings

### Expected Console Output
```
Profile panel clicked - Loading profile screen...
Profile loaded successfully
[Profile data displays...]
```

---

## Known Limitations

1. **Currency Display**
   - Gold and gems show placeholder values (100, 10)
   - TODO: Integrate with CurrencyManager when implemented

2. **Avatar Selection**
   - Only default avatar supported
   - TODO: Add avatar selection system

3. **Arena Icons**
   - Only Training Camp icon loads
   - TODO: Create and load arena-specific icons

4. **Animations**
   - No entrance animations on profile screen
   - TODO: Add fade-in or slide-in animations

---

## Regression Testing

Ensure these still work:
- [ ] Main menu displays correctly
- [ ] Profile panel on main menu shows data
- [ ] All main menu buttons functional
- [ ] Battle button still works
- [ ] Deck builder still accessible
- [ ] Settings still accessible

---

## Success Criteria

### Must Pass (Critical)
1. ✅ Profile screen loads without errors
2. ✅ Back button returns to main menu
3. ✅ All stats display (even if zero)
4. ✅ No null reference exceptions
5. ✅ Navigation smooth and responsive

### Should Pass (Important)
1. ✅ Data loads from PlayerProfile system
2. ✅ Win rate calculates correctly
3. ✅ Arena names match trophy counts
4. ✅ XP progress bar updates
5. ✅ Colors match design

### Nice to Have
1. ⚠️ Smooth animations on load
2. ⚠️ Currency shows real values
3. ⚠️ Custom avatars
4. ⚠️ Arena-specific icons

---

## Bug Reporting

If issues found, report with:
1. **Steps to reproduce**
2. **Expected behavior**
3. **Actual behavior**
4. **Console output**
5. **Screenshot** (if visual issue)

---

## Next Steps After Testing

Once tests pass:
1. Merge to develop branch
2. Update CLASH_ROYALE_PARITY_ROADMAP.md (Phase 1.1 complete)
3. Plan next UI feature (Achievement Screen)
4. Consider adding:
   - Profile edit functionality
   - Match history viewer
   - Friends list integration

---

**Testing Status:** ⏳ Ready for Testing
**Last Updated:** November 5, 2025
