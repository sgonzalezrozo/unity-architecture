# MCP for Unity: installation guide

[MCP for Unity](https://github.com/CoplayDev/unity-mcp) (by Coplay) lets the agent work with the Unity Editor open: compile, read the Console, run tests and build prefabs. It's a Unity package plus a small local server. Claude Code talks to the server on `localhost`, and the server talks to the open Editor. Nothing leaves your machine.

It's **optional**. Without it, the agent verifies in batch mode with `scripts/verify.sh` (close the Editor while it works), and writes a prefab spec that you build with **Assets > Unity Architecture > Build Prefab From Spec**.

## 1. What you need

| Tool | Check | Install |
|---|---|---|
| The rules installed in the project ([Installation](INSTALLATION.md)) | `.ai/` next to `Assets/` | `bash .ai/templates/scripts/install.sh` |
| `uv` (brings Python 3.10+ when needed) | `uv --version` | macOS: `brew install uv`. Linux/macOS: `curl -LsSf https://astral.sh/uv/install.sh \| sh`. Windows (PowerShell): `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 \| iex"` |
| Claude Code | `claude --version` | [claude.ai/code](https://claude.ai/code) |

## 2. Add the package

1. Open the project in Unity.
2. **Window > Package Manager > + > Add package from git URL**, and paste:

   ```text
   https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity
   ```

3. Wait for the import and compile to finish.

## 3. Register the server for Claude Code

Close Unity, then from the project root:

```bash
bash .ai/templates/scripts/install.sh --mcp
```

It writes `.mcp.json`, which registers the server as `unityMCP` on `http://localhost:8080/mcp`, and keeps every other file as it is.

## 4. Set it up in the Editor

Open Unity and **Window > MCP for Unity** (`Cmd+Shift+M` on macOS, `Ctrl+Shift+M` on Windows and Linux). Labels can change a little between versions.

1. **Dependencies.** The window checks Python and `uv`. If one is missing, install it and click **Verify again**.
2. **Transport: HTTP Local.** If you change the port, change it in `.mcp.json` too.
3. **Start Server**, and check that the Unity bridge shows **Running**. In Auto mode it starts with the Editor.
4. **Tool groups.** In **Tools**, turn on:
   - **Core Tools** (usually on): `refresh_unity`, `read_console`, `manage_scene`, `manage_editor`, `manage_prefabs`.
   - **Testing**: `run_tests`, `get_test_job`.
   - **Scripting Extensions**: `execute_code`, which builds and validates prefabs.

   Click **Reconfigure** or **Rescan** if the window offers it.
5. **Optional: Roslyn (C# 12+ Compiler).** Without it, `execute_code` compiles C# 6. The rules work either way.
6. **Don't click Register with Claude Code.** `.mcp.json` already registers the server; doing both gives two identical servers.

## 5. Connect and check

1. Keep Unity open, with the server running.
2. Open Claude Code at the project root (`claude`) and approve `unityMCP` when it asks about the servers in `.mcp.json`.
3. `/mcp` should list `unityMCP` as connected.
4. Ask it to check the setup:

   ```text
   Check that this project is set up for the .ai rules: run capability detection and editor tool detection, refresh Unity, read the Console, run the prefab validator test, and tell me what each tool verified.
   ```

   You should see `editorBridge`, `verifyScript` and `prefabTools` as `true` and a clean compile.

Claude Code asks before each `execute_code`, because it runs any C# in your Editor. To stop the prompts, add `"mcp__unityMCP__execute_code"` to `permissions.allow` in `.claude/settings.json`, knowing that.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `/mcp` doesn't list `unityMCP`, or it's disconnected | Open the Editor, start the server, and check the port matches `.mcp.json` |
| `run_tests` or `execute_code` doesn't exist | Turn on the **Testing** and **Scripting Extensions** tool groups, then restart Claude Code |
| Two Unity servers in `/mcp` | The server is registered in `.mcp.json` and from the window. Keep one |
| `execute_code`: "`Object` is an ambiguous reference" | It's compiling as C# 6. Write `UnityEngine.Object`, or install Roslyn |
| `verify.sh` fails with "another Unity instance is running" | Expected with the Editor open: the agent uses MCP instead, or close the Editor |
