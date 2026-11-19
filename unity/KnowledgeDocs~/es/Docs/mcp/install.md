# Instalar MCP for Unity

**Opcional.** Deja que el agente compile, testee y construya prefabs con el Editor abierto. La guía completa, con solución de problemas, está en `docs/MCP_FOR_UNITY.md` de las reglas.

1. **`uv` instalado** (`uv --version`). macOS: `brew install uv`.
1. **Window > Package Manager > + > Add package from git URL:**
   `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity`
1. **Cierra Unity** y ejecuta `bash .ai/templates/scripts/install.sh --mcp`. Escribe `.mcp.json`.
1. **Abre Unity, Window > MCP for Unity:** HTTP Local, **Start Server**, y activa **Core Tools**, **Testing** y **Scripting Extensions** (ver [Configurar MCP for Unity](doc:mcp.setup)).
1. **Abre Claude Code** en la raíz del proyecto y aprueba `unityMCP`. `/mcp` debería mostrarlo conectado.

> [!WARNING]
> No pulses también **Register with Claude Code** en la ventana: `.mcp.json` ya lo registra y tendrías dos servidores.

> [!TIP]
> ¿Problemas? Mira [Problemas con MCP](doc:mcp.troubleshooting).
