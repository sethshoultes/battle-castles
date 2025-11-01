# Music Directory

This directory contains all background music tracks for Battle Castles.

## Expected Files

### Menu Music
- `menu_theme.ogg` - Main menu background music
- `settings_theme.ogg` - Settings menu music (optional)

### Battle Music
- `battle_intro.ogg` - Battle introduction (non-looping, ~5-10 seconds)
- `battle_main.ogg` - Main battle theme (looping)
- `battle_overtime.ogg` - Overtime/sudden death theme (looping, intense)

### Battle Music Layers (for dynamic intensity)
- `battle_main_drums.ogg` - Drum layer
- `battle_main_bass.ogg` - Bass layer
- `battle_main_melody.ogg` - Melody layer
- `battle_main_harmony.ogg` - Harmony layer
- `battle_overtime_drums.ogg` - Overtime drum layer
- `battle_overtime_bass.ogg` - Overtime bass layer
- `battle_overtime_melody.ogg` - Overtime melody layer
- `battle_overtime_harmony.ogg` - Overtime harmony layer
- `battle_overtime_tension.ogg` - Additional tension layer

### Victory/Defeat Music
- `victory_fanfare.ogg` - Victory celebration (non-looping, ~5-10 seconds)
- `defeat_theme.ogg` - Defeat music (non-looping, ~5-10 seconds)
- `results_screen.ogg` - Results/stats screen music (looping)

### Transition Stingers (optional)
- `stinger_menu_to_battle_intro.ogg` - Menu to battle transition
- `stinger_battle_main_to_battle_overtime.ogg` - Normal to overtime transition
- `stinger_battle_main_to_victory.ogg` - Battle to victory transition
- `stinger_battle_main_to_defeat.ogg` - Battle to defeat transition

## File Format Requirements
- **Preferred format**: OGG Vorbis (.ogg)
- **Alternative formats**: MP3 (.mp3)
- **Sample rate**: 44.1 kHz or 48 kHz
- **Bit depth**: 16-bit
- **Channels**: Stereo

## Looping
Files that need to loop should have seamless loop points. Use Godot's import settings to configure loop points if needed.

## Volume Guidelines
- Music should be mastered to approximately -12 dB RMS
- Leave headroom for in-game volume adjustments
- Ensure consistent volume across all tracks