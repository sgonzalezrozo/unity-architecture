# Set up MCP for Unity

MCP for Unity is a Unity package plus a local server. Claude Code talks to the server on `localhost`, and the server talks to the open Editor. Nothing leaves your machine. It's **optional**: without it, the agent writes a prefab spec and you build it with **Assets > Unity Architecture > Build Prefab From Spec**.

> [!TIP] Shortcut
> **Window > MCP for Unity** — `Cmd+Shift+M` (macOS) / `Ctrl+Shift+M` (Windows, Linux)

1. **Dependencies:** the window checks Python and `uv`.
1. **Transport: HTTP Local.** `.mcp.json` registers the server as `unityMCP` on `http://localhost:8080/mcp` (`install.sh --mcp` writes it).
1. **Start Server**, and check the bridge says **Running**.
1. **Turn on the tool groups** (see [Tools the rules use](doc:mcp.tools)).
1. **Optional: Roslyn.** Without it, `execute_code` compiles C# 6.
1. **Don't also register the server from the window:** `.mcp.json` already does; you'd get two identical servers.

In Claude Code, `/mcp` should list `unityMCP` as connected.
