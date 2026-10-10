<p align="center">
  <img src="MirrasComboPoints_CurseForge_Icon.png" alt="Mirra's Combo Points logo" width="200">
</p>

# Mirra's Combo Points

Shows your combo points on your target's nameplate. A lightweight addon for **WoW Forever**.

## Features

- Combo points above or below your target's health bar
- Round or square pips
- Adjustable size, spacing, opacity and position
- Gradient or single color
- Custom color when all points are full
- Custom color for empty slots
- Option to hide at 0 combo points
- Live preview in the settings
- Settings under *Options → AddOns → Mirra's Combo Points*

## Installation

Copy the `MirrasComboPoints` folder into your WoW Forever `Interface/AddOns` directory.

Enemy nameplates must be enabled (default key: **V**).

## Commands

| Command | Description |
| --- | --- |
| `/mcp` | Open settings |
| `/mcp size <4-40>` | Pip size |
| `/mcp spacing <0-20>` | Spacing between pips |
| `/mcp x <n>` / `/mcp y <n>` | Position offset |
| `/mcp top` / `/mcp bottom` | Above or below the health bar |
| `/mcp empty` | Toggle hiding at 0 combo points |
| `/mcp slots` | Toggle empty slots |
| `/mcp reset` | Restore defaults |
| `/mcp debug` | Print diagnostics |

`/mirrascombopoints` works as an alternative to `/mcp`.

## Known issues

- The WoW Forever Beta client currently does not load saved settings after a reload or relog. This is a client issue, not an addon issue.
- Only tested with the default Blizzard nameplates.

## Author

Kekshaus
