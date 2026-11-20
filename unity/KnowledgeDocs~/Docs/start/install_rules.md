# Install the rules in a project

About 20 minutes, most of it waiting for Unity.

| You need | Why |
|---|---|
| Unity 6 (`6000.0`+) | The project, with **Test Framework** and **Unity UI** |
| Git and Bash | The submodule and the scripts (Git Bash on Windows) |
| Claude Code | The agent |
| `uv` | MCP for Unity runs its server with `uvx` |

1. Import the TMP fonts: **Window > TextMeshPro > Import TMP Essential Resources**. Close Unity.
1. Make the project a Git repository, with Unity's `.gitignore`.
1. Add the rules as a submodule:

```bash
git submodule add https://github.com/sgonzalezrozo/unity-architecture-agents.git .ai
```

4. Run the install script. It creates the entry files and adds this package to the manifest. It asks whether to also install the optional analyzers (default: no).

```bash
bash .ai/templates/scripts/install.sh
```

> [!WARNING] On Windows
> Run it in Git Bash, or from PowerShell or cmd with `.ai\templates\scripts\install.cmd`. A plain `bash` there is WSL's, which fails with "no installed distributions".

5. Answer `y` to **"Run scripts/verify.sh now?"** with Unity closed: it compiles and runs the tests in batch mode. A new project reports **50 tests**: they test the rules and their tools (the prefab validator, specs and recipes), not your code. Only one checks your project: that the prefabs in `Assets/Client` follow the prefab rules.
1. Optional: install and set up **MCP for Unity** (see [Install MCP for Unity](doc:mcp.install)).

> [!TIP]
> When you clone a project that already has it: `git submodule update --init`.
