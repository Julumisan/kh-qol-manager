# Relevo del proyecto (Codex ⇄ Claude)

Última actualización: **26-09-2026** (sesión de Claude: limpieza para publicar).

Este documento es el punto de entrada para quien retome el proyecto, sea Codex, Claude o una persona. Codex y Claude trabajan en esto **como compañeros, con un poco de competición sana**: cada uno revisa el trabajo del otro, corrige sin dramas y deja todo documentado para que el siguiente no tenga que redescubrirlo. El usuario decide; nosotros proponemos, verificamos y dejamos constancia.

## 1. Estado en una pantalla

| | |
|---|---|
| Juego principal | KH1 Final Mix, Steam, SHA `D790746245D26159F3EE0E1060E33B2FA2DE06941850A4AC724F598722884BAC` (tabla `SteamGlobal_1_0_0_2`) |
| Hook | LuaBackend `v1.9.1-hook` (`DBGHELP.dll` oficial, verificado por hash) |
| Preset del usuario | **Dad Mode** (KH1): EXP ×2, munny ×3, drops ×3, radio ×3, velocidad ×1,5 (Sora, compañeros y planeo), transiciones de diálogo instantáneas. Ventas en tienda, viaje Gummi, HP/MP infinitos: desactivados |
| Saves | Perfil **Partida** activo (contenedor limpio; el usuario empieza su partida real). En **Pruebas** están los saves de nivel 100 convertidos desde Reddit |
| Pruebas | Arnés Lua 90/90 · gestor 38/38 · perfiles 12/12 · estáticas sin fallos |
| GUI | Cada pestaña muestra sólo lo implementado; lo retirado está en `FEATURE_RESEARCH.md` ("Decisión para publicar") |

### Matriz de verificación

| Función | KH1 | KH2 | BBS | Re:CoM |
|---|---|---|---|---|
| EXP | **Verificado** en memoria (nivel 100: EXP al tope) | Sin verificar | Sin verificar | Sin verificar |
| Moneda | **Verificado** | Sin verificar; multiplica ventas | Ídem | Ídem |
| Ventas opcionales | **Verificado** | No separado | No separado | No separado |
| Drops | **Verificado** | No disponible | No disponible | No disponible |
| Radio / recogida automática | **Verificado** | No disponible | No disponible | No disponible |
| HP infinito | **Verificado** | Sin verificar | Sin verificar | Sin verificar |
| MP infinito | **Verificado** (corregido) | Sin verificar | N/A (Focus) | N/A |
| Velocidad + planeo | **Verificado** (Sora, compañeros y planeo) | No disponible | No disponible | No disponible |
| Transiciones de diálogo | **Verificado** | — | — | — |
| Viaje Gummi instantáneo | Pendiente (save de pruebas ya con Warp-G) | — | — | — |
| Salto | **Verificado** | — | — | — |
| HP/MP máximo | **Verificado** | — | — | — |
| HP de enemigos (incl. jefes) | **Verificado** | — | — | — |
| Bloques Gummi | En investigación (fuera de la GUI) | — | — | — |

"Verificado" = efecto observado en partida por el usuario **y** comprobado en memoria con lectura externa.

## 2. Quién hizo qué

**Codex (24-25-09):** gestor WinForms multijuego con pestañas y presets por juego; esquema de configuración v2 con validación, recuperación de JSON y 38 pruebas; instalador/desinstalador de LuaBackend con verificación de hash, manifiesto y backups; módulos iniciales de KH1, KH2, BBS y Re:CoM; `RESEARCH.md`, `FEATURE_RESEARCH.md` (pool de entidades, offsets de estadísticas, advertencias sobre save anywhere y bosses) y `FUTURE_NEXUS_RELEASE.md`.

**Claude (25-09):** identificación correcta de la build y firmas de código; EXP, drops, munny, radio, ventas, HP/MP, velocidad, planeo, compañeros, transiciones de diálogo y viaje Gummi en KH1 (todo por desensamblado propio); verificación en partida con el usuario; arnés Lua offline; perfiles de saves; herramientas en `research/tools`; conversor público de saves (`github.com/Julumisan/kh-pc-save-transfer`, proyecto aparte).

## 3. Marcador (competición sana)

Bugs encontrados en el trabajo **del otro** (y los propios, por honestidad):

| Encontró | En trabajo de | Bug | Estado |
|---|---|---|---|
| Claude | Codex | "Fingerprint" circular en `0x469872` y direcciones de la tabla 1.0.0.1 | Corregido |
| Claude | Codex | Munny por diferencias multiplicaba ventas en tienda (KH1) | Corregido; en KH2/BBS/Re:CoM sigue |
| Claude | Codex | Velocidad escrita en el bloque de relleno `0x2D5CB18` (sin efecto) | Corregido |
| Claude | Codex | MP infinito usaba el byte del save como máximo y nunca reponía | Corregido |
| Claude | Codex | `textTrans = 0x22EC194` era de la build JP | Corregido en `FEATURE_RESEARCH.md` |
| Claude | Codex | Propuesta de escribir el salto directamente (el juego lo recalcula) | Anotado |
| Claude | Claude | Primer diseño de EXP/drops escribía floats que el juego recalcula a menudo | Corregido (redirección de lectores) |
| Claude | Claude | La firma de mantisa podía redondear hacia abajo (10 % × 2,4 = 23 %) | Corregido; luego eliminada |
| Claude | Claude | Transiciones de diálogo bloqueadas por la comprobación del HUD | Corregido |
| Claude | Claude | Copias rotativas con nombre por segundo (colisión) | Corregido |
| Codex | Claude | *(pendiente: tu turno de revisar)* | — |

Reglas del marcador: sólo cuentan bugs **reproducibles** con evidencia (log, lectura de memoria o prueba que falla), y quien los encuentra deja una prueba que lo cubra.

## 4. Normas de trabajo acordadas

1. **Fail-closed siempre:** hash + `GAME_ID` + marcadores + firmas de código antes de escribir; bytes vanilla u propios antes de parchear.
2. **Nada es "Verificado" sin partida.** Script cargado ≠ funciona. Usar lecturas externas (`research/tools/live*.py`) y confirmar con el usuario.
3. **No escribir valores que el juego recalcula ni constantes compartidas:** redirigir lectores a ranuras privadas (ver `TECHNICAL.md`, "Patrones aprendidos").
4. **Seguro ante F1:** el estado para deshacer va en ranuras privadas, no sólo en Lua.
5. **Cada cambio lleva prueba** en `tests/kh1_runtime/test_kh1.py` (o el equivalente) y documentación en `TECHNICAL.md`/`README.md`.
6. **El usuario juega; nosotros no conducimos el juego con teclas simuladas.** Preparar todo, pedirle que llegue al punto de prueba y verificar leyendo memoria.
7. **Commits sin coautoría de IA** (preferencia del usuario). Las normas de divulgación de IA de Nexus son otra cosa y están en `FUTURE_NEXUS_RELEASE.md`.
8. **Saves:** nunca escribir el save del usuario desde el mod. Para pruebas, usar el perfil **Pruebas** (botón del gestor, con el juego cerrado).

## 5. Retos abiertos (¿quién se lo queda?)

| # | Tarea | Por qué | Pistas |
|---|---|---|---|
| 1 | **Revisar el código KH1 de Claude** | Empezar el marcador en la otra dirección | `scripts/kh1/io_packages/kh_qol/*`, `tests/kh1_runtime` |
| 2 | Ver la EXP ×2 en una subida de nivel | Última función KH1 sin ver | Partida real del usuario, primeros combates |
| 3 | Ver compañeros a 1,5x y viaje Gummi | Implementados, sin ver | Ciudad de Paso (Donald/Goofy); tras la primera ruta Gummi |
| 4 | Multiplicador de bloques Gummi | Pedido por el usuario | Observar el inventario Gummi durante un vuelo; `research/tools/textscan.py` como plantilla |
| 5 | Moneda KH2/BBS/Re:CoM en el punto de concesión + ventas opcionales | Hoy multiplican ventas siempre | Mismo enfoque que KH1: buscar el `AddMunny` equivalente y sus llamadas |
| 6 | Verificación en partida de KH2/BBS/Re:CoM | Todo sigue "Experimental" | Esperar valores recalculados y máximos equivocados, como en KH1 |
| 7 | Ver en partida salto, HP/MP máximo y HP de enemigos (KH1) | Implementados el 26-09, sin ver | `live_check.py`; slot 0 `+0x10/+0x40/+0x48`, enemigos en `Version.battle_slots` |
| 11 | Sesión con depurador: daño, texto letra a letra, bloques Gummi | Desbloquearía daño recibido/causado y one-hit | Puntos de ruptura de hardware de escritura sobre el HP de Sora / el recuento de glifos / el inventario Gummi, con el perfil de saves Pruebas |
| 8 | Texto instantáneo letra a letra | Nice to have | Descartes y siguiente paso en `FEATURE_RESEARCH.md` |
| 9 | Crash de Re:CoM (`CrashDump.dmp` 25-09 09:00, `+0x389C65`) | Visto en pruebas de Codex | Access violation con config Vanilla; revisar antes de dar Re:CoM por bueno |
| 10 | ~~Paquete de lanzamiento~~ **Hecho 26-09** | `dist/KH_QoL_Manager_0.1.0-beta.zip` | Rehacer con `tools/Build-Release.ps1` tras cada cambio; página en `NEXUS_PAGE.md` |

## 6. Cómo probar

```powershell
powershell -ExecutionPolicy Bypass -File .\KH_QoL\tests\Test-Manager.ps1      # juego cerrado
powershell -ExecutionPolicy Bypass -File .\KH_QoL\tests\Test-SaveProfiles.ps1
powershell -ExecutionPolicy Bypass -File .\KH_QoL\tests\Test-Static.ps1
python .\KH_QoL\tests\kh1_runtime\test_kh1.py
```

En partida: `python KH_QoL\research\tools\live_check.py KH_QoL\research\tools` vuelca el estado de todos los parches; los `watch*.py` sirven de monitores. Cambiar la config en caliente = guardar desde el gestor (o `Save-KHQoLSettings`); se aplica en ~2 s. Cambiar código Lua = F1 en el juego.

## 7. Mapa de documentos

- `README.md`: uso y estado para el usuario.
- `TECHNICAL.md`: mecanismos, mapa de memoria, patrones y ranuras privadas.
- `TEST_PLAN.md`: pruebas automáticas y checklist en partida.
- `FEATURE_RESEARCH.md`: viabilidad de lo pendiente, con correcciones.
- `RESEARCH.md`: fuentes, licencias y procedencia de cada dato.
- `FUTURE_NEXUS_RELEASE.md`: plan de publicación.
- `CHANGELOG.md`: historial de cambios.
- `research/tools/README.md`: herramientas de investigación.
