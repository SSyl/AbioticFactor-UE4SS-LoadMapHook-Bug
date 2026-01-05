# UE4SS LoadMap Hook Bug Reproduction

Minimal reproduction case demonstrating that `RegisterLoadMapPreHook` and `RegisterLoadMapPostHook` only fire for the first mod to register them, while other lifecycle hooks (`RegisterInitGameStatePreHook`/`PostHook`) correctly fire for all registered mods.

## The Problem

When multiple Lua mods register `RegisterLoadMapPreHook` or `RegisterLoadMapPostHook`, only the first mod's callbacks are invoked. All mods report successful registration (no errors), but only one actually receives the callback. This effectively breaks any mod that relies on LoadMap hooks if another mod loads first.

## What Was Tested

- **Direct registration** - No wrapper, just calling `RegisterLoadMapPreHook`/`PostHook` directly
- **pcall wrapper** - Wrapped registration in pcall to catch silent failures (all report success)
- **ExecuteWithDelay** - Delayed registration by 1000ms, 5000ms, 10000ms (no effect)
- **Default mods enabled/disabled** - Tested with and without shipped UE4SS mods (BPModLoaderMod uses `RegisterLoadMapPostHook`)
- **NexusMods Version vs Latest Experimental** - Bug exists in both; Experimental has additional regression where `RegisterLoadMapPostHook` doesn't fire at all when BPModLoaderMod is enabled

## Results

All 10 test mods (HookModA through HookModJ) register all 4 hooks successfully:

| Hook | Mods Registered | Mods That Fire |
|------|-----------------|----------------|
| `RegisterLoadMapPreHook` | A-J (10) | A only |
| `RegisterLoadMapPostHook` | A-J (10) | A only |
| `RegisterInitGameStatePreHook` | A-J (10) | A-J (all 10) |
| `RegisterInitGameStatePostHook` | A-J (10) | A-J (all 10) |

## How to Reproduce

1. Copy `HookModA` through `HookModJ` folders into your UE4SS `Mods` directory
2. Ensure each mod has an `enabled.txt` file (included)
3. Launch the game
4. Check the UE4SS console output

**Expected:** All 10 mods print "fired!" for all 4 hook types
**Actual:** Only HookModA prints "fired!" for LoadMap hooks; all 10 print for InitGameState hooks

## Sample Output

```
[Lua] [Hook Mod A] Loading...
[Lua] [Hook Mod A] RegisterLoadMapPreHook pcall success
[Lua] [Hook Mod A] RegisterLoadMapPostHook pcall success
[Lua] [Hook Mod A] RegisterInitGameStatePreHook pcall success
[Lua] [Hook Mod A] RegisterInitGameStatePostHook pcall success
[Lua] [Hook Mod A] Mod loaded
...
[Lua] [Hook Mod J] Loading...
[Lua] [Hook Mod J] RegisterLoadMapPreHook pcall success
[Lua] [Hook Mod J] RegisterLoadMapPostHook pcall success
[Lua] [Hook Mod J] RegisterInitGameStatePreHook pcall success
[Lua] [Hook Mod J] RegisterInitGameStatePostHook pcall success
[Lua] [Hook Mod J] Mod loaded

[Lua] [Hook Mod A] RegisterLoadMapPreHook fired!        <-- Only A fires

[Lua] [Hook Mod A] RegisterInitGameStatePreHook fired!  <-- All 10 fire
[Lua] [Hook Mod B] RegisterInitGameStatePreHook fired!
[Lua] [Hook Mod C] RegisterInitGameStatePreHook fired!
[Lua] [Hook Mod D] RegisterInitGameStatePreHook fired!
[Lua] [Hook Mod E] RegisterInitGameStatePreHook fired!
[Lua] [Hook Mod F] RegisterInitGameStatePreHook fired!
[Lua] [Hook Mod G] RegisterInitGameStatePreHook fired!
[Lua] [Hook Mod H] RegisterInitGameStatePreHook fired!
[Lua] [Hook Mod I] RegisterInitGameStatePreHook fired!
[Lua] [Hook Mod J] RegisterInitGameStatePreHook fired!
[Lua] [Hook Mod A] RegisterInitGameStatePostHook fired!
[Lua] [Hook Mod B] RegisterInitGameStatePostHook fired!
[Lua] [Hook Mod C] RegisterInitGameStatePostHook fired!
[Lua] [Hook Mod D] RegisterInitGameStatePostHook fired!
[Lua] [Hook Mod E] RegisterInitGameStatePostHook fired!
[Lua] [Hook Mod F] RegisterInitGameStatePostHook fired!
[Lua] [Hook Mod G] RegisterInitGameStatePostHook fired!
[Lua] [Hook Mod H] RegisterInitGameStatePostHook fired!
[Lua] [Hook Mod I] RegisterInitGameStatePostHook fired!
[Lua] [Hook Mod J] RegisterInitGameStatePostHook fired!

[Lua] [Hook Mod A] RegisterLoadMapPostHook fired!       <-- Only A fires
```

## Environment

- **Game:** Abiotic Factor v1.2.0
- **UE4SS (Nexus):** [v3.0.1-553-gc68f4f7](https://www.nexusmods.com/abioticfactor/mods/35)
- **UE4SS (Latest Experimental):** v3.0.1-828-g83b2a4a (December 29th, 2025)
- **OS:** Windows 11 25H2

### Nexus Release Behavior
LoadMap hooks fire for the first mod to register them. With default mods enabled, BPModLoaderMod and HookModA both get their PostHook callbacks (on different map loads), but HookModB-J never fire.

### Latest Experimental Regression
On latest experimental, BPModLoaderMod (which registers `RegisterLoadMapPostHook` via mods.txt) appears to "claim" the hook, causing `RegisterLoadMapPostHook` to never fire for *any* mod - not even BPModLoaderMod itself. The PreHook still fires for HookModA only.

## Tools (Optional)

The `/tools` folder contains a PowerShell script to regenerate the test mods:

Edit template.lua with whatever code changes you want (leave the modName variable as `"[{{MOD_NAME}}] "`).
Want to try it without pre hooks? Or without the game state hooks? No pcalls? Just edit the template.lua file and run the script as follows:

```powershell
cd tools
.\generate_mods.ps1
```

This is optional - the pre-generated mods are ready to use.
