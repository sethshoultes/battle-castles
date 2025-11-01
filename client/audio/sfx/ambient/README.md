# Ambient Sound Effects

This directory contains ambient and environmental sound effects.

## Expected Files

### Battlefield Ambience
- `battlefield_quiet.ogg` - Quiet battlefield ambience (wind, distant sounds)
- `battlefield_active.ogg` - Active battle ambience (distant fighting)
- `crowd_cheer.ogg` - Crowd cheering
- `crowd_gasp.ogg` - Crowd gasping
- `crowd_murmur.ogg` - Crowd murmuring (loop)

### Environmental
- `wind_light.ogg` - Light wind (loop)
- `wind_strong.ogg` - Strong wind (loop)
- `rain_light.ogg` - Light rain (loop)
- `rain_heavy.ogg` - Heavy rain (loop)
- `thunder.ogg` - Thunder sound
- `birds_chirping.ogg` - Birds chirping (peaceful, loop)
- `crows_cawing.ogg` - Crows cawing (ominous)

### Castle/Medieval Ambience
- `castle_interior.ogg` - Castle interior ambience (echoes, distant footsteps)
- `castle_courtyard.ogg` - Castle courtyard ambience
- `torch_burning.ogg` - Torch burning (loop)
- `flag_flapping.ogg` - Flags flapping in wind (loop)
- `chains_rattling.ogg` - Chains rattling
- `drawbridge_lower.ogg` - Drawbridge lowering
- `drawbridge_raise.ogg` - Drawbridge raising

### Battle Atmosphere
- `war_drums.ogg` - War drums in distance (loop)
- `horn_battle.ogg` - Battle horn sound
- `horn_victory.ogg` - Victory horn fanfare
- `horn_retreat.ogg` - Retreat horn sound
- `battle_distant.ogg` - Distant battle sounds (loop)

### Time of Day
- `morning_ambience.ogg` - Morning ambience (birds, peaceful)
- `day_ambience.ogg` - Daytime ambience
- `evening_ambience.ogg` - Evening ambience (crickets starting)
- `night_ambience.ogg` - Night ambience (crickets, owls)

### Special Events
- `overtime_ambience.ogg` - Tense overtime atmosphere
- `victory_celebration.ogg` - Victory celebration sounds
- `defeat_ambience.ogg` - Somber defeat atmosphere

## Implementation Notes
- Most ambient sounds should loop seamlessly
- Use lower volumes for ambient sounds (typically -6 to -12 dB)
- Layer multiple ambiences for richer soundscapes
- Consider fading ambiences in/out based on game state

## File Format
- Format: OGG Vorbis (.ogg) or MP3 (.mp3)
- Duration: 30-60 seconds for looping ambiences
- Sample rate: 44.1 kHz or 48 kHz
- Ensure seamless loop points for looping sounds