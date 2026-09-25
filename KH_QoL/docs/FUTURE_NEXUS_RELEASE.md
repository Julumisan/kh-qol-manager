# Publicación futura en Nexus Mods

Estado: **intención futura; no publicar todavía**. Este documento es el relevo operativo para continuar el lanzamiento con Codex, Claude o una persona sin tener que reconstruir las decisiones del proyecto.

## Objetivo

Publicar **KH QoL Manager** cuando exista una versión limpia, reproducible y suficientemente probada. El primer lanzamiento público debería ser `0.1.0-beta`: KH1 puede anunciar sólo lo comprobado y los otros juegos deben figurar como experimentales hasta completar sus pruebas en partida.

No crear una página pública vacía. Nexus prohíbe los placeholders sin un archivo funcional y exige que las afirmaciones de la página sean verificables.

## Condiciones mínimas antes de publicar

- Instalación limpia desde un ZIP en otra copia o instalación de Steam.
- Apertura del launcher oficial y carga correcta de cada ejecutable compatible.
- Prueba A/B de cada función anunciada: Vanilla, opción activa y vuelta a Vanilla.
- Build desconocida bloqueada sin ninguna escritura.
- Desinstalación completa probada, incluidos archivos preexistentes de otro mod.
- Al menos KH1 probado en una partida no completada para confirmar EXP y subida de nivel.
- Ninguna opción roja o no verificada presentada como funcional.
- `CHANGELOG`, licencia del proyecto, créditos, terceros, instrucciones y plantilla de incidencias incluidos.
- ZIP generado por una lista positiva de archivos; nunca comprimir directamente la carpeta de desarrollo.

## Contenido del paquete

Incluir:

- `KH_QoL_Manager.cmd` y `KH_QoL_Manager.ps1`.
- Scripts propios en `KH_QoL/scripts`.
- Configuración inicial, documentación de usuario y desinstalador.
- `LICENSE`, `THIRD_PARTY_NOTICES.md`, `CHANGELOG.md` y número de versión.
- Un manifiesto de archivos del paquete con SHA-256.

Excluir siempre:

- Ejecutables, assets, partidas o cualquier archivo de Kingdom Hearts.
- `KH_QoL/research`, repositorios clonados, tablas de Cheat Engine y `pydeps`.
- Logs, copias de seguridad, volcados de memoria y capturas con datos personales.
- `settings.json` del usuario y el manifiesto de instalación generado localmente.
- `LuaBackend.toml` con rutas absolutas de este PC.
- DLL descargadas para investigar y cualquier archivo sin permiso de redistribución.

## LuaBackend y licencias

La opción más limpia es declarar [LuaBackend](https://github.com/Sirius902/LuaBackend) como requisito externo y dirigir al usuario a su release oficial. LuaBackend es GPL-3.0; no se debe volver a empaquetar su DLL sin revisar y cumplir sus obligaciones de licencia, avisos y acceso al código fuente correspondiente.

El código de KH QoL debe llevar una licencia elegida expresamente por el autor antes del lanzamiento. Los repositorios usados como referencia conservan sus propias licencias. No incluir código, assets o tablas de terceros cuando sólo se tenga permiso para estudiarlos. El mod “100 Drop Rate” de Nexus se trató únicamente como comparación pública y no se reutilizó.

## Página recomendada

Usar una página principal/hub y no cuatro copias independientes del mismo gestor. La descripción debe contener:

1. Qué hace el gestor y qué no hace.
2. Tabla por juego con `Verificado`, `Experimental` y `No disponible`.
3. Hashes exactos de las builds Steam admitidas.
4. Requisito de LuaBackend y pasos de instalación/desinstalación.
5. Compatibilidades y posibles conflictos con otros hooks `DBGHELP.dll` o scripts Lua.
6. Aviso de copia de seguridad de saves, aunque el proyecto no los modifica intencionadamente.
7. Capturas de la GUI y pruebas visibles; no usar una imagen que sugiera funciones inexistentes.
8. Créditos técnicos y licencias.
9. Plantilla de informe de error.

Plantilla de incidencia:

```text
Juego y versión:
SHA-256 del EXE (lo muestra el gestor):
Preset/opciones:
Momento exacto y pasos para reproducir:
Resultado esperado / observado:
¿Vuelve a ocurrir en Vanilla?:
Otros mods o hooks instalados:
Adjuntar el log del juego afectado (sin partidas ni datos personales):
```

## Transparencia sobre IA

El desarrollo y la documentación han recibido asistencia de modelos generativos. La página y las etiquetas deben declararlo de acuerdo con las reglas vigentes cuando se publique. A 25 de septiembre de 2026, Nexus exige etiquetar el uso generativo relevante y responsabiliza al autor de verificar todas las afirmaciones, también las generadas con herramientas de IA. No presentar el mod al evento especial del 25.º aniversario de 2026: sus reglas prohíben expresamente IA en código, assets o diálogo para ese evento.

Revisar estas políticas de nuevo el día del lanzamiento, porque pueden cambiar:

- [File Submission Guidelines](https://help.nexusmods.com/article/28-file-submission-guidelines)
- [Best Practices for Mod Authors](https://help.nexusmods.com/article/136-best-practices-for-mod-authors)
- [Upload API Open Beta](https://www.nexusmods.com/kingdomheartsfinalmix/news/15454)

## Flujo de lanzamiento

1. Congelar alcance y versión.
2. Ejecutar todas las pruebas automáticas y manuales del `TEST_PLAN.md`.
3. Crear el ZIP en una carpeta temporal desde la lista positiva anterior.
4. Examinar el ZIP, calcular hashes y probarlo desde cero.
5. Crear manualmente la primera página de Nexus y mantenerla oculta mientras se completa.
6. Subir `0.1.0-beta`, revisar la vista previa y publicar sólo cuando archivo y descripción coincidan.
7. Para versiones posteriores, valorar la Upload API/GitHub Action oficial. La beta anunciada en marzo de 2026 se centra en **actualizar** mods existentes, no en crear la primera página.

## Criterio de salida de beta

- Todas las funciones verdes probadas en al menos dos sesiones nuevas.
- Sin corrupción de guardado ni bloqueo de progreso en la matriz de encuentros elegida.
- Instalación, actualización y desinstalación probadas por otra persona o en otro Windows.
- Informes de build incompatibles producen bloqueo seguro y un mensaje útil.
- Documentación en español e inglés sincronizada con la GUI real.



## Estado (26-09-2026)

Paquete `0.1.0-beta` preparado: `KH_QoL/dist/KH_QoL_Manager_0.1.0-beta.zip` (32 archivos, lista positiva en `tools/Build-Release.ps1`), captura `KH_QoL_Manager_en.png` y texto de página en `docs/NEXUS_PAGE.md`. Licencia MIT (a confirmar por el autor). LuaBackend se descarga en la instalación, no se redistribuye. Instalación limpia desde el ZIP probada. Pendiente del autor: crear la página, etiqueta de IA y publicar.
