# Investigación y procedencia

Investigación realizada el 24 de septiembre de 2026. Se priorizaron repositorios oficiales, releases originales y código con licencia visible.

## Build local

| Archivo | Tamaño | Versión | SHA-256 |
|---|---:|---|---|
| `KINGDOM HEARTS FINAL MIX.exe` | 7.490.832 | 1.0.0.1 | `D790746245D26159F3EE0E1060E33B2FA2DE06941850A4AC724F598722884BAC` |
| `KINGDOM HEARTS II FINAL MIX.exe` | 8.659.216 | 1.0.0.2 | `9002B2DE6A1F91A790BD0673DE125D1CF833F7942BFEC827CDCF6BA64D5849ED` |
| `KINGDOM HEARTS Birth by Sleep FINAL MIX.exe` | 9.346.320 | 1.0.0.1 | `375A811243F1F95F786F00318E2E1210DD5881B25BBF0912A0AD8F81650C976C` |
| `KINGDOM HEARTS Re_Chain of Memories.exe` | 9.665.808 | 1.0.0.1 | `ACF42E96A168C73301F5C2CC2915D07E6C420F56A59C6286655C970BFEE36BBF` |

Los cuatro hashes están autorizados únicamente para su módulo y todos vuelven a comprobar `GAME_ID`, fingerprint y valores vivos antes de escribir.

## Fuentes principales

- [Sirius902/LuaBackend](https://github.com/Sirius902/LuaBackend), GPL-3.0, commit observado `11258d39db6df01e9534cca02e12360ee1f95fcd`. Se siguió su instalación Steam mediante el hook `DBGHELP.dll`, configuración TOML y ruta absoluta de scripts.
- [Release v1.9.1-hook de LuaBackend](https://github.com/Sirius902/LuaBackend/releases/tag/v1.9.1-hook), publicada el 22 de agosto de 2025. Asset oficial `DBGHELP.zip`: SHA-256 publicado por GitHub `61889ff6f7af080d9f65db8c5ded8e3521311999aaa23e2b62d9cf172d818fd0`; DLL extraído: `224474E2333776627E39EB715B2EDC9AF521940C9254B8280B7D286BEA646E39`.
- [OpenKH/OpenKh](https://github.com/OpenKH/OpenKh), Apache-2.0, commit observado `7a3b945c538d32c6a285128c98aefba093f52ceb`. Referencia de formatos y ecosistema; no se necesitó instalar OpenKH Mods Manager.
- [Denhonator/KHPCSpeedrunTools](https://github.com/Denhonator/KHPCSpeedrunTools), Unlicense, commit `fb5e4aae160835e7051d7500d7a76f8cd8171c73`. Aporta detección Steam Global 1.0.0.1 (`GAME_ID 0xAF71841E`, byte `0x469872 == 106`) y el mapa de direcciones actual. Su manejo del multiplicador nativo de EXP y accesorios permitió implementar el mecanismo sin sobrescribir EXP total.
- [mattfabius/KHPCStatInventoryModifier](https://github.com/mattfabius/KHPCStatInventoryModifier), MIT, commit `b3e9eaf`. Confirma la disposición relativa antigua entre el bloque de estadísticas y Munny. La dirección actual se obtuvo trasladando ese delta a la tabla Steam actual; por eso Munny permanece marcado Experimental.
- [Actualización Steam publicada por pfjarschel](https://pastebin.com/V64WYT8Y), enlazada desde los comentarios de Nexus el 16 de agosto de 2026 y confirmada allí en Windows. Identifica el offset Steam `+0x3A3F96`, Sora en `0x2DE9364` y Munny en `0x2DFF77C`; estos hechos coinciden con la derivación independiente. No se incorporó el script de edición de inventario.
- [Keralin/kh1fm-autosave](https://github.com/Keralin/kh1fm-autosave), Unlicense, commit `d0fdde8eed4579e8b1e8ba2f441e5c36419b3096`. Confirma separación por paquetes de versión y los riesgos de escribir contenedores de guardado. No se incorporó autosave ni save-anywhere.
- [Critical Mix Additions](https://github.com/Drflash55/KH1-Critical-Mix-Additions) y [Extras](https://github.com/Drflash55/KH1-Critical-Mix-Additions-Extras), AGPL-3.0, commits observados `f705c7c0...` y `d578...`. No se copió código AGPL; sólo se contrastaron hechos de direcciones con otras tablas.
- [100 Drop Rate en Nexus Mods](https://www.nexusmods.com/kingdomheartsfinalmix/mods/238), versión 2.0 observada (11 de septiembre de 2026). El autor no permite reutilizar/modificar/publicar el archivo; no se descargó ni incorporó su código. El control de drops queda deshabilitado hasta disponer de un mecanismo independiente y verificable.
- [KH2-Lua-Library](https://github.com/TopazTK/KH2-Lua-Library), GPL-3.0. Su tabla Steam Global vigente confirma `Save=0x09A9830`, `Btl0Pointer=0x2AE5DD8` y `Slot1=0x2A23518`. El código del proyecto no incorpora la biblioteca; las direcciones se aislaron y se volvieron a validar contra el EXE local.
- [KH-RECOM-AP-LUA](https://github.com/gaithernOrg/KH-RECOM-AP-LUA) y [KH-BBS-AP-LUA](https://github.com/gaithernOrg/KH-BBS-AP-LUA), usados sólo como referencia de hechos técnicos. Confirmaron la tabla Re:CoM `0x7C2C78`, la tabla BBS `0x649604` y la cadena de HP de BBS. No se copió su integración Archipelago.
- [BBS-All-Commands-Shop](https://github.com/Denhonator/BBS-All-Commands-Shop), MIT, contrastó la detección de la build BBS actual.
- [HydroSulphide/KH1FM-Memory-Map](https://github.com/HydroSulphide/KH1FM-Memory-Map), GPL-3.0, commit observado `ff7789a4e44a1b55826104e49964d40c876cb913`; wiki commit `5a5fc55fcff1dd853714bb2b42715872e34e4029`. Confirma el pool de entidades y el layout de estadísticas de campo. Su dirección de código `on_get_hit` corresponde a otra revisión y se descartó tras contrastarla con el EXE local.
- Una tabla histórica de Cheat Engine para Re:CoM se usó exclusivamente como pista de ingeniería inversa. El patrón se buscó de nuevo en el EXE local y se desensambló: la instrucción actual resuelve los punteros globales `0x87B390` (batalla) y `0x87CBF8` (estado), con HP `+0x42C/+0x430`, EXP `+0x440` y puntos Moguri `+0x448`. No se ejecutó Cheat Engine ni se incorporó la tabla al runtime.

## Hallazgos técnicos usados

- EXP usa el float nativo `0x2D5CB00`. El juego ya consulta ese valor al conceder EXP. Se reconstruye el bonus de accesorios (1,0 base, +0,2/+0,3 según el accesorio) y se multiplica por la opción del usuario.
- Munny no ofrece un multiplicador nativo documentado. La ubicación `0x2DFF77C` se derivó por delta estructural y se cruzó con la actualización Steam de agosto de 2026; se protege con rangos, estado jugable, detección de incrementos y límite 99.999. No se multiplica continuamente el total.
- HP/MP actuales de runtime y máximos se contrastaron entre mapas contemporáneos. Las opciones infinitas nunca alteran HP/MP máximos.
- La velocidad base observada por las tablas Steam es 8,0 en `0x2D5CB18`; se limita a 0,5–2x y no se toca en Vanilla salvo para restaurar una modificación previa.
- KH2 usa la tabla Sora de `Btl0+0x25928` (99 entradas, stride `0x10`). El runtime conserva una copia original y divide los requisitos por el multiplicador; `1x` restaura exactamente esa copia. Munny está en `Save+0x2440`; HP/MP actuales y máximos están en `Slot1`.
- BBS usa 99 requisitos consecutivos en `0x649604`; el primer valor de esta build es 90. EXP, Munny y nivel viven en el bloque de personaje `0x10FA6240`. HP se obtiene por la cadena `0x10F9EE40 → +0x118 → +0x398 → +0xA0/+0xA4`.
- Re:CoM usa siete constantes de cálculo de gemas EXP en `0x7C2C78` con valores Vanilla `1400, 99, 60, 30, 10, 5, 1`. Los puntos Moguri y HP se leen del bloque de batalla resuelto por `0x87B390`.

## Drops: viabilidad de un multiplicador parcial

- La especificación primaria de OpenKH para KH2 documenta `PRZT` dentro de `00battle`: 184 entradas, cada una con tres IDs y tres porcentajes `int16`. Esto permite multiplicar cada probabilidad original y saturarla en 100 %, conservando la tabla de objetos.
- OpenKH documenta en BBS `PRIZEBOXDATA` (`Percent Rate`) y los parámetros `EPD` (`Probability`) por enemigo. El mecanismo también admite porcentajes parciales; no obliga a usar 100 %.
- Esos datos son archivos/recursos cargados por el juego. Para respetar la prohibición de parche permanente todavía falta identificar, autenticar y restaurar sus copias en memoria en esta build. Por esa razón la GUI sigue bloqueando drops.
- Re:CoM separa drops de cartas enemigas, cartas de mapa y llaves. Se encontraron mods de 100 %, pero no una estructura runtime abierta y licenciada que permita asegurar un multiplicador común sin alterar reglas especiales.

## Decisiones de licencia y confianza

El proyecto contiene código propio. LuaBackend se distribuye sin modificar desde su release oficial y conserva su licencia upstream. Las fuentes Unlicense/MIT se usaron como referencia técnica; las fuentes con permisos restrictivos o copyleft incompatible no se copiaron. Direcciones duras están aisladas en `version.lua`, ligadas al hash exacto y acompañadas por fingerprint y comprobaciones de estado.

La auditoría de opciones todavía no implementadas (daño, HP de enemigos y bosses, one-hit, salto, guardado y texto) está en [`FEATURE_RESEARCH.md`](FEATURE_RESEARCH.md). El plan de empaquetado y publicación futura está en [`FUTURE_NEXUS_RELEASE.md`](FUTURE_NEXUS_RELEASE.md).

## Corrección KH1 (25-09-2026)

- El EXE local **no** es la build `SteamGlobal_1_0_0_1` de KHPCSpeedrunTools (en `0x469872` no hay `106`), sino `SteamGlobal_1_0_0_2` (`0x4698D2 = "japanese"`, `beepHack 0x26E20C = 9`). La mayoría de direcciones usadas coinciden entre ambas, salvo `soraStats` (usado antes para recalcular accesorios de EXP), que ya no se usa.
- Drops, EXP, Munny y radio de recogida se localizaron por desensamblado propio del EXE (capstone), sin usar código de terceros: función de bonificaciones `0x2A6380`, spawn de premios `0x2AB940`/`0x2ABC40`, recogida de orbes `0x2AC080`/`0x2AB420`, AddMunny `0x2E7E10`. Detalles y firmas en `TECHNICAL.md` y `scripts/kh1/io_packages/kh_qol/version.lua`.
- Fórmula de Lucky Strike (1 + 0,5·n) contrastada con [KH Wiki: Lucky Strike](https://www.khwiki.com/Lucky_Strike).
- Pruebas: [lupa](https://pypi.org/project/lupa/) 2.8 (MIT, Lua 5.4 embebido) instalado en `research/pydeps` sólo para el arnés offline; no se carga en el juego.
