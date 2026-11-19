# Editor abierto o cerrado

| | Editor abierto (MCP) | Editor cerrado |
|---|---|---|
| Compilar | `refresh_unity` + Consola | `scripts/verify.sh` en batch |
| Tests | `run_tests` con filtro | `VERIFY_TEST_FILTER="..." scripts/verify.sh` |
| Prefabs | Construidos y validados con `execute_code` | No se construyen: el agente escribe el handoff |
| Play mode | Automático | Paso manual |
| Stop hook | `verify-editor.sh` | `verify.sh` |

> [!TIP]
> Trabaja con el Editor **abierto** para todo lo que tenga UI. El modo cerrado vale para cambios de C# puro, CI y máquinas sin Unity abierto.

> [!RULE] EDIT-10
> Con el Editor abierto, tras cambiar scripts el agente **pide compilar** (`refresh_unity`): un Editor sin foco no se refresca solo.
