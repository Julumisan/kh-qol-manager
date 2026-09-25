# KH QoL Manager

Gestor local multijuego para **Kingdom Hearts HD 1.5+2.5 ReMIX de Steam**, pensado para reducir grindeo sin modificar ejecutables ni partidas guardadas. La GUI separa KH1, KH2, Birth by Sleep y Re:Chain of Memories en pestañas, y cada una conserva su propio preset.

## Empezar a jugar

1. Haz doble clic en `KH_QoL_Manager.cmd` en la carpeta del juego.
2. Elige una pestaña y su preset. KH1 conserva `Dad Mode`; los otros juegos empiezan en `Vanilla`.
3. Pulsa **Guardar y abrir Steam**.
4. En el launcher oficial, inicia cualquier juego de la colección.

Después de guardar no necesitas volver a abrir el gestor: LuaBackend carga automáticamente la configuración del ejecutable que inicies. Abre el gestor sólo cuando quieras cambiar opciones, reparar o desinstalar.

Los cambios guardados se recargan aproximadamente cada dos segundos. Es más seguro cambiar opciones en el menú o antes de iniciar una partida.

## Estado de funciones por juego

| Juego | Integración | Funciones que escriben memoria |
|---|---|---|
| KH1 Final Mix | Activa, hash, marcadores de versión y 14 firmas de código | EXP, Munny, drops, radio de recogida, HP/MP infinitos y velocidad (experimentales) |
| KH2 Final Mix | Activa, hash y huella exactos | EXP, Munny y HP/MP infinitos (experimentales) |
| Birth by Sleep | Activa, hash y huella exactos | EXP, Munny y HP infinito (experimentales) |
| Re:Chain of Memories | Activa, hash y huella exactos | EXP, puntos Moguri y HP infinito (experimentales) |

En la GUI, verde = verificado en partida, naranja = implementado pero **Experimental** hasta observarlo en una partida, rojo = no escribe memoria. En KH1 ya están verificados munny, drops y radio. El gestor sólo muestra, en cada pestaña, las opciones implementadas para ese juego. BBS usa Focus en vez de MP; Re:CoM no tiene barra de MP y sus puntos Moguri son moneda, por lo que no se presentan equivalencias ficticias.

### KH2, Birth by Sleep y Re:Chain of Memories

| Función | KH2 | BBS | Re:CoM |
|---|---|---|---|
| EXP | Reescala de forma reversible la tabla de requisitos de nivel | Reescala la tabla de 99 requisitos de nivel | Reescala la tabla nativa de cálculo de gemas EXP |
| Moneda | Multiplica sólo incrementos de Munny | Multiplica sólo incrementos de Munny | Multiplica sólo incrementos de puntos Moguri |
| HP infinito | Repone HP actual sin resucitar desde cero | Repone HP mediante la cadena de punteros de la unidad de batalla | Repone HP del bloque de batalla |
| MP infinito | Repone MP actual sin alterar el máximo | No aplicable: el recurso es Focus | No aplicable: no existe barra de MP |
| Movimiento | No disponible: sólo se conoce un control de velocidad global, no equivalente | No disponible | No disponible |

Cambiar EXP a `1x` restaura las tablas originales capturadas en memoria. Los multiplicadores de moneda no cambian el saldo al cargar una partida ni multiplican gastos; sólo reaccionan a incrementos posteriores y reconocen su propia escritura.

### KH1 Final Mix

| Función | Estado | Implementación |
|---|---|---|
| EXP | **Verificado** (en memoria) | Las 2 instrucciones que conceden EXP leen `bonus_accesorios × N` de un float propio. El save de pruebas (nivel 100) tiene la EXP al tope 999.999, así que no se pudo ver una subida |
| Munny | **Verificado** (25-09-2026) | Cambia el valor de los orbes de munny (1/5/20 → p. ej. 3/15/60). Ventas en tienda y recompensas de evento no se multiplican. Límite 99.999 |
| Ventas en tienda (opcional) | **Verificado** (25-09-2026: poción 12 → 36 con 3x) | Casilla aparte, desactivada por defecto: el precio de venta de los objetos usa el multiplicador de munny (la tienda muestra el precio ya multiplicado). Los precios de compra no cambian. No incluye bloques Gummi |
| Drops | **Verificado** (25-09-2026) | Las 2 instrucciones que deciden el drop leen `Lucky Strike × N`: probabilidad × N con tope natural del 100 %, misma tabla de objetos |
| Radio de recogida | **Verificado** (25-09-2026) | Escala los radios de atracción de orbes (con y sin Treasure Magnet); la constante compartida con otro código no se toca |
| Recogida automática | Verificado (usa el radio) | Fuerza el radio a 50x como mínimo |
| HP infinito | **Verificado** (25-09-2026) | Repone el HP al máximo real en el mismo frame; nunca resucita desde 0; puede interferir con muertes guionizadas |
| MP infinito | **Verificado** (25-09-2026) | Repone MP hasta el máximo real de combate (corregido: antes usaba un byte del save y no reponía) |
| Velocidad | **Verificado** (25/26-09-2026) | Velocidad de Sora y de los compañeros (bloques de combate con ficha de personaje; los enemigos no se tocan), (bloque real `0x2D5CC18`; antes se escribía en un bloque sin uso) y planeo acorde (velocidad máxima y aceleración, normal y Superglide); 0,5–2x; respeta velocidades especiales del juego |
| Salto | **Verificado** (26-09-2026: 290 → 580 con 2x) | Salto de Sora escalado en la tabla de parámetros de combate (de donde el juego lo recalcula) y en el valor vivo; 0,5–3x |
| HP máximo / MP máximo | **Verificado** (26-09-2026: HP 102 → 204, MP 15 → 30) | Máximos de Sora en combate (no se guardan en la partida); siguen las subidas de nivel y el equipo; 0,5–3x |
| HP de enemigos | **Verificado** (26-09-2026: 150 → 300 con 2x, 120 → 1.200 con 10x) | Se aplica a cada enemigo al aparecer, una sola vez; **incluye jefes** (no se distinguen de forma fiable); 0,1–10x |
| Transiciones de diálogo instantáneas | **Verificado** (25-09-2026) | Corta la animación de apertura (11 frames), cambio de página (7) y cierre de los cuadros de texto (`0x22EC114`). Las letras siguen apareciendo a su ritmo normal. No toca el paso de tiempo global ni las cinemáticas |
| Viajes Gummi instantáneos | Pendiente de ver (el save de pruebas ya lleva Warp-G) | Hace que la nave cuente como equipada con Warp-G desde el principio: el juego ofrece su propio *Warp Drive* sólo en rutas ya voladas. **El primer viaje a cada mundo sigue siendo obligatorio** (lo impone el juego; respeta los desbloqueos de la historia). Desactivado en Dad Mode |

Las opciones que no se pueden implementar con garantías **no aparecen** en el gestor (daño causado/recibido, one-hit, invulnerabilidad, HP de jefes por separado, guardar en cualquier sitio, reintento rápido, bloques Gummi); el motivo de cada una está en `FEATURE_RESEARCH.md`.

`Dad Mode` en KH1: 2x EXP, 3x Munny, 3x drops, 3x radio, velocidad 1,5x (Sora, compañeros y planeo) y transiciones de diálogo instantáneas; combate y bosses permanecen Vanilla. Todo vuelve a los bytes originales al poner 1x (sin reiniciar el juego). Detalles en `TECHNICAL.md`.

### Investigación de drops ajustables

No es imposible. KH2 conserva tres probabilidades originales por entrada en la tabla `PRZT` de `00battle`, y BBS almacena probabilidades por enemigo tanto en `PRIZEBOXDATA` como en sus parámetros `EPD`. Por tanto se puede aplicar exactamente `min(probabilidad_original × multiplicador, 100%)` sin convertirlo en drop garantizado. Todavía no se activa en KH2/BBS porque falta localizar y validar de forma independiente la copia runtime de esas tablas en esta build; parchear archivos del juego violaría el diseño reversible. **KH1 ya lo implementa** mediante el multiplicador nativo de Lucky Strike. En Re:CoM aún falta un hook propio comprobable.

## Saves de pruebas y partida real (KH1)

El botón **Saves: … → cambiar a …** de la pestaña KH1 (o `KH_QoL_Manager.ps1 -SwitchSaves`) alterna entre dos perfiles del contenedor de KH1, `Partida` y `Pruebas`, guardados en `KH_QoL\save_profiles`. Cada cambio guarda antes el contenedor activo en su perfil, así que ninguno pierde progreso, y deja una copia rotativa en `KH_QoL\backup\save-switch` (máximo 6). Exige que el juego esté cerrado. Si el perfil de destino está vacío, se quita el contenedor y el juego crea uno limpio al arrancar. Los saves de otros juegos no se tocan.

## Seguridad y recuperación

- El ejecutable oficial no se modifica.
- Antes de escribir memoria se exige simultáneamente el hash autorizado, `GAME_ID`, firmas de código de la build y comprobaciones de rango sobre el estado cargado.
- Una actualización de Steam cambia el hash y bloquea todos los parches.
- **Vanilla en este juego** sólo restaura la pestaña seleccionada; no cambia los otros títulos.
- **Desinstalar hook** elimina/restaura únicamente `DBGHELP.dll` y `LuaBackend.toml` y conserva el gestor. `Uninstall_KH_QoL.cmd` hace una desinstalación completa: primero restaura esos archivos por hash y luego elimina sólo `KH_QoL` y los launchers propios. No toca saves ni mods ajenos.
- Si un archivo instalado cambia después, el desinstalador lo conserva en vez de borrarlo.

Los logs están en `KH_QoL\logs`, separados como `kh1-runtime.log`, `kh2-runtime.log`, `bbs-runtime.log` y `recom-runtime.log`. F2 abre la consola integrada de LuaBackend para diagnóstico.

## Archivos principales

- `KH_QoL_Manager.cmd` / `.ps1`: entrada de un clic y GUI WinForms.
- `KH_QoL\config\settings.json`: configuración humana.
- `KH_QoL\scripts\kh1|kh2|bbs|recom\main.lua`: entradas aisladas de LuaBackend.
- `KH_QoL\uninstall\install-manifest.json`: propiedad, hashes y restauración.
- `KH_QoL\docs`: investigación, diseño y pruebas.
- `KH_QoL\save_profiles`: perfiles de saves de KH1 (Partida / Pruebas).
- `KH_QoL\tests`: pruebas del gestor, de perfiles, estáticas y arnés Lua (`kh1_runtime`).
- `KH_QoL\research\tools`: herramientas de desensamblado y lectura en vivo (ver su README).

Documentos de continuidad:

- [`HANDOFF.md`](HANDOFF.md): **punto de entrada** para retomar el proyecto (estado, reparto Codex/Claude, normas, retos abiertos).
- [`CHANGELOG.md`](CHANGELOG.md): historial de cambios.

- [`FEATURE_RESEARCH.md`](FEATURE_RESEARCH.md): qué se investigó, qué se implementó y qué se descartó (con el motivo) en cada juego.
- [`FUTURE_NEXUS_RELEASE.md`](FUTURE_NEXUS_RELEASE.md): intención y checklist para una futura publicación en Nexus Mods.

## Línea de comandos

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\KH_QoL_Manager.ps1 -Validate
powershell.exe -ExecutionPolicy Bypass -File .\KH_QoL_Manager.ps1 -Install
powershell.exe -ExecutionPolicy Bypass -File .\KH_QoL_Manager.ps1 -Uninstall
powershell.exe -ExecutionPolicy Bypass -File .\KH_QoL_Manager.ps1 -SwitchSaves   # KH1: Partida <-> Pruebas (juego cerrado)
```

`-Validate` comprueba los cuatro ejecutables, el hook oficial y el esquema multijuego. Una actualización de cualquiera de los EXE bloquea únicamente los parches de esa build hasta volver a verificarla.
