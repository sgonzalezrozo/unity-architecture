# Installation

Step by step, from a new, empty Unity project to Claude Code building a feature that passes every check. It takes about 20 minutes, most of it waiting for Unity.

When you're done you'll have:

- The rules in a `.ai` folder (a Git submodule), plus the small entry files that Claude Code, Cursor, Copilot and Rider read.
- The analyzers, which turn the mechanical rules into compile errors in `Assets/Client`.
- The `com.sgonzalezrozo.unity-architecture` package from `.ai/unity`: the prefab recipes, the specs, the prefab validator, and the reporters that write each compile and test run to `Logs/verify/`.
- MCP for Unity, so the agent can compile, test and build prefabs in the open Editor.
- A Claude Code Stop hook that won't let the agent finish with a broken build.

Already have a project? Skip step 1 and start at step 2. For updating, cloning and installing by hand, see the [README](../README.md#use-it-in-a-project).

## What you need

| Tool | Why | Check |
|---|---|---|
| Unity 6 (`6000.0` or later; written against `6000.3`), installed with Unity Hub | The project | Unity Hub > Installs |
| Git | The submodule, and the scripts' change detection | `git --version` |
| A Bash shell | The install, update and verify scripts. On Windows, Git Bash | `bash --version` |
| Claude Code | The agent: the CLI, the desktop app or an IDE extension | `claude --version` |
| `uv` (it brings Python 3.10+ when needed) | MCP for Unity runs its server with `uvx` | `uv --version` |

Install the missing ones. On macOS, with Homebrew:

```bash
brew install git uv
```

On macOS or Linux without Homebrew, `uv`:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Claude Code, on macOS or Linux:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

On Windows, install [Git for Windows](https://git-scm.com/download/win) (it includes Git Bash), and `uv` from PowerShell:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

## 1. Create the Unity project

1. In Unity Hub, click **New project**, choose a Unity 6 editor and a template (**Universal 2D** or **Universal 3D** both work; the rules cover uGUI, so the pipeline doesn't matter), name it and create it.
2. When it opens, check **Window > Package Manager > In Project** for these packages. New Unity 6 projects usually have them already:
   - **Test Framework** (`com.unity.test-framework`). Without it, the verify scripts only compile and the prefab validator can't run.
   - **Unity UI** (`com.unity.ugui`), which includes TextMeshPro.
3. Import the TextMeshPro fonts: **Window > TextMeshPro > Import TMP Essential Resources**. Prefabs built from specs use TextMeshPro, and without these resources their text has no font.
4. Close Unity. The next steps change `Packages/manifest.json`, and the first check runs in batch mode, which can't open a project the Editor has open.

## 2. Make the project a Git repository

Open a terminal at the **project root**, the folder that holds `Assets`, `Packages` and `ProjectSettings`:

```bash
cd ~/Projects/MyGame
```

Add a Unity `.gitignore` before the first commit, so `Library`, `Temp` and the generated files stay out:

```bash
curl -L https://raw.githubusercontent.com/github/gitignore/main/Unity.gitignore -o .gitignore
```

Then create the repository and commit the empty project:

```bash
git init
```

```bash
git add .
```

```bash
git commit -m "Initial commit"
```

Skip this step if `git status` already works in the project.

## 3. Add the rules as a submodule

```bash
git submodule add https://github.com/sgonzalezrozo/unity-architecture-agents.git .ai
```

You now have a `.ai` folder next to `Assets`, with `AGENTS.md`, `architecture`, `templates`, `analyzers` and `unity` inside. Unity ignores folders whose names start with a dot, so it never imports `.ai` or creates `.meta` files for it.

## 4. Run the install script

```bash
bash .ai/templates/scripts/install.sh
```

It creates the files assistants read from fixed paths, copies the analyzers, writes `.mcp.json` and `.claude/settings.json`, and adds the rules' package to `Packages/manifest.json`. The [README](../README.md#3-put-the-entry-files-at-the-root) lists every file it creates. Files that already exist are kept, so it's safe to run again.

At the end it asks: **"Run scripts/verify.sh now?"** Answer `y`. With Unity closed, it opens the project once in batch mode, imports it, compiles it and runs the EditMode tests. The first run can take several minutes; later ones are quick. It ends with an exit code: `0` passed, `1` failed, `2` couldn't run.

- Exit code `2` with "Unity not found": the script looks for the version in `ProjectSettings/ProjectVersion.txt` in Unity Hub's install folder. Set `UNITY_PATH` to the Unity executable and run it again:

```bash
UNITY_PATH="/Applications/Unity/Hub/Editor/6000.3.0f1/Unity.app/Contents/MacOS/Unity" scripts/verify.sh
```

- "Analyzers not installed": `Assets/Client` already had code but no `Client.asmdef`. Add the assembly definition and run the script again (see [Feature structure](../architecture/FEATURE_STRUCTURE.md#assembly-definitions)).

## 5. Add MCP for Unity

MCP for Unity (by Coplay) is a Unity package plus a small local server. Claude Code talks to the server on `localhost`, and the server talks to the open Editor. Nothing leaves your machine.

1. Open the project in Unity.
2. **Window > Package Manager > + > Add package from git URL**, and paste:

   ```text
   https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity
   ```

3. Wait for the import and compile to finish.

## 6. Set up MCP for Unity

This is the part the install script can't do for you. Open **Window > MCP for Unity** (`Cmd+Shift+M` on macOS, `Ctrl+Shift+M` on Windows and Linux). Labels can change a little between MCP for Unity versions.

1. **Dependencies.** The window checks Python and `uv`. If one is missing, install it (see [What you need](#what-you-need)) and click **Verify again**.
2. **Transport: HTTP Local.** In the connection section, choose **HTTP Local**. `.mcp.json` registers the server for Claude Code as `unityMCP` on `http://localhost:8080/mcp`, MCP for Unity's default HTTP address. If you change the port, change it in `.mcp.json` too.
3. **Start the server.** Click **Start Server** (or **Start Local HTTP Server**), and make sure the Unity bridge shows **Running**. In Auto mode it starts by itself with the Editor.
4. **Turn on the tool groups the rules use.** In the **Tools** section, enable:
   - **Core Tools**, usually on already: `refresh_unity`, `read_console`, `manage_scene`, `manage_editor`, `manage_prefabs`.
   - **Testing**: `run_tests` and `get_test_job`. Without them the agent can't run tests in the Editor, and the Stop hook keeps asking for them.
   - **Scripting Extensions**: `execute_code`. The agent builds prefabs through it with `PrefabSpecs.BuildFromSpec` (`EDIT-11`), and validates them with `PrefabValidator.ValidateAsset` (`EDIT-12`).

   Click **Reconfigure** or **Rescan** if the window offers it, so the server picks up the change.
5. **Optional: install Roslyn.** In the dependencies list, **Roslyn (C# 12+ Compiler)** lets `execute_code` compile modern C#. Without it, `execute_code` falls back to C# 6 (CodeDom): agents must write `UnityEngine.Object` instead of `Object`, and can't use newer syntax. The rules work either way.
6. **Don't also register the server from the window.** `.mcp.json` already registers `unityMCP` for this project. If you click **Register with Claude Code** too, Claude Code sees two servers with the same tools. If you prefer the window's registration, delete the `unityMCP` entry from `.mcp.json`, and keep the name `unityMCP`: `.claude/settings.json` allows tools named `mcp__unityMCP__*`.

## 7. Connect Claude Code

1. Keep Unity open, with the server running.
2. Open Claude Code at the project root:

```bash
claude
```

3. Claude Code asks whether to use the MCP servers in `.mcp.json`. Approve `unityMCP`.
4. Check the connection: `/mcp` should list `unityMCP` as connected. If it doesn't, check that the Editor is open, the server is started and the port matches `.mcp.json`.
5. Ask Claude Code to check the setup. It reads the rules, detects the capabilities and runs the checks:

```text
Check that this project is set up for the .ai rules: run capability detection and editor tool detection, refresh Unity, read the Console, run the prefab validator test, and tell me what each tool verified.
```

You should see `editorBridge`, `verifyScript` and `prefabTools` as `true`, a clean compile, and `ClientPrefabsTests` passing (with no prefabs yet, it has nothing to fail on).

`.claude/settings.json` lets the agent run `verify.sh`, `verify-editor.sh`, read-only `git` commands and the read-only Unity tools (`read_console`, `refresh_unity`, `run_tests`, `get_test_job`) without asking each time. Claude Code still asks before `execute_code`, because it runs any C# in your Editor. To stop the prompts, add `"mcp__unityMCP__execute_code"` to `permissions.allow` yourself, knowing that.

## 8. Commit

```bash
git add .
```

```bash
git commit -m "Add Unity Architecture Agents and MCP for Unity"
```

This commits the entry files, `.gitmodules` (the `.ai` version the project uses), the analyzers, `Assets/Client`, `.mcp.json`, `.claude` and the manifest change. `Logs/` stays out: the default Unity `.gitignore` ignores it.

## 9. Finish in your other tools

- **Rider:** open `.aiassistant/rules/project.md` and set the rule's type to **Always**.
- **Rules for this project only** (the scene loader, the localization system, naming that only this project uses): write them in the root `AGENTS.md`, under "Rules for this project only". Never edit files inside `.ai`: the next update overwrites them.
- **A hook that watches more:** the copied hook in `.claude/hooks/verify-on-stop.sh` can be changed, for example to also watch local packages. `update.sh` keeps a changed copy and lists it for you to merge.

## Next

- [Usage](USAGE.md): prompts that work, with the Editor open or closed, and what the agent does with each.
- [Editor tools](../architecture/EDITOR_TOOLS.md): which tool verifies what.
- [Prefabs](../architecture/PREFABS.md): the prefab rules, the recipes and the JSON spec.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `.ai` is empty after cloning | Submodules aren't cloned by default. Run `git submodule update --init` |
| `install.sh`: "doesn't look like a Unity project" | Run it from the project root, and `.ai` must sit next to `Assets` |
| `/mcp` doesn't list `unityMCP`, or it's disconnected | Open the Editor, start the server in **Window > MCP for Unity**, and check that the port matches `.mcp.json` |
| The agent says `run_tests` or `execute_code` doesn't exist | Turn on the **Testing** and **Scripting Extensions** tool groups (step 6), then restart Claude Code |
| Two Unity servers in `/mcp` | The server is registered both in `.mcp.json` and from the window. Keep one (step 6) |
| `execute_code`: "`Object` is an ambiguous reference" | It's compiling as C# 6. Write `UnityEngine.Object`, or install Roslyn (step 6) |
| Prefab texts show no font | TMP Essential Resources aren't imported (step 1) |
| The hook says Unity "hasn't compiled the latest script changes", or "the full EditMode suite is due" | Expected with the Editor open: the agent runs `refresh_unity` or `run_tests` and stops again |
| The hook says it can't check | With the Editor closed, `verify.sh` couldn't find Unity: set `UNITY_PATH`. With it open, the reporters haven't written `Logs/verify/` yet: ask the agent to refresh Unity |
| `verify.sh` fails with "another Unity instance is running" | Batch mode can't open a project the Editor has open. Close the Editor, or work with it open through MCP |
| The analyzers don't run | They check only the assembly named `Client`. Code must be under `Assets/Client`, next to `Client.asmdef` |
