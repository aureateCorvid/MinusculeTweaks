# Minuscule Tweaks

A small collection of quality-of-life UI improvements for World of Warcraft 3.3.5a (Interface 30300).

Each feature can be toggled individually from the **AddOns** tab of the Interface options. All features are enabled by default. Changes take effect after a UI reload (a Reload UI button is provided in the options panel).

## Features

### Chat Edit Fix
Makes the chat input box behave like a normal text editor:
- Arrow keys move the cursor
- Shift + Arrow selects text
- Ctrl + Arrow jumps between words
- Remembers the last message sent

### Class Color Frames
Colors name backgrounds (or the name text where no background exists) by class on:
- Player frame
- Target frame
- Focus frame
- Party frames
- Target of Target / Focus of Target

### Custom Status Text
Adjusts health and power text on unit frames:
- **Player & Target**: Current value and percentage (`12345 (87%)`)
- **Party, Pet & Focus**: Percentage only (`87%`)
- Special handling for dead and ghost states (including a custom "Ghost" text)

### Spec Tooltip
Inserts the primary talent specialization into player tooltips.  
Format: `Level [Number] [Race] [Spec] [Class] (Player)`  
Tied specs are shown as `Spec1/Spec2`.

## Installation
1. Download the release.
2. Extract the `MinusculeTweaks` folder into your `Interface/AddOns/` directory.
3. Reload the UI or restart the game.

## Configuration
Open the Interface options (`Esc` → Interface), switch to the **AddOns** tab, and select **Minuscule Tweaks**.

## Credits
Created by **Grok**.

## License
MIT License. See [LICENSE](LICENSE) for details.
