# Tools que usan las reglas

| Necesidad | Tool | Grupo |
|---|---|---|
| Compilar, leer errores | `refresh_unity`, `read_console` | **Core Tools** (on por defecto) |
| Correr tests | `run_tests`, `get_test_job` | **Testing** (<color=#D29922>off por defecto</color>) |
| Construir y validar prefabs | `execute_code` | **Scripting Extensions** (<color=#D29922>off por defecto</color>) |
| Play mode | `manage_editor` (`play`, `stop`) | Core Tools |

Se activan en **Window > MCP for Unity > Tools**. Pulsa **Reconfigure** / **Rescan** si aparece.

> [!WARNING] Sin Roslyn
> `execute_code` compila C# 6: escribe `UnityEngine.Object` (no `Object`) y nada de sintaxis nueva.

> [!NOTE]
> Claude Code pide permiso antes de cada `execute_code` porque ejecuta cualquier C# en tu Editor. Para quitarlo, añade `"mcp__unityMCP__execute_code"` a `permissions.allow` en `.claude/settings.json`, sabiéndolo.
