# Third-party notices

## LuaBackend v1.9.1-hook (not included)

- Project: https://github.com/Sirius902/LuaBackend — license GPL-3.0.
- This package does **not** contain LuaBackend. On **Install / repair**, the manager downloads the unmodified official release asset
  `https://github.com/Sirius902/LuaBackend/releases/download/v1.9.1-hook/DBGHELP.zip` and only uses it if it matches:
  - `DBGHELP.zip` SHA-256 `61889FF6F7AF080D9F65DB8C5DED8E3521311999AAA23E2B62D9CF172D818FD0`
  - `DBGHELP.dll` SHA-256 `224474E2333776627E39EB715B2EDC9AF521940C9254B8280B7D286BEA646E39`
- LuaBackend's source code and license are available from its repository.

## Technical references

The Lua scripts and the manager are original code. Game addresses were derived from our own disassembly of the Steam executables and cross-checked with public research, credited here:

- Denhonator / KHPCSpeedrunTools (Unlicense) — Steam version markers and address tables.
- OpenKH (Apache-2.0) — file format documentation.
- TopazTK / KH2-Lua-Library (GPL-3.0) — KH II address reference (no code included).
- gaithernOrg / KH-RECOM-AP-LUA and KH-BBS-AP-LUA — Re:CoM and BBS address references (no code included).
- mattfabius / KHPCStatInventoryModifier (MIT) — KH1 data layout reference.

No code, assets or tables from mods with restrictive permissions are included.

KINGDOM HEARTS is a trademark of Disney and Square Enix. Not affiliated or endorsed.
