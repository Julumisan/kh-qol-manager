# Nexus Mods page — KH QoL Manager 0.1.0-beta

Copy the fields below into the Nexus page (Kingdom Hearts Final Mix section is the natural home; mention the other games in the description). The description uses Nexus BBCode.

## Fields

- **Name:** KH QoL Manager - Grind Reducer and Quality of Life (Steam)
- **Version:** 0.1.0-beta
- **Category:** Gameplay (or Utilities)
- **Short summary (≤ 350 chars):** One-click settings window for KINGDOM HEARTS HD 1.5+2.5 ReMIX (Steam): EXP, munny and drop multipliers, pickup radius, movement speed, jump, max HP/MP, enemy HP, infinite HP/MP, instant dialogue transitions and more. Nothing patched on disk, saves untouched, English/Spanish.
- **Requirements:** LuaBackend v1.9.1-hook (installed automatically by the manager from its official GitHub release).
- **Permissions:** MIT for the manager and scripts. LuaBackend is not included.
- **AI tag:** Nexus asks authors to tag generative-AI use. Suggested disclosure (edit as you see fit): *"Developed with the help of AI coding assistants; every Kingdom Hearts Final Mix option was tested in game."* Do not submit to the 25th-anniversary event (its rules forbid AI).
- **Images:** `KH_QoL_Manager_en.png` (settings window).

## Description (BBCode)

```
[size=5][b]KH QoL Manager[/b][/size]
Grind reducer and quality-of-life options for [b]KINGDOM HEARTS HD 1.5+2.5 ReMIX (Steam)[/b], with a small settings window in English and Spanish.

Nothing is patched on disk and your saves are never modified: every option works in game memory through LuaBackend and is undone as soon as you set it back to 1x.

[size=4][b]Kingdom Hearts Final Mix[/b][/size]
[list]
[*]EXP multiplier
[*]Munny multiplier (value of munny orbs) and optional shop-sale multiplier
[*]Item drop chance multiplier - each enemy keeps its own loot table, capped at 100%
[*]Orb pickup radius and automatic pickup
[*]Movement speed for Sora, party members and gliding
[*]Jump height, max HP, max MP
[*]Enemy HP (bosses included)
[*]Infinite HP / infinite MP
[*]Instant dialogue box transitions
[*]Instant Gummi travel: Warp Drive to worlds you have already flown to (the first trip to each world is still required)
[/list]

[size=4][b]KH II Final Mix, Birth by Sleep, Re:Chain of Memories (beta)[/b][/size]
EXP, munny / moogle points and infinite HP (plus MP in KH II). Not tested in play yet - they start in Vanilla.

[size=4][b]Presets[/b][/size]
Vanilla, Light QoL, [b]Dad Mode[/b] (EXP x2, munny x3, drops x3, pickup x3, speed x1.5, instant dialogue transitions - combat untouched) and Chaos / Sandbox. Each game has its own tab and preset.

[size=4][b]Installation[/b][/size]
[list=1]
[*]Extract the archive into the game folder (where KINGDOM HEARTS FINAL MIX.exe is).
[*]Run [b]KH_QoL_Manager.cmd[/b].
[*]Press [b]Install / repair[/b] - it downloads the official LuaBackend v1.9.1-hook release and checks its SHA-256.
[*]Choose your options, press [b]Save all[/b] and play from Steam as usual.
[/list]

[size=4][b]Safety[/b][/size]
[list]
[*]Only works with the exact Steam game versions it knows (SHA-256 + code signatures). After a game update, the updated game is left untouched until the mod is updated.
[*]No game files, Steam files or saves are modified.
[*]If another mod already uses DBGHELP.dll, it is detected and left alone.
[*]Uninstall: [b]Uninstall hook[/b] in the manager, or Uninstall_KH_QoL.cmd to remove everything. Saves and other mods are not touched.
[/list]

[size=4][b]Compatibility[/b][/size]
Steam version of KINGDOM HEARTS HD 1.5+2.5 ReMIX on Windows. Epic Games and other versions are not supported. Other LuaBackend scripts can coexist, but using two mods that change the same thing is not recommended.

[size=4][b]Reporting problems[/b][/size]
Please include: the game, the options you used, what happened, and the matching log from KH_QoL\logs (*-runtime.log).

[size=4][b]Credits[/b][/size]
LuaBackend by Sirius902 (GPL-3.0, downloaded from its official release). Technical references: Denhonator's KHPCSpeedrunTools, OpenKH, TopazTK's KH2-Lua-Library, gaithernOrg's Archipelago Lua scripts, mattfabius's KHPCStatInventoryModifier. KINGDOM HEARTS is a trademark of Disney and Square Enix; this mod is not affiliated with them.
```

## Upload checklist

1. Run the tests (see `TEST_PLAN.md`) and `KH_QoL\tools\Build-Release.ps1`.
2. Upload `KH_QoL\dist\KH_QoL_Manager_0.1.0-beta.zip` as the main file (version 0.1.0-beta).
3. Paste the fields and description, add the image, set the AI tag, preview, publish.
