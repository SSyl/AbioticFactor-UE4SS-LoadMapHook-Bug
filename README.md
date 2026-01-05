# UE4SS LoadMap Hook Bug Reproduction

Minimal reproduction case demonstrating that `RegisterLoadMapPreHook` and `RegisterLoadMapPostHook` only fire for the first mod to register them, while other lifecycle hooks (`RegisterInitGameStatePreHook`/`PostHook`) correctly fire for all registered mods.

## The Problem

When multiple Lua mods register `RegisterLoadMapPreHook` or `RegisterLoadMapPostHook`, only the first mod's callbacks are invoked. All mods report successful registration (no errors), but only one actually receives the callback. This effectively breaks any mod that relies on LoadMap hooks if another mod loads first.

## What Was Tested

- **Direct registration** - No wrapper, just calling `RegisterLoadMapPreHook`/`PostHook` directly
- **pcall wrapper** - Wrapped registration in pcall to catch silent failures (all report success)
- **ExecuteWithDelay** - Delayed registration by 1000ms, 5000ms, 10000ms (no effect)
- **Default mods enabled/disabled** - Tested with and without shipped UE4SS mods (BPModLoaderMod uses `RegisterLoadMapPostHook`)
- **Stable vs Experimental** - Bug exists in both; Experimental has additional regression where `RegisterLoadMapPostHook` doesn't fire at all when BPModLoaderMod is enabled

## Results

All 10 test mods (HookModA through HookModJ) register all 4 hooks successfully:

| Hook | Mods Registered | Mods That Fire |
|------|-----------------|----------------|
| `RegisterLoadMapPreHook` | A-J (10) | A only |
| `RegisterLoadMapPostHook` | A-J (10) | A only |
| `RegisterInitGameStatePreHook` | A-J (10) | A-J (all 10) |
| `RegisterInitGameStatePostHook` | A-J (10) | A-J (all 10) |

### Note on Data Structure

The UE4SS source stores these callbacks in vectors designed for multiple callbacks:

```cpp
static inline std::vector<LuaCallbackData> m_load_map_pre_callbacks{};
static inline std::vector<LuaCallbackData> m_load_map_post_callbacks{};
static inline std::vector<LuaCallbackData> m_init_game_state_pre_callbacks{};
static inline std::vector<LuaCallbackData> m_init_game_state_post_callbacks{};
```

All four use the same data structure, yet only InitGameState hooks correctly iterate through all callbacks.

## How to Reproduce

1. Copy `HookModA` through `HookModJ` folders into your UE4SS `Mods` directory
2. Ensure each mod has an `enabled.txt` file (included)
3. Launch the game
4. Check the UE4SS console output

**Expected:** All 10 mods print "fired!" for all 4 hook types
**Actual:** Only HookModA prints "fired!" for LoadMap hooks; all 10 print for InitGameState hooks

## Environment

- **Game:** Abiotic Factor
- **UE4SS (Nexus):** [v3.0.1-553-gc68f4f7](https://www.nexusmods.com/abioticfactor/mods/35) - experimental build shipped for Abiotic Factor
- **UE4SS (Latest Experimental):** v3.0.1-828-g83b2a4a (December 29th, 2025)
- **OS:** Windows 11 25H2

### Nexus Build Behavior
LoadMap hooks fire for the first mod to register them. With default mods enabled, BPModLoaderMod and HookModA both get their PostHook callbacks (on different map loads), but HookModB-J never fire.

### Latest Experimental Regression
On latest experimental, BPModLoaderMod (which registers `RegisterLoadMapPostHook` via mods.txt) appears to "claim" the hook, causing `RegisterLoadMapPostHook` to never fire for *any* mod - not even BPModLoaderMod itself. The PreHook still fires for HookModA only.

## Related Issues

- [Issue #346](https://github.com/UE4SS-RE/RE-UE4SS/issues/346) - Similar symptom: "all it did was change which hook actually hooked"
- [PR #776](https://github.com/UE4SS-RE/RE-UE4SS/pull/776) - Fixed crash in `RegisterLoadMapPreHook`, but multi-mod dispatch issue remains

## Tools (Optional)

The `/tools` folder contains a PowerShell script to regenerate the test mods:

```powershell
cd tools
.\generate_mods.ps1
```

This is optional - the pre-generated mods are ready to use.
