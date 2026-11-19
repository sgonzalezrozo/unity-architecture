# Install MCP for Unity

**Optional.** It lets the agent compile, test and build prefabs with the Editor open. The full guide, with troubleshooting, is `docs/MCP_FOR_UNITY.md` in the rules.

1. **`uv` installed** (`uv --version`). macOS: `brew install uv`.
1. **Window > Package Manager > + > Add package from git URL:**
   `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity`
1. **Close Unity** and run `bash .ai/templates/scripts/install.sh --mcp`. It writes `.mcp.json`.
1. **Open Unity, Window > MCP for Unity:** HTTP Local, **Start Server**, and turn on **Core Tools**, **Testing** and **Scripting Extensions** (see [Set up MCP for Unity](doc:mcp.setup)).
1. **Open Claude Code** at the project root and approve `unityMCP`. `/mcp` should show it connected.

> [!WARNING]
> Don't also click **Register with Claude Code** in the window: `.mcp.json` already registers it, and you'd get two servers.

> [!TIP]
> Problems? See [MCP troubleshooting](doc:mcp.troubleshooting).
