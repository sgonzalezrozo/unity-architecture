# Tools the rules use

| Need | Tool | Group |
|---|---|---|
| Compile, read errors | `refresh_unity`, `read_console` | **Core Tools** (on by default) |
| Run tests | `run_tests`, `get_test_job` | **Testing** (<color=#D29922>off by default</color>) |
| Build and check prefabs | `execute_code` | **Scripting Extensions** (<color=#D29922>off by default</color>) |
| Play mode | `manage_editor` (`play`, `stop`) | Core Tools |

Turn them on in **Window > MCP for Unity > Tools**. Click **Reconfigure** / **Rescan** if offered.

> [!WARNING] Without Roslyn
> `execute_code` compiles C# 6: write `UnityEngine.Object` (not `Object`) and no newer syntax.

> [!NOTE]
> Claude Code asks before each `execute_code`, because it runs any C# in your Editor. To stop the prompts, add `"mcp__unityMCP__execute_code"` to `permissions.allow` in `.claude/settings.json`, knowing that.
