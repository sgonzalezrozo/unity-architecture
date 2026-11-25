# Installation

Step by step, from a new, empty Unity project to Claude Code building a feature that passes every check. It takes about 20 minutes, most of it waiting for Unity.

When you're done you'll have the rules in a `.ai` folder (a Git submodule): the architecture, the examples and the good practices. They're documents: read them in `.ai/`, or in the Editor with **Tools > Unity Architecture > Rules Guide**. Their install adds only `.editorconfig` and the Rules Guide package, and nothing reads them by default.

An AI reads and follows them through a separate, optional enforcement package (private for now), installed next to them as `.ai-enforcement`. It adds the instruction files for Claude Code, Cursor, Copilot and Rider, the hooks, the checks and the prefab tools, and runs this install first. Steps 5 to 9 below are for working with it.

Already have a project? Skip step 1 and start at step 2. For updating, cloning and installing by hand, see the [Setup Reference](REFERENCE.md).

## What you need

| Tool | Why | Check |
|---|---|---|
| Unity 6 (`6000.0` or later; written against `6000.3`), installed with Unity Hub | The project | Unity Hub > Installs |
| Git | The submodule, and the scripts' change detection | `git --version` |
| A Bash shell | The install, update and verify scripts. On Windows, Git Bash | `bash --version` |
| Claude Code | The agent: the CLI, the desktop app or an IDE extension | `claude --version` |
| `uv` (it brings Python 3.10+ when needed) | Only for MCP for Unity, which runs its server with `uvx` | `uv --version` |

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
git submodule add https://github.com/sgonzalezrozo/unity-architecture.git .ai
```

You now have a `.ai` folder next to `Assets`, with `AGENTS.md`, `architecture`, `docs` and `unity` inside. Unity ignores folders whose names start with a dot, so it never imports `.ai` or creates `.meta` files for it.

## 4. Run the install script

```bash
bash .ai/templates/scripts/install.sh
```

**On Windows**, run the scripts in Git Bash, or call the `.cmd` launcher from PowerShell or cmd: `.ai\templates\scripts\install.cmd`. A plain `bash` in PowerShell or cmd is WSL's launcher, which fails with "Windows Subsystem for Linux has no installed distributions".

It adds `.editorconfig` and the Rules Guide package (`com.sgonzalezrozo.unity-architecture`, from `.ai/unity`) to `Packages/manifest.json`. A `.editorconfig` you already have is asked about: `[r]` replaces it (the old one is kept as `.editorconfig.bak`), `[s]` skips it. That's all the rules install: open the project and read them in **Tools > Unity Architecture > Rules Guide**.

With the enforcement package, run its install instead (`bash .ai-enforcement/templates/scripts/install.sh`): it runs this one first, then adds the instruction files, the hooks and the checks, and its README says the rest. Your project's own rules go in `PROJECT_RULES.md`, which it creates and never changes. The AI context it generates in `Logs/ai/` is never committed: keep `Logs/` in `.gitignore`.

## 5. Optional: add MCP for Unity

Steps 5 to 9 are for working with an AI agent, through the enforcement package.

The same steps, on one page: [MCP for Unity: installation guide](MCP_FOR_UNITY.md).

MCP for Unity (by Coplay) is a Unity package plus a small local server. Claude Code talks to the server on `localhost`, and the server talks to the open Editor. Nothing leaves your machine.

1. Open the project in Unity.
2. **Window > Package Manager > + > Add package from git URL**, and paste:

   ```text
   https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity
   ```

3. Wait for the import and compile to finish.
4. Close Unity, and register the server for Claude Code:

```bash
bash .ai/templates/scripts/install.sh --mcp
```

It writes `.mcp.json` and keeps everything else as it is.

## 6. Optional: set up MCP for Unity

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

**Without MCP for Unity**, close Unity, open Claude Code at the project root (`claude`), and ask it to check the setup:

```text
Check that this project is set up for the .ai rules: read the project profile (Logs/ai/profile.md) and list its forks and capabilities, run scripts/verify.sh, and tell me what each tool verified.
```

You should see `verifyScript` and `prefabTools` as `true` and `editorBridge` as `false`, and `verify.sh` passing. That's the whole setup.

**With MCP for Unity:**

1. Keep Unity open, with the server running.
2. Open Claude Code at the project root:

```bash
claude
```

3. Claude Code asks whether to use the MCP servers in `.mcp.json`. Approve `unityMCP`.
4. Check the connection: `/mcp` should list `unityMCP` as connected. If it doesn't, check that the Editor is open, the server is started and the port matches `.mcp.json`.
5. Ask Claude Code to check the setup. It reads the rules, detects the capabilities and runs the checks:

```text
Check that this project is set up for the .ai rules: read the project profile (Logs/ai/profile.md) and list its forks and capabilities, refresh Unity, read the Console, run the prefab validator test, and tell me what each tool verified.
```

You should see `editorBridge`, `verifyScript` and `prefabTools` as `true`, a clean compile, and `ClientPrefabsTests` passing (with no prefabs yet, it has nothing to fail on).

`.claude/settings.json` lets the agent run `verify.sh`, `verify-editor.sh`, read-only `git` commands and the read-only Unity tools (`read_console`, `refresh_unity`, `run_tests`, `get_test_job`) without asking each time. Claude Code still asks before `execute_code`, because it runs any C# in your Editor. To stop the prompts, add `"mcp__unityMCP__execute_code"` to `permissions.allow` yourself, knowing that.

It also adds the timing hooks: each prompt ends with its stages and their seconds on screen, and `Logs/agent-timing/` keeps one log per session, with no prompt text, tool arguments or file contents ([Timing](USAGE.md#timing)). An existing `settings.json` is kept, so merge the `log-timing.sh` hooks from `.ai/templates/claude/settings.json` into it.

## 8. Commit

```bash
git add .
```

```bash
git commit -m "Add Unity Architecture"
```

This commits the entry files, `.gitmodules` (the `.ai` version the project uses), the analyzers, `Assets/Client`, `.claude`, `.mcp.json` if you added MCP for Unity, and the manifest change. `Logs/` stays out: the default Unity `.gitignore` ignores it.

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
| Windows: "Windows Subsystem for Linux has no installed distributions" | `bash` in PowerShell or cmd is WSL's. Run the script in Git Bash, or use `.ai\templates\scripts\install.cmd` (or `update.cmd`) |
| `ScriptableSingleton already exists` or `assets located in immutable packages were unexpectedly altered` after adding packages (such as Screen System) | A package was added while Unity was still importing another. Nothing is broken: clear the Console. Add Tools Core first and wait for the compile before adding the next package. If they come back when you open the project without adding a package, report it |
| `install.sh`: "doesn't look like a Unity project" | Run it from the project root, and `.ai` must sit next to `Assets` |
| `/mcp` doesn't list `unityMCP`, or it's disconnected | Open the Editor, start the server in **Window > MCP for Unity**, and check that the port matches `.mcp.json` |
| The agent says `run_tests` or `execute_code` doesn't exist | Turn on the **Testing** and **Scripting Extensions** tool groups (step 6), then restart Claude Code |
| Two Unity servers in `/mcp` | The server is registered both in `.mcp.json` and from the window. Keep one (step 6) |
| `execute_code`: "`Object` is an ambiguous reference" | It's compiling as C# 6. Write `UnityEngine.Object`, or install Roslyn (step 6) |
| Prefab texts show no font | TMP Essential Resources aren't imported (step 1) |
| The hook says Unity "hasn't compiled the latest script changes", or "the full EditMode suite is due" | Expected with the Editor open: the agent runs `refresh_unity` or `run_tests` and stops again |
| The hook says it can't check | With the Editor closed, `verify.sh` couldn't find Unity: set `UNITY_PATH`. With it open, the reporters haven't written `Logs/verify/` yet: ask the agent to refresh Unity |
| `verify.sh` fails with "another Unity instance is running" | Batch mode can't open a project the Editor has open. Close the Editor, or work with it open through MCP |
| The analyzers don't run | They're optional: install them with `install.sh --analyzers`. They check only the assembly named `Client`, so code must be under `Assets/Client`, next to `Client.asmdef` |
