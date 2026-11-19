# El Stop hook

Un hook de Claude Code impide que el agente termine con el build roto. Solo corre si cambió `Assets`, `Packages` o `ProjectSettings`, y se rinde tras **3 intentos** seguidos.

| Mensaje | Qué hace el agente |
|---|---|
| "Unity hasn't compiled the latest script changes" | `refresh_unity`, lee la Consola y para otra vez |
| "A prefab under Assets/Client changed..." | Corre `ClientPrefabsTests` |
| "The full EditMode suite is due" | Corre todos los tests EditMode (como mucho cada 2 h) |
| Error de prefab con ID de regla | Reconstruye o arregla el prefab |
| Error `CS...` o `UA00..` | Arregla el código |
| "Verify passed" | Nada: puede terminar |

| Editor | El hook ejecuta |
|---|---|
| Cerrado | `scripts/verify.sh` (compila en batch; tests cuando tocan) |
| Abierto | `scripts/verify-editor.sh` (lee `Logs/verify/` que escribe el Editor) |

Exit codes: `0` pasó, `1` falló, `2` no pudo correr.
