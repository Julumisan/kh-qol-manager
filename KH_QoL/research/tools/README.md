# Herramientas de investigación (KH1)

Sólo lectura sobre el juego, salvo que se diga lo contrario. Requieren Python 3 y `../pydeps` (pefile, capstone, lupa).

| Script | Uso |
|---|---|
| `kdisasm.py <salida.pkl>` | Desensambla el EXE de KH1 una vez (≈1 min) y guarda `kh1.pkl`. Ejecutar como `python kdisasm.py kh1.pkl` en esta carpeta antes que los demás. |
| `q.py` | Biblioteca: `refs(lo, hi)` (instrucciones con destino RIP en un rango), `show()`, `at()`. |
| `r2.py LO HI N` | Muestra cada referencia a `[LO, HI)` con N instrucciones de contexto. |
| `r3.py A B` | Desensambla de A a B. |
| `calls.py F...` | Lista quién llama (call/jmp) a cada función. |
| `cref.py C...` | Quién usa cada constante (p. ej. si una constante de `.rdata` es compartida). |
| `live.py` | Biblioteca: `Proc()` abre el proceso de KH1 **sólo lectura** (`rd`, `f`, `i`, `b`). |
| `live_check.py <esta carpeta>` | Volcado del estado de todos los parches del mod en el juego en marcha. |
| `watch.py` / `watchhp.py` / `watchtext.py` | Monitores de cambios: munny y Lucky Strike, HP/MP/velocidad, estructura de texto. Pensados para `Monitor`/terminal (una línea por cambio). |
| `textscan.py S` | Muestrea zonas de diálogo durante S segundos y ordena candidatos a contador. |
| `savekey.py` / `convert.py` | Análisis y conversión del contenedor de saves (cabecera XOR + `MD5(SteamID+"1")`). La versión pública para usuarios es `github.com/Julumisan/kh-pc-save-transfer`. `convert.py` **escribe** un archivo de salida (no el save). |

Direcciones = RVA respecto a la base del módulo (igual que LuaBackend).
