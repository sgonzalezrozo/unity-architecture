# MCP troubleshooting

| Symptom | Cause and fix |
|---|---|
| `/mcp` doesn't list `unityMCP` | Open the Editor, start the server in **Window > MCP for Unity**, and check the port in `.mcp.json` |
| The agent says `run_tests` or `execute_code` doesn't exist | Turn on the **Testing** and **Scripting Extensions** groups and restart Claude Code |
| Two Unity servers in `/mcp` | Registered both in `.mcp.json` and from the window: keep one |
| `execute_code`: "`Object` is an ambiguous reference" | It compiles as C# 6: write `UnityEngine.Object` or install Roslyn |
| Prefab texts have no font | TMP Essential Resources aren't imported |
| `verify.sh`: "another Unity instance is running" | Batch mode can't open an open project: close the Editor or work through MCP |
