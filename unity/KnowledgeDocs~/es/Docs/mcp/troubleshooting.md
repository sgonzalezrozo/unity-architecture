# Problemas frecuentes con MCP

| Síntoma | Causa y arreglo |
|---|---|
| `/mcp` no lista `unityMCP` | Abre el Editor, arranca el servidor en **Window > MCP for Unity** y revisa el puerto de `.mcp.json` |
| El agente dice que `run_tests` o `execute_code` no existen | Activa los grupos **Testing** y **Scripting Extensions** y reinicia Claude Code |
| Dos servidores Unity en `/mcp` | Registrado en `.mcp.json` y desde la ventana: deja uno |
| `execute_code`: "`Object` is an ambiguous reference" | Compila como C# 6: escribe `UnityEngine.Object` o instala Roslyn |
| Los textos del prefab no tienen fuente | Faltan las TMP Essential Resources |
| `verify.sh`: "another Unity instance is running" | Batch no abre un proyecto abierto: cierra el Editor o trabaja por MCP |
