# Hull Breaker — Subnautica 2 Mod

> **Break through the limit.** Stack multiple Strike Armors (Hull Reinforcements) on your Tadpole.

## Quick Start

1. Copy the `SN2HullBreaker` folder into your game's UE4SS Mods folder:

   ```
   Steam\steamapps\common\Subnautica2\Subnautica2\Binaries\Win64\ue4ss\Mods\
   ```

2. Open `mods.txt` (in that same `Mods` folder) and add this line before `; Built-in keybinds`:

   ```
   SN2HullBreaker : 1
   ```

3. Launch the game. Done!

## Usage

- Deploy a **Tadpole** in the world
- Open your inventory and drag **Strike urs** onto the Tadpole's upgrade slots
- You can now place **multiple Strike Armors** — fill all 4 slots if you want
- The mod auto-patches every Tadpole, including newly built ones

> **Note:** The Tadpole must be deployed in the world (not docked) for the mod to patch it. If it doesn't work immediately, wait 30 seconds or undock and redock the Tadpole.

## Requirements

- Subnautica 2
- [UE4SS](https://www.nexusmods.com/subnautica2/mods/36) v3.0.1 or later

## Uninstall

1. Remove `SN2HullBreaker : 1` from `mods.txt` (or change to `: 0`)
2. Delete the `SN2HullBreaker` folder

Your saves are not affected.

---

## Configuration

Open `Scripts\main.lua` and edit the `Config` table at the top:

| Setting | Default | Description |
|---------|---------|-------------|
| `AllowMultipleUnique` | `true` | Allow duplicate unique upgrades (the main fix) |
| `MaxItems` | `nil` | Override number of upgrade slots (default: 4, `nil` = unchanged) |
| `LogLevel` | `1` | `0` = silent, `1` = normal, `2` = verbose |

## Console Commands

Use the UE4SS debug console (`~` key) or any console enabler mod:

| Command | Description |
|---------|-------------|
| `HB_Patch` | Manually patch all Tadpoles in the world |
| `HB_Status` | Show current upgrade inventory state of all Tadpoles |
| `HB_Info` | Show mod version and configuration |

## How It Works

The Tadpole's upgrade inventory uses `UWEInventoryComponent` with a property `bAllowMultipleUnique` set to `false` by default. This prevents placing duplicate unique items like Strike Armor. The mod sets it to `true` on every Tadpole's `UpgradeInventoryComponent`, removing the restriction.

## Compatibility

- Works with other UE4SS mods
- Does not modify any game files
- Runtime-only change — reverts if the mod is removed

## Known Issues

- The damage reduction effect of Strike Armor may or may not stack — this depends on the game's internal systems, not the inventory restriction. This mod only removes the **placement** blocker.
- The mod re-patches automatically every time the game loads.

## Credits

- Built with [UE4SS](https://github.com/Subnautica2Modding/Subnautica2-UE4SS) by the Subnautica 2 Modding community
