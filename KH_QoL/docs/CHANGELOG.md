# Changelog

## 26-09-2026 — paquete 0.1.0-beta para Nexus (Claude)

- GUI bilingüe (inglés/español) con selector de idioma que reconstruye la ventana sin perder cambios y recuerda la elección (`ui_language`); versión en el título.
- Textos de opciones reducidos a una frase de qué hacen (sin estados de verificación); aviso "Beta" de una línea en KH2/BBS/Re:CoM.
- Mensajes del núcleo e instalador bilingües; desinstalador basado en datos (`Kept`) y no en el texto.
- LuaBackend se descarga de la release oficial en la instalación y se verifica (ZIP y DLL por SHA-256); ya no se empaqueta.
- La desinstalación completa conserva los perfiles de saves (se mueven junto a los saves de Steam).
- `tools/Build-Release.ps1`: ZIP desde lista explícita + `MANIFEST.sha256`. Paquete: `dist/KH_QoL_Manager_0.1.0-beta.zip`, texto de página en `NEXUS_PAGE.md`.
- Prueba de instalación limpia desde el ZIP (EXE copiados, descarga real, validación, desinstalación completa): correcta.

## 26-09-2026 — limpieza para publicar (Claude)

- GUI: cada pestaña muestra sólo las opciones implementadas en ese juego; secciones vacías ocultas; leyenda de colores simplificada.
- KH1: nuevas opciones Experimental: salto de Sora, HP/MP máximo de Sora, HP de enemigos (incluye jefes).
- Retirados de la GUI, con motivo documentado: daño causado/recibido, daño de enemigos, one-hit, invulnerabilidad, HP de jefes por separado, guardar en cualquier sitio, reintento rápido, bloques Gummi.
- KH2/BBS/Re:CoM: el texto de moneda avisa de que también multiplica ventas.
- Gestor: SHA-256 con .NET en vez de `Get-FileHash` (fallaba en algunos hosts de PowerShell).
- Rangos: HP/MP máximo 0,5–3x, HP de enemigos 0,1–10x.
- Verificado en partida: salto (290 → 580), HP/MP máximo (102 → 204, 15 → 30), HP de enemigos (×2 y ×10, grupo intacto), velocidad de compañeros; EXP verificada en memoria. Sólo el viaje Gummi queda pendiente (el save de pruebas ya tiene Warp-G).

## 25-09-2026 — revisión KH1 y verificación en partida (Claude)

### Corregido
- Identificación de build: el EXE es `SteamGlobal_1_0_0_2`; sustituido el "fingerprint" circular por marcadores públicos + 13 firmas de código + comprobación de bytes vanilla en cada sitio parcheado.
- Munny: ya no multiplica ventas en tienda ni recompensas de evento (se multiplica el valor de los orbes).
- MP infinito: usa el máximo real de combate; antes nunca reponía.
- Velocidad: escribe en el bloque de Sora (antes, en un bloque de relleno sin efecto).
- EXP/drops: dejan de escribir floats que el juego recalcula; se redirigen sus lectores.

### Añadido
- Drops: probabilidad × N con tope 100 % (Lucky Strike), sobre la tabla original.
- Radio de recogida y recogida automática.
- Ventas en tienda multiplicadas (opcional, desactivado por defecto).
- Velocidad de compañeros y planeo acorde a la velocidad.
- Transiciones de diálogo instantáneas.
- Viaje Gummi instantáneo (Warp Drive nativo desde el principio; primer viaje obligatorio). Experimental.
- Perfiles de saves Partida/Pruebas con botón en el gestor y `-SwitchSaves`.
- Estados en colores en la GUI (verde verificado, naranja pendiente, rojo no disponible).
- Arnés Lua offline (`tests/kh1_runtime`), pruebas de perfiles y herramientas en `research/tools`.
- Nuevo Dad Mode: EXP ×2, munny ×3, drops ×3, radio ×3, velocidad ×1,5, transiciones instantáneas.

### Verificado en partida
Munny, drops, radio, recogida automática, ventas, HP/MP infinitos, velocidad (Sora y planeo), transiciones de diálogo.

## 24-25-09-2026 — primera versión (Codex)

- Gestor WinForms multijuego (KH1/KH2/BBS/Re:CoM) con presets independientes.
- Instalación/desinstalación verificada de LuaBackend `v1.9.1-hook`.
- Módulos iniciales de EXP, moneda y HP/MP para los cuatro juegos.
- Documentación de investigación, pruebas y plan de publicación.
