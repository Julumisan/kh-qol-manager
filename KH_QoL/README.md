# KH QoL Manager 0.1.0-beta

Grind-reducer and quality-of-life options for **KINGDOM HEARTS HD 1.5+2.5 ReMIX (Steam)**, with a small settings window. Nothing is patched on disk and your saves are never modified: the options live in game memory through [LuaBackend](https://github.com/Sirius902/LuaBackend) and are undone when set back to 1x.

[Español más abajo](#español)

## Install

1. Extract the ZIP **into the game folder** (the one with `KINGDOM HEARTS FINAL MIX.exe`).
2. Double-click `KH_QoL_Manager.cmd`.
3. Press **Install / repair**. This downloads the official LuaBackend `v1.9.1-hook` release from GitHub and checks its SHA-256 before using it.
4. Pick your options, press **Save all** (or **Save and open Steam**) and play. You only need the manager again to change something.

The window follows your Windows language; switch English/Español in the top-right corner.

## Options

**Kingdom Hearts Final Mix** — EXP, munny (orb value), optional shop-sale multiplier, item drop chance (capped at 100 %, original loot tables), orb pickup radius and automatic pickup, infinite HP/MP, movement speed (Sora, party and gliding), jump height, max HP/MP, enemy HP (bosses included), instant dialogue box transitions, and instant Gummi travel (Warp Drive for worlds you have already flown to; the first trip is still required).

**KH II Final Mix, Birth by Sleep, Re:Chain of Memories** — EXP, munny/moogle points, infinite HP (and MP in KH II). **Beta:** not tested in play yet; they start in Vanilla.

Presets: *Vanilla*, *Light QoL*, *Dad Mode* (EXP ×2, munny ×3, drops ×3, pickup ×3, speed ×1.5, instant dialogue transitions; combat untouched) and *Chaos / Sandbox*.

## Safety

- Works only with the exact Steam game versions it knows (checked by SHA-256 and code signatures). After a game update the affected game is left untouched until the mod is updated.
- No game file, Steam file or save is modified. Settings are undone at 1x without restarting.
- **Uninstall hook** removes only the LuaBackend files it installed. `Uninstall_KH_QoL.cmd` removes everything; saves and other mods are not touched.
- Another mod already using `DBGHELP.dll` is detected and left alone.

## Troubleshooting

- *LuaBackend not installed*: press **Install / repair**. Without internet, download `DBGHELP.zip` from the LuaBackend `v1.9.1-hook` release and put it in `KH_QoL\vendor\LuaBackend-v1.9.1-hook\`.
- *Unsupported game version*: the game was updated; wait for a mod update.
- Logs: `KH_QoL\logs`. In game, **F2** opens the LuaBackend console and **F1** reloads the scripts.

When reporting a problem, include the game, the options you used, what happened and the matching `KH_QoL\logs\*-runtime.log`.

---

## Español

Opciones para reducir el grindeo y de comodidad para **KINGDOM HEARTS HD 1.5+2.5 ReMIX (Steam)**, con una ventana de configuración. No se parchea nada en disco ni se modifican tus partidas: las opciones actúan en memoria mediante LuaBackend y se deshacen al volver a 1x.

1. Descomprime el ZIP **en la carpeta del juego** (donde está `KINGDOM HEARTS FINAL MIX.exe`).
2. Abre `KH_QoL_Manager.cmd`.
3. Pulsa **Instalar / reparar**: descarga la release oficial de LuaBackend `v1.9.1-hook` desde GitHub y comprueba su SHA-256.
4. Elige tus opciones, pulsa **Guardar todos** (o **Guardar y abrir Steam**) y juega.

El idioma sigue al de Windows y se puede cambiar arriba a la derecha. KH II, Birth by Sleep y Re:Chain of Memories están en **beta** (sin probar en partida; empiezan en Vanilla). Desinstalación: **Desinstalar hook** o `Uninstall_KH_QoL.cmd`; no se tocan partidas ni otros mods.

## License

MIT (see `LICENSE`). LuaBackend is GPL-3.0 and is downloaded from its official release, not included in this package (see `THIRD_PARTY_NOTICES.md`).
