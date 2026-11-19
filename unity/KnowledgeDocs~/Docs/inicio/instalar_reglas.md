# Instalar las reglas en un proyecto

Unos 20 minutos, casi todo esperando a Unity.

| Necesitas | Para qué |
|---|---|
| Unity 6 (`6000.0`+) | El proyecto, con **Test Framework** y **Unity UI** |
| Git y Bash | El submódulo y los scripts (en Windows, Git Bash) |
| Claude Code | El agente |
| `uv` | MCP for Unity lanza su servidor con `uvx` |

1. Importa las fuentes de TMP: **Window > TextMeshPro > Import TMP Essential Resources**. Cierra Unity.
1. Haz el proyecto repositorio Git (con el `.gitignore` de Unity).
1. Añade las reglas como submódulo:

```bash
git submodule add https://github.com/sgonzalezrozo/unity-architecture-agents.git .ai
```

4. Ejecuta el instalador: crea los archivos de entrada, copia los analyzers, escribe `.mcp.json` y añade este package al manifest.

```bash
bash .ai/templates/scripts/install.sh
```

5. Responde `y` a **"Run scripts/verify.sh now?"**: compila y corre los tests en batch.
1. Instala y configura **MCP for Unity** (ver [Configurar MCP for Unity](doc:mcp.configurar)).

> [!TIP]
> Al clonar un proyecto que ya lo tiene: `git submodule update --init`.
