# Investigación de opciones pendientes

Fecha de corte: **25 de septiembre de 2026**. Esta es una auditoría de viabilidad, no una promesa de que los controles estén listos. Mientras una fila no alcance “implementado”, la GUI debe mantenerla deshabilitada y el runtime no debe escribir memoria para ella.

## Resumen ejecutivo

| Opción | KH1 | KH2 | BBS | Re:CoM | Prioridad propuesta |
|---|---|---|---|---|---|
| HP/MP máximo del jugador | Prometedor, runtime conocido | Requiere base estable | HP prometedor; Focus aparte | HP prometedor; no hay MP | Media |
| Daño recibido | Falta hook con identidad | Tablas/hook por localizar | Multiplicadores EPD conocidos | Sin mapa fiable | Alta |
| Daño causado | Falta atacante + objetivo | ATKP/ENMP documentados | EPD documentado | Sin mapa fiable | Alta |
| HP de enemigos | Pool conocido; falta clasificar | ENMP documentado; copia runtime pendiente | EPD documentado; copia runtime pendiente | Sin mapa fiable | Alta |
| HP de jefes | Posible, alto riesgo de scripts | Posible, 32 unidades/fases | Max HP EPD explícito | Sin mapa fiable | Baja hasta tener excepciones |
| Daño de enemigos | No separable aún de peligros/scripts | Falta contexto del atacante | EPD permite ajuste por enemigo | Sin mapa fiable | Baja |
| One-hit enemigos | Depende de clasificar objetivos | Depende de clasificar objetivos | Depende de EPD/runtime | Sin mapa fiable | Después de HP enemigo |
| One-hit bosses | Alto riesgo de softlock | Alto riesgo de fases | Alto riesgo de fases | Alto riesgo | Última |
| Invulnerabilidad | Reposición ya posible; hook real pendiente | Reposición posible | Reposición posible | Reposición posible | Media |
| Salto | Fuerza runtime de Sora localizada | Campos de movimiento documentados | Por investigar | Por investigar | Media |
| Guardar en cualquier sitio | Mecanismo conocido, riesgo de save/script | Por investigar | Por investigar | Por investigar | Baja |
| Reintento rápido | Requiere máquina de estados | Por investigar | Por investigar | Por investigar | Baja |
| Texto rápido | Direcciones conocidas | Por investigar | Por investigar | Por investigar | Media |
| Cutscenes rápidas | Posible con exclusiones | Por investigar | Por investigar | Por investigar | Baja |

“Documentado” no equivale a “seguro”: KH2 y BBS guardan parámetros en archivos que luego se cargan en memoria. Este proyecto exige localizar la copia runtime, comprobar su identidad y restaurarla; no parcheará los archivos del juego.

## KH1 Final Mix: hallazgos propios

La investigación está ligada al EXE local SHA-256 `D790746245D26159F3EE0E1060E33B2FA2DE06941850A4AC724F598722884BAC`.

### Pool de entidades y estadísticas

- El juego mantiene un pool de **32 bloques de 0x100 bytes** desde `0x2D5CC10`; la máscara de ocupación empieza en `0x2D5CB04`.
- Cada entidad cargada registra un puntero en la lista que empieza en `0x2D5AB20`. El objeto contiene un handle en `+0x6C`; la rutina de resolución en `0x38ADC0` devuelve su bloque de estadísticas.
- En el bloque: HP actual `+0x3C`, HP máximo `+0x40`, MP actual `+0x44`, MP máximo `+0x48`, fuerza `+0x4C` y defensa `+0x50`.
- Sora ocupa normalmente el primer bloque: `0x2D5CC10`; su impulso de salto está en `+0x10` y su HP actual en `0x2D5CC4C`.
- La rutina `0x2A4920` suma un delta firmado al HP, lo limita a `0..máximo` y persiste el byte cuando existe un registro enlazado. No es un hook exclusivo de daño: al menos una llamada conocida le pasa una cantidad positiva de curación. Interceptarla sin contexto modificaría curas y scripts.

### Qué implica para cada opción

**HP/MP máximo del jugador.** Se puede experimentar sobre `+0x40/+0x48` sin tocar los bytes persistentes del save. Para evitar multiplicación acumulativa hay que capturar el valor Vanilla, detectar recálculos por nivel/equipo, reaplicar desde esa base y restaurar exactamente al volver a `1x`. Falta prueba en vivo con subida de nivel, cambio de equipo, mundo, muerte y recarga.

**Salto.** `0x2D5CC20` es el impulso de salto de Sora y coincide con el mapa reciente. Es candidato a un multiplicador runtime reversible. Cambiar sólo ese float puede alterar física contextual o ser sobrescrito al cambiar de sala; necesita una prueba limitada a `0,5–2x` antes de exponerlo.

**Daño recibido.** Las seis resistencias asociadas a Sora y el bloque runtime son pistas útiles, pero no equivalen aún a un multiplicador universal. La vía correcta es identificar la resolución de un impacto negativo con identidad de objetivo, excluir curación/veneno/scripts y después escalar sólo el delta de Sora.

**Daño causado.** Se necesita conservar identidad de atacante y objetivo. Un hook que sólo vea la pérdida de HP también multiplicaría ataques de Donald/Goofy, daño ambiental o daño entre NPC. Magia usa además fórmulas/tablas propias. No implementar hasta observar el evento completo en debugger.

**HP de enemigos normales.** Es viable recorrer los slots activos y modificar `actual/máximo`, pero primero hay que clasificar de forma estable Sora, compañeros, NPC, objetos rompibles, enemigos y summons. La lista de entidades más el handle es el camino más sólido; asumir “todos menos el primer slot” no es seguro.

**HP de bosses.** Existen slots y direcciones usadas por herramientas previas, pero su propio código contiene lógica por mundo, sala, encuentro y cutscene. Hay jefes con varias entidades, umbrales y cambios de fase. Se necesita una allowlist de encuentros probados y restauración por spawn; un multiplicador global sería propenso a softlocks.

**One-hit.** Debe reutilizar la clasificación anterior. Para enemigos normales puede aplicarse sobre el daño confirmado o fijar HP antes del golpe; para bosses debe permanecer separado y desactivado hasta cubrir fases guionizadas.

**Invulnerabilidad.** La reposición de HP actual ya existe y evita resucitar desde cero, pero puede neutralizar muertes guionizadas. Una invulnerabilidad real debe filtrar impactos, no forzar el máximo cada frame. Hasta entonces conviene conservar `HP infinito` como Experimental y no ofrecer ambos controles como si fueran mecanismos diferentes.

**Guardar en cualquier sitio.** La bandera `0x2354854` y un script público confirman que el menú puede abrirse, pero el propio proyecto de referencia advierte de consecuencias inesperadas durante combate o cutscenes. Si se implementa, debería ser una acción puntual y bloqueada salvo estado de campo seguro, no un booleano persistente.

**Texto y cutscenes.** Para esta build se conocen `textSpeed=0x233FBDC`, `textTrans=0x22EC114` (corregido; `0x22EC194` es de la build JP) y `animSpeed=0x233FBCC`. Texto instantáneo es un candidato razonable tras verificar firmas. La velocidad de animación requiere exclusiones de minijuegos cronometrados, summons y escenas especiales. La GUI debería separar “texto rápido” de “cutscenes rápidas”.

### Dirección descartada

El mapa KH1FM reciente etiqueta `0x2A467E` como instrucción de `on_get_hit` para Steam 1.0.0.9. En este EXE exacto esos bytes no forman el hook esperado. Aunque muchas direcciones de datos coinciden, **no se debe reutilizar esa dirección de código**.

## KH2 Final Mix

OpenKH documenta en `00battle`:

- `LVPM`: HP de nivel con fórmula `(EnemyHp * LevelHp + 99) / 100`, además de fuerza y defensa.
- `ENMP`: 32 unidades de HP por enemigo, límite/mínimo de daño y debilidades por elemento en porcentajes.
- `ATKP`: parámetros de ataque, equipo afectado, reacción y otros datos de daño.
- `PLYA`: salto y velocidades de movimiento.

Esto demuestra que HP, daño, resistencias y salto son modificables conceptualmente. Aún falta localizar en esta build las copias runtime concretas de `ENMP/ATKP/PLYA`, registrar sus longitudes y valores originales, distinguir variantes de bosses y restaurarlas. Escalar las 32 unidades indiscriminadamente puede romper subentidades o fases. No editar `00battle.bin` en disco.

## Birth by Sleep Final Mix

OpenKH documenta en cada `EPD`:

- `+0x04`: HP máximo para bosses o multiplicador de salud para enemigos.
- `+0x10` en adelante: multiplicadores de daño físico y elemental.
- Parámetros de técnica con techo/suelo de daño.
- Probabilidad de prize box y lista de drops con probabilidad propia.

Es la base de datos más directa de los cuatro juegos para HP y daño por enemigo. El paso pendiente es interceptar o localizar cada EPD ya cargado en memoria, relacionarlo con la entidad correcta, hacer copia Vanilla y aplicar cambios sin tocar archivos. También hay que comprobar si un boss interpreta `+0x04` como valor absoluto mientras un enemigo lo usa como multiplicador, tal como indica el formato.

## Re:Chain of Memories

El mapa actual basta para HP de Sora, EXP y puntos Moguri, pero no para identificar de forma robusta entidades enemigas, jefes o resolución de daño. Su combate por cartas añade reglas que no se pueden equiparar limpiamente a KH1/KH2. Mantener daño, HP enemigo, one-hit y salto deshabilitados hasta una investigación específica con cambios de carta/stock, duelo, bosses y salas normales.

## Plan de depuración en vivo

Orden recomendado para la siguiente sesión jugable de KH1:

1. Crear un monitor **sólo lectura** del pool de 32 slots y la lista de entidades.
2. Registrar spawn/despawn, handle, HP máximo, fuerza, defensa y cambios de HP sin guardar nombres personales ni partidas.
3. Comparar sala vacía, compañeros, un Heartless normal, objeto rompible y un boss temprano.
4. Usar breakpoints de escritura sobre HP de Sora y un enemigo; capturar la pila y registros para golpe físico, magia, daño ambiental, curación y muerte guionizada.
5. Derivar firmas de código de la build, no direcciones sueltas.
6. Implementar primero salto o HP máximo runtime, luego daño recibido; dejar bosses para una matriz de encuentros.
7. Para cada parche: prueba A/B, restauración a Vanilla, cambio de sala, muerte, carga, pausa y salida al título.

No ejecutar DLL o tablas incluidas en repositorios de investigación. Las tablas se usan como documentación y toda dirección de código debe contrastarse contra el EXE local.

## Fuentes

- [HydroSulphide/KH1FM-Memory-Map](https://github.com/HydroSulphide/KH1FM-Memory-Map), GPL-3.0, commit observado `ff7789a4e44a1b55826104e49964d40c876cb913`.
- [Denhonator/KHPCSpeedrunTools](https://github.com/Denhonator/KHPCSpeedrunTools), Unlicense, commit observado `fb5e4aae160835e7051d7500d7a76f8cd8171c73`.
- [OpenKH/OpenKh](https://github.com/OpenKH/OpenKh), Apache-2.0, commit observado `7a3b945c538d32c6a285128c98aefba093f52ceb`; formatos `kh2/00battle`, `bbs/epd` y `bbs/edp`.
- Desensamblado estático propio del EXE autorizado con Capstone/pefile. Los RVA se documentan para reproducibilidad y no se activan automáticamente.


## Revisión y correcciones (25-09-2026, tras pruebas en partida)

- **Texto rápido: dirección equivocada.** `textTrans = 0x22EC194` es el valor de la tabla **SteamJP_1_0_0_2**. Esta build es Global (`SteamGlobal_1_0_0_2`): `textTrans = 0x22EC114`, `textSpeed = 0x233FBDC`. Verificar con firma antes de usar.
- **Salto: no escribir `0x2D5CC20` directamente.** La rutina `0x2A6380` reescribe `stats+0x10` desde `[0x2D22D30] + personaje*4 + 0x54/0x56` (niveles de High Jump) cada vez que recalcula bonificaciones, y en partida se observó que recalcula muy a menudo (menús, zonas, habilidades). Un float escrito ahí se perdería. Usar el mismo patrón que EXP/drops: redirigir el lector o escalar la tabla de origen, con restauración a 1x.
- **Lección general de la verificación:** cualquier valor recalculado por `0x2A6380` (EXP `0x2D5CB00`, Jackpot `0x2D60FA4`, Lucky Strike `0x2D60FA8`, salto `stats+0x10`, flags `stats+0x184`) no debe escribirse; hay que redirigir las instrucciones que lo leen. Detalle en `TECHNICAL.md`.
- **Moneda en KH2/BBS/Re:CoM:** su método actual (multiplicar cualquier subida del saldo) también multiplica **ventas en tienda**. En KH1 se corrigió actuando en el punto de concesión (orbes). Revisar lo mismo en los otros tres antes de publicar.
- **Estado KH1 verificado en partida:** munny, drops y radio de recogida (ver `TEST_PLAN.md`). EXP sólo comprobado en memoria.

## Texto instantáneo (letra a letra) — pendiente (25-09-2026)

- Implementado y verificado: transiciones de los cuadros (`0x22EC114` = campo `+0x1C` de la ventana 1 del pool de 4 ventanas de 0x38 bytes en `0x22EC0C0`; cuenta 11 al abrir y 7 al cambiar de página). Debe ejecutarse fuera de la comprobación de partida porque el HUD se oculta en los diálogos.
- Descartado como control del ritmo de letras: `0x233FBDC` (paso de tiempo global del juego; tocarlo acelera todo), `0x232DF74` (índice del buffer de glifos dibujados por frame; efecto, no causa), `0x23D3E10` (índice de escritura de una cola circular de 256 órdenes en `0x23D1E10`), `0x22EC118/11C` (0,125 en diálogo, `inf` fuera; escala de la ventana).
- Escaneo en vivo de `0x22EC000`, `0x232D000`, `0x2380000`, `0x23D0000` y `0x2998000` durante un diálogo sin encontrar un contador por carácter: probablemente vive en memoria dinámica del sistema de mensajes. Siguiente paso: punto de ruptura de escritura (depurador) sobre el recuento de glifos para llegar a la rutina que decide cuántos caracteres mostrar.

## Decisión para publicar (26-09-2026)

Criterio: una opción aparece en el gestor sólo si está implementada con las garantías del proyecto (fail-closed, reversible, sin tocar archivos ni saves). Lo demás se retira de la GUI y queda aquí.

### KH1 Final Mix

| Opción | Decisión | Motivo |
|---|---|---|
| Salto | **Implementado** (Experimental) | Tabla de parámetros de combate `[0x2D22D30]+0x54/0x56+id*4`; ver `TECHNICAL.md` |
| HP / MP máximo | **Implementado** (Experimental) | Seguimiento de la base en el bloque de Sora, con copia F1-segura |
| HP de enemigos | **Implementado** (Experimental), incluye jefes | Escalado al aparecer; no hay un indicador fiable de jefe |
| HP de jefes (separado) | Retirado | Sin clasificador fiable de jefe; un valor separado sería engañoso |
| Daño causado | Retirado | Mismo efecto práctico que "HP de enemigos"; el daño no pasa por una rutina única (la de cambio de HP `0x2A4920` sólo se usa para curas; hay 482 escrituras a `+0x3C`) |
| Daño recibido / daño de enemigos | Retirado | Requiere localizar la resolución del impacto con un depurador (puntos de ruptura de escritura sobre el HP de Sora) |
| One-hit enemigos / jefes | Retirado | Depende de clasificar jefes; riesgo de softlock en fases guionizadas |
| Invulnerabilidad | Retirado | Sin hook de impacto sería un duplicado de "HP infinito" |
| Guardar en cualquier sitio | Retirado | La propia referencia (KHPCSpeedrunTools) advierte de consecuencias en combate/cinemáticas |
| Reintento rápido | Retirado | Requiere la máquina de estados de muerte/continuar |
| Bloques Gummi | Retirado de la GUI, en investigación | Hay que observar un vuelo Gummi |
| Texto letra a letra | En investigación | Ver sección anterior; las transiciones sí están |

Siguiente paso técnico común (daño, texto, Gummi): sesión con depurador (puntos de ruptura de hardware sobre la dirección observada) con el juego en una partida de pruebas.

### KH2 / BBS / Re:CoM

Sólo se muestran EXP, moneda y HP (y MP en KH2), todos Experimental. El resto de opciones se retira de sus pestañas hasta repetir en cada juego el proceso de KH1: desensamblado propio, arnés offline y verificación en partida (hay saves de prueba de KH2 y BBS en la carpeta de descargas del usuario, convertibles con `kh-pc-save-transfer`). Conocido: su moneda multiplica también las ventas en tienda (se avisa en el texto de estado).
