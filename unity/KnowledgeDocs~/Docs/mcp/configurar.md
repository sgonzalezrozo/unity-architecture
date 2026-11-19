# Configurar MCP for Unity

MCP for Unity es un package de Unity más un servidor local. Claude Code habla con el servidor en `localhost`, y el servidor con el Editor abierto. Nada sale de tu máquina.

> [!TIP] Atajo
> **Window > MCP for Unity** — `Cmd+Shift+M` (macOS) / `Ctrl+Shift+M` (Windows, Linux)

1. **Dependencias:** la ventana comprueba Python y `uv`.
1. **Transport: HTTP Local.** `.mcp.json` registra el servidor como `unityMCP` en `http://localhost:8080/mcp`.
1. **Start Server**, y comprueba que el bridge diga **Running**.
1. **Activa los grupos de tools** (ver [Tools que usan las reglas](doc:mcp.tools)).
1. **Opcional: Roslyn.** Sin él, `execute_code` compila C# 6.
1. **No registres el servidor también desde la ventana:** `.mcp.json` ya lo hace; tendrías dos servidores iguales.

En Claude Code, `/mcp` debe listar `unityMCP` como conectado.
