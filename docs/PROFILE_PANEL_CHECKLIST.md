# Profile Panel Assets - Quick Checklist

## Essential Assets (Priority Order)

### Must Have (Core Functionality)
- [ ] `client/assets/sprites/ui/profile_panel_bg.png` (320×400px)
- [ ] `client/assets/sprites/ui/resource_counter_bg.png` (120×36px)
- [ ] `client/assets/sprites/ui/icons/trophy_icon.png` (32×32px)
- [ ] `client/assets/sprites/ui/icons/gold_icon.png` (32×32px)
- [ ] `client/assets/sprites/ui/icons/gem_icon.png` (32×32px)

### Important (Visual Polish)
- [ ] `client/assets/sprites/ui/avatar_frame.png` (80×80px)
- [ ] `client/assets/sprites/ui/default_avatar.png` (64×64px)
- [ ] `client/assets/sprites/ui/level_badge.png` (48×48px)

### Nice to Have (Future Enhancement)
- [ ] `client/assets/sprites/ui/arena_badge_frame.png` (64×64px)
- [ ] `client/assets/sprites/ui/chest_slot_empty.png` (64×64px)
- [ ] `client/assets/sprites/ui/chest_slot_filled.png` (64×64px)
- [ ] `client/assets/sprites/ui/arenas/training_camp.png` (48×48px)

## Workflow

1. Generate the "Must Have" assets first using prompts from `PROFILE_PANEL_ASSETS.md`
2. Place files in the specified directories
3. Let me know when they're ready - I'll update the scene and scripts
4. Test the profile panel appearance
5. Generate remaining assets for full polish

## Quick Tips

- Use AI image generators (DALL-E, Midjourney, etc.) with the provided prompts
- Export at 2x resolution, then scale down in Godot for crisp display
- PNG format with transparency
- Match the golden/blue color scheme of existing UI buttons
