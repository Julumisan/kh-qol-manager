# Diseño técnico

Última revisión: 25-09-2026. Para el estado del proyecto, las tareas abiertas y el reparto de trabajo, ver `HANDOFF.md`.

## Flujo

`KH_QoL_Manager.cmd` inicia PowerShell 5.1 en modo STA y abre WinForms. El gestor usa un `TabControl` con estado independiente para KH1/KH2/BBS/Re:CoM, valida `config/settings.json` (esquema 2) y genera un `runtime.lua` separado para cada juego. LuaBackend carga la carpeta correspondiente al EXE iniciado; nunca se comparte un mapa de direcciones entre juegos.

Cada 120 frames, `main.lua` compara el contenido de `runtime.lua`. Una configuración válida se aplica en caliente; si la lectura o evaluación falla, se conserva la última configuración válida. Los números también se vuelven a limitar en Lua. **F1** (LuaBackend) recarga los scripts sin cerrar el juego; todos los módulos de KH1 están diseñados para sobrevivir a esa recarga sin multiplicar nada dos veces.

## Cadena fail-closed

Antes de cualquier escritura deben cumplirse todos estos niveles:

1. El gestor calcula SHA-256 de los cuatro EXE y sólo emite `build_authorized=true` en el runtime correspondiente cuando coincide el hash exacto catalogado.
2. Lua compara de nuevo la cadena completa del hash.
3. LuaBackend debe informar el `GAME_ID` propio del módulo: KH1 `0xAF71841E`, KH2 `0x431219CC`, BBS `0xBED4B944` o Re:CoM `0x9E3134F5`.
4. Firmas de la build:
   - **KH1:** los dos marcadores públicos de `SteamGlobal_1_0_0_2` (`0x4698D2 = "japanese"`, `0x26E20C = 09`) y 17 firmas exactas de instrucciones que referencian las direcciones de datos usadas (`version.lua`, `M.signatures`). Además, cada sitio que el mod reescribe (16, `M.patch_sites`) sólo se toca si contiene los bytes vanilla o los que escribió el propio mod; si no, esa función se bloquea para la sesión.
   - **KH2/BBS/Re:CoM:** firma de ocho bytes en `0x660EF4`, `0x726464` o `0x705248`.
5. Comprobación de partida cargada (nivel, HP, HUD, puntero de munny en KH1) para los valores ligados a la partida. Las excepciones justificadas en KH1 son los parches estáticos de código (se aplican al autorizar), las transiciones de diálogo y el viaje Gummi (el HUD se oculta en diálogos y en el mapa de mundos).

Una discrepancia deja el script en modo lectura/espera. No existe fallback a otra tabla ni escritura “a ver si funciona”.

## KH1 Final Mix

### Identificación de la build

El EXE instalado (SHA `D790746245D26159…`, metadatos 1.0.0.1) corresponde a la tabla **`SteamGlobal_1_0_0_2`** de KHPCSpeedrunTools, no a la 1.0.0.1. La primera versión del mod usaba como "fingerprint" los bytes que hubiera en `0x469872` (texto japonés), lo que era circular. Todas las direcciones actuales se derivaron desensamblando este EXE (capstone) y se contrastaron en el proceso real.

### Patrones aprendidos (aplicables a los otros juegos)

1. **No escribir valores que el juego recalcula.** La rutina `0x2A6380` rehace EXP, Jackpot, Lucky Strike, salto (`stats+0x10`) y flags (`stats+0x184`) al abrir o cerrar menús, al cambiar de zona, desde scripts y al cambiar habilidades; en partida pasa muy a menudo. En vez de escribir el valor, se **redirigen las instrucciones que lo leen** (desplazamiento RIP) a un float propio con `base × N`.
2. **No escribir constantes compartidas.** Las constantes de `.rdata` (8,0, 16,0, 40000,0…) las usan cientos de instrucciones; se redirigen sólo las cargas relevantes.
3. **Ranuras privadas.** El relleno a cero tras el final de `.data` (VirtualSize `0x2F135B8`, misma página) no lo referencia nada de la imagen. El mod guarda ahí sus valores y copias de seguridad (ver mapa).
4. **Seguro ante F1.** Todo estado necesario para deshacer (bases, precios originales, última velocidad escrita) se guarda en esas ranuras y no sólo en Lua.
5. **El HUD no siempre está.** Se oculta en diálogos y en el mapa de mundos; lo que debe funcionar ahí va fuera de la comprobación de partida.
6. **Verificar en partida con lecturas externas.** `live_check`/monitores de sólo lectura (Python + `ReadProcessMemory`) confirmaron cada función; tres errores sólo se vieron así (velocidad en el bloque de relleno, MP con el máximo equivocado, texto bloqueado por el HUD).

### Mapa de memoria

| RVA | Qué es | Uso |
|---|---|---|
| `0x2D5CB00` | Multiplicador de EXP (1 + 0,2/0,3 por accesorio) | Sólo lectura; lectores redirigidos |
| `0x2D60FA4` | Jackpot (1 + 0,5·n; nº de orbes) | Sin tocar |
| `0x2D60FA8` | Lucky Strike (1 + 0,5·n; probabilidad de drop) | Sólo lectura; lectores redirigidos |
| `0x2D5CC10` | Pool de 32 bloques de combate × 0x100 (bloque 0 = Sora); ocupación en `0x2D5CB04` | HP `+0x3C`, HP máx `+0x40`, MP `+0x44`, MP máx `+0x48`, velocidad `+0x08`, salto `+0x10`, ficha del save `+0xC8` |
| `0x2D5CB10` | Bloque de combate de relleno (el juego lo ignora) | Sólo se limpia (`+0x08` = 8,0) |
| `0x2DE9364` | Fichas de personaje del save (0x74 bytes): nivel, HP, HP base… | Identificar compañeros |
| `0x2E1F4D8` | Puntero al bloque de config/munny (= base + `0x2DFF760`); munny en `+0x1C` | Límite 99.999; cálculo de la base |
| `0x2D22D30` | Puntero a la tabla de parámetros de combate (salto por personaje `+0x54/+0x56 + id*4`, curación `+0x88`, resurrección `+0x8C`) | Salto |
| `0x2D22D38` | Puntero a la tabla de objetos (255 × 20 bytes; compra `+0x08`, venta `+0x0A`) | Ventas opcionales |
| `0x22EC0C0` | Pool de 4 ventanas de texto × 0x38; transición de la ventana 1 en `0x22EC114` | Transiciones de diálogo |
| `0x2689878` | Mapa de mundos: "la nave lleva Warp-G" | Viaje Gummi |
| `0x233FBDC` | Paso de tiempo global del juego | **Nunca** se escribe |

Ranuras privadas (relleno de `.data`):

| RVA | Contenido |
|---|---|
| `0x2F13A00` | Ventas: `KHQS` + puntero de la tabla + 255 precios de venta originales (hasta `0x2F13C0A`) |
| `0x2F13C20` | HP de enemigos: 32 × int, HP máximo escrito por bloque de combate |
| `0x2F13CB0` | Salto: marca + puntero de la tabla de parámetros + 2 valores originales de Sora |
| `0x2F13CC0` / `CC8` | HP / MP máximo de Sora: base y valor escrito |
| `0x2F13FCC` / `FD0` / `FD4` | Planeo: aceleración, velocidad máxima normal y con Superglide × multiplicador |
| `0x2F13FD8` | Última velocidad escrita (sobrevive a F1) |
| `0x2F13FE0` / `FE4` | Copias de la primera revisión (sólo migración) |
| `0x2F13FE8` / `FEC` | EXP y Lucky Strike efectivos (`base × N`) |
| `0x2F13FF0` | Radio de 1 Treasure Magnet × m² |

### EXP — Verificado en memoria

`0x2A4FB8`/`0x2A50AB` conceden `trunc(exp_base × [EXP] + 0,5)`. Ambas instrucciones leen el float privado `0x2F13FE8` = bonificación de accesorios × N. El save de pruebas (nivel 100) tiene la EXP al tope (999.999 en la ficha de Sora, `+0x3C`), así que no se pudo ver una subida.

### Drops — Verificado

En muerte de enemigo (`0x2ABB58`): `drop si trunc(prob% × LuckyStrike) > trunc(rand × 100)`; en objetos (`0x2ABE50`): `prob × LuckyStrike > rand`. Ambas instrucciones leen `0x2F13FEC` = Lucky Strike × N, lo que da exactamente `min(prob × N, 100 %)` sobre la tabla original de cada enemigo. Con 100x casi todos los enemigos sueltan su objeto. Jackpot no se toca (multiplicaría orbes de HP/MP).

### Munny — Verificado

La recogida de orbes ejecuta `mov ecx, 1|5|20; call AddMunny` (`0x2AC313/1F/2B`); el mod reescribe sólo los inmediatos con `round(valor × N)`. Ventas (`0x301370/0x301440`) y recompensas de evento no pasan por ahí. Límite 99.999. Verificado con más de 60 recogidas, todas múltiplos de 3 con 3x.

### Ventas en tienda (opcional) — Verificado

El precio de venta es el u16 `+0x0A` de la tabla de objetos; sólo lo leen `0x2FF6C0`, `0x301440` y `0x3017C0` (tienda). Con la casilla activa se escala por el multiplicador de munny y la tienda muestra el precio resultante (poción 12 → 36 con 3x). Originales en `0x2F13A00`; si la tabla se reubica se toma otra copia; desactivada no lee ni escribe nada. Bloques Gummi (`0x301370`, tabla `0x225FC0` compartida) excluidos.

### Radio de recogida y recogida automática — Verificado

`0x2AB420`/`0x2AC080` comparan distancia² con 80² (`0x3EF6C8`), 120² (`0x3EF6CC`), 200² con 1 Treasure Magnet (`0x3EDE28`, compartida con 6 rutinas) o 400² con 2 (`0x3EF6D0`). Las tres exclusivas se escalan por m²; las tres cargas de la compartida se redirigen a `0x2F13FF0`. Recogida automática = radio ≥ 50x.

### HP y MP infinitos — Verificado

HP: `+0x3C` ← `+0x40` en el mismo frame si `0 < HP < máx` (no resucita). MP: `+0x44` ← `+0x48` (máximo real con bonificaciones). La primera versión usaba el byte `0x2DE9368` del save como máximo (8 con máximo real 15) y nunca reponía.

### Velocidad de movimiento y planeo — Verificado (Sora, compañeros y planeo)

- Se aplica a cada bloque ocupado cuyo `+0xC8` apunta a una ficha de personaje (Sora, Donald, Goofy e invitados; los enemigos no tienen ficha). La base del módulo se deduce del puntero de munny y se exige alineación de 64 KB.
- Sólo se reescala si `+0x08` vale 8,0 o lo que escribió el mod; cualquier otro valor es una velocidad contextual del juego y se respeta. Última velocidad escrita en `0x2F13FD8`.
- La primera versión escribía `0x2D5CB18` (bloque de relleno) y no tenía efecto; se limpia al arrancar.
- Planeo (`0x2B2A40`): la velocidad máxima (8,0 normal / 16,0 Superglide) y la aceleración (0,4) son constantes compartidas por 150+ instrucciones; sus tres cargas se redirigen a `0x2F13FCC..FD4` con `valor × multiplicador`.

### Salto — Verificado (26-09-2026)

`0x2A6380` copia el salto de cada personaje al bloque de combate (`+0x10`) desde `[0x2D22D30] + id*4 + 0x54` (o `+0x56` según un estado del juego; `0x2A6772` y `0x2C9AA7` también los leen). Se escalan los dos valores de Sora (id 0) en la tabla y el valor vivo. Comprobación de cordura antes de la primera escritura: el salto vivo de Sora debe coincidir con uno de los dos valores de la tabla. Originales en `0x2F13CB0`; 1x los restaura. Firmas: `0x2A653A`, `0x2A6557`, `0x2A655E`, `0x2A657C`.

### HP máximo / MP máximo — Verificado (26-09-2026)

Bloque de Sora `+0x40` / `+0x48`. Un valor distinto del escrito por el mod se toma como nueva base (subida de nivel, equipo, zona); se escribe `base × N` (máx. 999) y se recorta el actual si supera el máximo. Base y valor escrito en `0x2F13CC0/CC8`. Sólo en memoria: el registro del save no se toca.

### HP de enemigos — Verificado (26-09-2026)

Bloques ocupados sin ficha de personaje (`Version.battle_slots`). Al aparecer con HP completo se escalan HP y HP máximo una vez; el máximo escrito se guarda por bloque en `0x2F13C20`, así un enemigo nunca se escala dos veces (tampoco tras F1 o al alternar la opción). Incluye jefes, objetos rompibles e invocaciones sin ficha. En 1x no escribe nada.

### Transiciones de diálogo instantáneas — Verificado

`0x22EC114` cuenta 11 frames al abrir un cuadro y 7 al cambiar de página. El mod lo pone a 0 cuando está en `(0, 1000)`, fuera de la comprobación de partida. Las letras siguen apareciendo a su ritmo; la investigación del ritmo de letras está en `FEATURE_RESEARCH.md`.

### Nave Gummi

- **Viaje instantáneo (pendiente de ver):** al abrir el mapa, `0x1F375A` guarda en `[0x2689878]` si la nave lleva el bloque de warp (`0x20CBF0`: byte `+0x9AA9` de los datos de la nave > 0). El menú de trayecto (`0x1EF170`) ofrece el Warp Drive sólo si ese flag está activo **y** el byte de estado del destino (`[0x506F10 + mundo]`) tiene el bit `0x02` a 0 (con el bit activo el menú atenúa la opción, `0x1F1D49`). El mod sólo fuerza el flag a 1, así que las rutas no voladas siguen exigiendo el vuelo normal. Firmas: `0x1F375A`, `0x1EF278`, `0x20CC18`. La referencia pública (Instant Gummi de KHPCSpeedrunTools) se descartó porque redirige destinos y cambia la ruta de la historia. Pendiente de verificar en partida: el save de pruebas al 100 % ya lleva Warp-G (la marca vale 1 sin el mod) y todas sus rutas tienen `0x02` a 0; hay que verlo en una partida sin Warp-G tras la primera ruta.
- **Bloques Gummi (en investigación):** `0x20D290`/`0x20D5B0` cuentan piezas al cargar planos (no son drops). Siguiente paso: observar el inventario Gummi durante un vuelo.

### Perfiles de saves

`Switch-KHSaveProfile` alterna el contenedor `KHFM_WW.png` entre `KH_QoL\save_profiles\Partida` y `Pruebas`: guarda el activo en su perfil, coloca el otro (o lo quita para que el juego cree uno limpio), deja una copia rotativa en `backup\save-switch` (máx. 6) y exige el juego cerrado. No toca saves de otros juegos.

### Pruebas

- `tests/kh1_runtime/test_kh1.py`: ejecuta los scripts reales en Lua 5.4 (lupa) contra una imagen de memoria construida con el EXE instalado y la API de LuaBackend simulada (90 casos).
- `tests/Test-SaveProfiles.ps1` (12), `tests/Test-Manager.ps1` (38; exige el juego cerrado), `tests/Test-Static.ps1`.

## KH2 / BBS / Re:CoM (sin revisar en partida)

### EXP — Experimental

- **KH2:** captura las 99 entradas de la tabla de nivel de Sora en `Btl0+0x25928` (stride `0x10`) y escribe `ceil(original/multiplicador)`. Si cambia el puntero `Btl0`, vuelve a capturar; `1x` restaura los valores originales.
- **BBS:** captura 99 enteros consecutivos en `0x649604`, exige que sean crecientes y que el primero sea 90, y aplica la misma reducción reversible de requisitos.
- **Re:CoM:** valida las siete constantes Vanilla de cálculo de gemas en `0x7C2C78` y escribe `floor(original/multiplicador)`, con mínimo 1.

### Moneda — Experimental (problema conocido)

Cada módulo observa su saldo vivo (Munny en KH2/BBS, puntos Moguri en Re:CoM) y, ante una subida, suma `round(gain × (multiplier - 1))`. **Multiplica también las ventas en tienda.** En KH1 se resolvió actuando en el punto de concesión; aquí está pendiente, y la GUI lo indica en la casilla de ventas.

### HP/MP — Experimental

KH2 usa el bloque runtime `Slot1` para HP y MP. BBS resuelve la cadena de punteros de la unidad de batalla para HP. Re:CoM usa el bloque de batalla cuyo puntero global está en `0x87B390`. Todos reponen sólo si `0 < actual < máximo`. BBS usa Focus y Re:CoM carece de barra de MP.

Riesgos previsibles a la luz de KH1: valores recalculados por el juego, máximos tomados de un campo equivocado y direcciones copiadas de tablas de otra build. Ver `HANDOFF.md`.

## Opciones retiradas

La GUI sólo muestra opciones implementadas. Daño causado/recibido, daño de enemigos, one-hit, invulnerabilidad, HP de jefes por separado, guardar en cualquier sitio, reintento rápido y bloques Gummi se retiraron; los motivos están en `FEATURE_RESEARCH.md` ("Decisión para publicar"). No se parchean recursos en disco.

## Instalación y desinstalación

La instalación verifica el SHA oficial de `DBGHELP.dll`, hace backup una sola vez si encuentra un archivo propio preexistente y crea un manifiesto con estado original/instalado. Una segunda instalación reutiliza el manifiesto; si alguien modificó un archivo desde entonces, se detiene para no sobrescribirlo. El desinstalador sólo elimina un archivo si su hash aún coincide con el que instaló, o restaura el backup original.

No se parchea ningún EXE en disco, no se modifica Steam y no se instala persistencia fuera de la carpeta del juego. Los parches de código de KH1 existen sólo en la memoria del proceso y se deshacen a 1x.

## Aislamiento multijuego

Cada juego tiene pestaña, configuración, sección TOML, `GAME_ID`, SHA-256, firmas, direcciones y módulos Lua propios. No se reutilizan offsets entre juegos.
