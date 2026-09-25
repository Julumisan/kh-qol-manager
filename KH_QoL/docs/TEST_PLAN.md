# Plan y registro de pruebas

## Automatizadas

Ejecutar:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\KH_QoL\tests\Test-Manager.ps1
powershell.exe -ExecutionPolicy Bypass -File .\KH_QoL\tests\Test-Static.ps1
python .\KH_QoL\tests\kh1_runtime\test_kh1.py
```

**Estado a 25-09-2026 (revisión de Claude):** arnés Lua **90/90**, gestor **38/38** (exige el juego cerrado), perfiles de saves **12/12**, estáticas sin fallos. El arnés ejecuta los scripts reales de KH1 en Lua 5.4 contra una imagen de memoria construida con el EXE instalado.

Añadir también:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\KH_QoL\tests\Test-SaveProfiles.ps1
```

(Resultado de la primera versión, Codex, 25-09-2026: 38/38 del gestor y 30/30 estáticas, con migración v1→v2, presets, rangos, recuperación JSON, hashes, TOML, fail-closed, instalación idempotente y desinstalación selectiva.)

La primera versión de la GUI se validó mediante UI Automation. La revisión multijuego actual se validó por parser de PowerShell y comprobaciones estructurales porque esta sesión no expuso una superficie de aplicaciones nativas; debe repetirse la inspección visual cuando el host habilite Computer Use para Windows.

Se hicieron arranques no destructivos de KH2, BBS y Re:CoM con Steam App ID. LuaBackend cargó cada `main.lua`, informó el `GAME_ID` correcto, aceptó hash y firma y activó Vanilla. BBS y Re:CoM permanecieron vivos durante la ventana de prueba; KH2 permaneció vivo en la repetición instrumentada. Las lecturas confirmaron fingerprints y, en BBS, la tabla EXP exacta. No se cargó ninguna partida; las comprobaciones de estado impidieron escrituras en la pantalla inicial. Todos los procesos de prueba se cerraron después.

La validación final `KH_QoL_Manager.ps1 -Validate` comprueba la instalación real, los hashes de los cuatro EXE y el DLL oficial.

## Checklist manual en juego

No se marca una función como Verified hasta observar su efecto real y revisar el log. Usar un save prescindible o anotar los totales antes de cada prueba.

| # | Caso | Procedimiento / resultado esperado | Estado inicial |
|---:|---|---|---|
| 1 | Vanilla | En cada juego, restaurar Vanilla y ganar EXP/moneda; recompensa normal | KH1: A/B en caliente hecho (drops/radio/velocidad); resto pendiente |
| 2 | EXP 2x | En cada juego, anotar nivel/EXP, derrotar enemigo conocido y comprobar progresión equivalente a 2x | KH1: verificado en memoria (EXP al tope 999.999 en el save de nivel 100) |
| 3 | Moneda 3x | KH1/KH2/BBS: ganar Munny; Re:CoM: ganar puntos Moguri. Incremento final 3x, sin remultiplicación | **KH1 verificado 25-09-2026** (orbes 3/15/60); resto pendiente |
| 4 | Drop 3x | KH1: matar enemigos con drop conocido (p. ej. Soldier/Shadow en Ciudad de Paso) y comparar frecuencia; leer `0x2D60FA8` = base×3 | **KH1 verificado 25-09-2026** (100x: casi todos sueltan; restaurado a 3x); otros no disponible |
| 5 | Clamp drop | KH1: la fórmula del juego satura en 100 % (50 % × 3 → 100 %) | Automatizado (fórmula del EXE) |
| 6 | Pickup | KH1: los orbes vuelan hacia Sora desde ~3x más lejos; con 1 Treasure Magnet también | **KH1 verificado 25-09-2026** (10x) |
| 7 | HP jugador | En cada juego, HP infinito repone daño normal pero no resucita desde 0 | **KH1 verificado 25-09-2026**; resto pendiente |
| 8 | HP enemigo | Control deshabilitado; HP Vanilla | Esperado/no disponible |
| 9 | One-hit normal | Control deshabilitado; daño Vanilla | Esperado/no disponible |
| 10 | Boss | Todos los controles de boss deshabilitados; secuencia Vanilla | Esperado/no disponible |
| 11 | Load/save/reload | Cambiar preset en menú, cargar save y confirmar que no multiplica el saldo existente | Pendiente |
| 12 | Cerrar/reabrir | Cerrar normalmente, reabrir y confirmar preset/log sin duplicar recompensas | **KH1 verificado** (varios reinicios y recargas F1 sin duplicar) |
| 13 | Build desconocida | Copia temporal con hash distinto o test unitario; `build_authorized=false`, cero escrituras | Detección automatizada; runtime pendiente |
| 14 | Restauración EXP | Cambiar de 2x a 1x en una partida; los requisitos/constantes originales vuelven sin reiniciar | Pendiente |
| 15 | MP por juego | KH1/KH2 reponen MP; BBS/Re:CoM muestran la opción deshabilitada por no existir recurso equivalente | **KH1 verificado 25-09-2026** (tras corregir el máximo); KH2 pendiente |
| 16 | Velocidad y planeo | KH1: 2x / 0,5x / 1,5x en caliente; Sora y planeo acordes | **Verificado 25/26-09-2026** (Sora, Donald y Goofy a 12/16) |
| 17 | Ventas en tienda | KH1: casilla activa, poción 12 → 36 con 3x; desactivada vuelve a 12 | **Verificado 25-09-2026** |
| 18 | Transiciones de diálogo | KH1: el contador 11/7 se corta a 0; cuadros sin animación | **Verificado 25-09-2026** |
| 19 | Viaje Gummi | KH1: tras volar una ruta, el menú ofrece Warp Drive a ese mundo y no a los no visitados | Pendiente (el save de pruebas ya lleva Warp-G: marca = 1 sin el mod) |
| 21 | Salto | KH1: 1,5x → Sora salta más alto; 1x vuelve exacto; tras un menú sigue escalado | **Verificado 26-09-2026** (290 → 580 con 2x; 1x vuelve a 290) |
| 22 | HP/MP máximo | KH1: 2x → barra más larga; subir de nivel mantiene el ×2; 1x recorta el actual | **Verificado 26-09-2026** (HP 102 → 204, MP 15 → 30; 1x restaura) |
| 23 | HP de enemigos | KH1: 2x → los enemigos nuevos aguantan el doble; los ya presentes no cambian | **Verificado 26-09-2026** (150 → 300 con 2x, 120 → 1.200 con 10x; grupo intacto) |
| 20 | Perfiles de saves | Cambiar Pruebas ↔ Partida con el juego cerrado; ambos conservan progreso | Automatizado 12/12; cambio real hecho 25-09-2026 |

## Criterios de aceptación runtime

- El log contiene hash autorizado y configuración, sin errores.
- EXP/Munny se prueban con incrementos conocidos, no sólo por carga del script.
- Un cambio Vanilla restaura EXP a la base de accesorios en KH1, las tablas originales en KH2/BBS/Re:CoM y velocidad a 8,0 en KH1 si este mod la cambió.
- No hay crash al entrar/salir de mundos, abrir menús, cargar o cerrar.
- No se modifica ningún archivo de save; comparar sus timestamps es una comprobación adicional, teniendo en cuenta que el propio juego guarda normalmente.

Si falla un caso experimental, restaurar Vanilla, cerrar el juego y revisar el log del título correspondiente en `KH_QoL\logs`. El hash/fingerprint evitan que un fallo de versión se convierta en una escritura ciega.
