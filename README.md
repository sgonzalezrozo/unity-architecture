# Unity Architecture Agents

**Architecture rules and a working process for AI coding assistants on Unity projects.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Unity Architecture Agents is a free, open-source `AGENTS.md` and `CLAUDE.md` rule set for AI coding agents on Unity 6 projects. It gives agents a strict MVC architecture for uGUI, Roslyn analyzers that turn the rules into compile errors, a batch-mode verify script, and a Claude Code hook that won't let an agent finish with a broken build. Templates cover Cursor, GitHub Copilot and Rider AI Assistant. It works with Unity MCP servers and the Unity CLI.

## What's included

| File | Purpose |
|---|---|
| [AGENTS.md](AGENTS.md) | Entry point: stack, philosophy and where to read next |
| [Developer overview](architecture/DEVELOPER_OVERVIEW.md) | One-file summary for human developers |
| [Agent workflow](architecture/AGENT_WORKFLOW.md) | Task classification, plan format, checklist, Definition of Done and Git |
| [MVC](architecture/MVC.md) | How Models, Views and Controllers work together |
| [Feature structure](architecture/FEATURE_STRUCTURE.md) | Folders, naming, and screen composition |
| [Dependency injection](architecture/DEPENDENCY_INJECTION.md) | Bindings, installers and references |
| [Backend integration](architecture/BACKEND_INTEGRATION.md) | How features talk to a backend |
| [UI patterns](architecture/UI_PATTERNS.md) | Clickable elements, visual states, tabs, lists and layouts |
| [Optional packages](architecture/OPTIONAL_PACKAGES.md) | How an agent detects optional packages and adapts its code |
| [C# standards](architecture/CSHARP_STANDARDS.md) | Style, performance, async, logging and tests |
| [Editor tools](architecture/EDITOR_TOOLS.md) | How an agent verifies its work with Unity MCP, the Unity CLI or `verify.sh` |
| [Examples](architecture/examples) | Three complete features with invented names: a backend feature, custom input and a filtered list |
| [Templates](templates) | `.editorconfig`, Copilot, Cursor and Rider rules, `verify.sh`, a Claude Code Stop hook, and `install.sh` and `update.sh` to put them in your project and keep them current |
| [Analyzers](analyzers) | Roslyn analyzers that turn the mechanical rules into compile errors |

## How the process scales

| Request | Process |
|---|---|
| Question, explanation, review | Answer directly |
| Small change inside existing classes | Make the change and summarize it |
| New feature, screen, class family or refactor | Plan first, wait for approval |

Before returning code, the agent runs the [pre-response checklist](architecture/AGENT_WORKFLOW.md#pre-response-checklist). The [analyzers](analyzers) turn the mechanical items into compile errors.

## Use it in a project

Five steps, about five minutes. You need Git, and a terminal open at your **project root**: the folder that holds `Assets`, `Packages` and `ProjectSettings`. On Windows, use Git Bash.

### 1. Make sure the project is a Git repository

If `git status` says "not a git repository", create one first:

```bash
git init
git add .
git commit -m "Initial commit"
```

Add a Unity `.gitignore` before that first commit, so `Library` and `Temp` stay out.

### 2. Add the rules

```bash
git submodule add https://github.com/sgonzalezrozo/unity-architecture-agents.git .ai
```

You now have a folder named `.ai` next to `Assets`, with `AGENTS.md`, `architecture`, `templates` and `analyzers` inside. Unity ignores folders that start with a dot, so it never imports `.ai` or creates `.meta` files for it.

### 3. Put the entry files at the root

Assistants only read instructions from fixed places in your project, and a submodule can only add its own folder. This script puts small entry files there, pointing to `.ai`:

```bash
bash .ai/templates/scripts/install.sh
```

Run it from a terminal; double-clicking a `.sh` file opens it in an editor on most systems. Your project root now has:

| File | Read by | What it is |
|---|---|---|
| `AGENTS.md` | Codex, Cursor and most agents | Points to `.ai/AGENTS.md`, and holds rules for this project only |
| `CLAUDE.md` | Claude Code | Loads `.ai/AGENTS.md` and your `AGENTS.md` |
| `.github/copilot-instructions.md` | GitHub Copilot | Points to `.ai/AGENTS.md`, with the core rules in case nothing else loads |
| `.aiassistant/rules/project.md` | Rider AI Assistant | The same, for Rider |
| `.cursor/rules/unity-architecture.mdc` | Cursor | The same, for Cursor |
| `.editorconfig` | Rider, Visual Studio | Formatting, `var`, braces and naming |
| `scripts/verify.sh` | Agents, CI | Compiles in batch mode, runs EditMode tests, checks Fast IoC generation |
| `scripts/verify-editor.sh` | Agents, the hook | Checks the project while the Editor is open, from the results the Editor writes |
| `Assets/Editor/UnityArchitecture/` | Unity | Writes each compile and test run in the open Editor to `Logs/verify/` |
| `.mcp.json` | Claude Code | Registers a local Unity MCP server (MCP for Unity) on `localhost:8080`. Never replaced |
| `.claude/hooks/verify-on-stop.sh`, `.claude/settings.json` | Claude Code | Runs `verify.sh` when the agent finishes and sends failures back. Also allows `verify.sh` and read-only `git` commands, so Claude doesn't ask for each one |
| `Assets/Client/Analyzers/UnityArchitecture.Analyzers.dll` | Unity | The [analyzers](analyzers): the mechanical rules become compile errors. Prebuilt, so no .NET SDK needed |
| `Assets/Client/Client.asmdef` | Unity | Only when `Assets/Client` doesn't exist yet. The analyzers check this assembly only, not third-party code |

Files that already exist are kept, so running it again is safe. If your project already had a `.claude/settings.json`, the script says so: add the Stop hook and the allowed commands from `.ai/templates/claude/settings.json` to it yourself. If `Assets/Client` already has code but no `Client.asmdef`, the analyzers aren't installed, and the script says why.

At the end it offers to run `scripts/verify.sh` once. Say yes, with the project closed in Unity: the first batch-mode run imports the whole project, which can take longer than the hook waits, and later runs are quick. `--verify` runs it without asking, `--no-verify` skips it.

### 4. Commit

```bash
git add .
git commit -m "Add Unity Architecture Agents"
```

This commits the files above and `.gitmodules`, which records the `.ai` version your project uses.

### 5. Finish in your tools

- **Rider:** open `.aiassistant/rules/project.md` and set the rule's type to **Always**.
- **Rules for this project only:** write them in your root `AGENTS.md`, under "Rules for this project only". Never edit files inside `.ai`: the next update would overwrite them.

That's it: open the project with Claude Code and ask for a feature. It reads the rules from `.ai`, the analyzers stop code that breaks the mechanical rules, and when it finishes the hook compiles and runs the tests, and sends any failure back for it to fix. Keep the project closed in Unity while it works: batch mode can't open a project the Editor has open, so the hook would skip the check and say so.

### Cloning a project that uses it

`git clone` leaves `.ai` empty. Fill it with:

```bash
git submodule update --init
```

Or clone with `git clone --recurse-submodules <url>`.

### Updating

One command gets the latest rules and refreshes the files at the root:

```bash
bash .ai/templates/scripts/update.sh
```

It updates the `.ai` submodule from GitHub, then runs `install.sh --update`: the copies that came from `.ai` (Copilot, Rider and Cursor rules, `.editorconfig`, `verify.sh`, `verify-editor.sh`, the hook, the Editor scripts and the analyzers) get the new version, and are listed. A copy you changed in your project, such as a hook that also watches local packages, is kept: the script recognizes an unchanged copy because it matches an earlier version in `.ai`'s history, and lists the changed ones for you to merge by hand. It never touches `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json` or `.mcp.json`, which are yours.

Then commit, so everyone on the project gets the same version:

```bash
git add .
git commit -m "Update Unity Architecture Agents"
```

What changed is in `.ai/CHANGELOG.md`. Teammates get it with `git pull` followed by `git submodule update --init`.

The files are copies rather than symbolic links because links need extra setup on Windows, and Copilot and Rider don't always follow them.

### Work with the Editor open (MCP for Unity)

An agent can also work while the project is open in Unity, through a local Unity MCP server, such as [MCP for Unity](https://github.com/CoplayDev/unity-mcp) (by Coplay). Everything runs on your machine: Claude Code talks to the server on `localhost`, and the server talks to the open Editor. There's no other server or pipeline to set up.

1. In Unity, **Window > Package Manager > + > Add package from git URL**: `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity` (needs Python 3.10+ and `uv`).
2. `install.sh` already wrote `.mcp.json`, which registers the server for Claude Code as `unityMCP` on `http://localhost:8080/mcp`, MCP for Unity's default. Open Claude Code in the project and approve the server.
3. Keep the Editor open while the agent works.

With the Editor open, the Stop hook can't run `verify.sh`, because batch mode can't open a project the Editor has open. The Editor scripts that `install.sh` puts in `Assets/Editor/UnityArchitecture` write each compile and test run to `Logs/verify/`, and the hook reads them with `scripts/verify-editor.sh`. If a script changed after the last compile, or the tests are older than it, the hook asks the agent to compile (`refresh_unity`) or run the tests (`run_tests`) through the MCP server before finishing.

### How verification works

`scripts/verify.sh` finds the Unity version in `ProjectSettings/ProjectVersion.txt` in Unity Hub's default folder, or in the folder set in **Hub > Preferences > Installs**; set `UNITY_PATH` to use another. It compiles the project and runs the EditMode tests; without the Test Framework package (`com.unity.test-framework`) it only compiles, and says so. It fails on compiler and analyzer errors, and writes `Logs/verify/summary.json` for agents and CI. Exit codes: `0` passed, `1` failed, `2` couldn't run. When Claude Code finishes, the hook runs it if `Assets`, `Packages` or `ProjectSettings` changed, and sends failures back to the agent. It gives up after three attempts in a row. Close the project in the Editor while the agent works, or the hook can't check anything.

With a Unity MCP server, such as the Unity CLI's `unity mcp` mode or [MCP for Unity](https://github.com/CoplayDev/unity-mcp), the agent reads the Console, runs tests and builds prefabs through the open Editor instead. [Editor tools](architecture/EDITOR_TOOLS.md) says which tool checks what, and what an agent may do through a bridge.

### Installing without the script

Each file the script creates comes from `.ai/templates`, except `AGENTS.md`, `CLAUDE.md` and `Client.asmdef`, and the analyzers, which come from `.ai/analyzers/prebuilt` with `.ai/analyzers/dll.meta.template` as their `.meta`. To do it by hand, copy them to the paths in the table above, make `scripts/verify.sh` and the hook executable, and write the two entry files:

`AGENTS.md`:

```markdown
# AGENTS.md

All rules live in the `.ai` submodule. Read `.ai/AGENTS.md` completely, then open only the document it points to.

If `.ai/` is empty, run `git submodule update --init`.

## Rules for this project only
```

`CLAUDE.md`:

```text
@.ai/AGENTS.md
@AGENTS.md
```

## Project status

This is version `0.4.1`. The architecture and the code style are mandatory. [Fast IoC](https://github.com/sgonzalezrozo/unity-fast-ioc), [UI Scroller](https://github.com/sgonzalezrozo/unity-ui-scroller), [Screen System](https://github.com/sgonzalezrozo/unity-screen-system) and [UI Foundations](https://github.com/sgonzalezrozo/unity-ui-foundations) are optional: agents detect them, and use plain Unity forms when they're missing.

## FAQ

### How do I make AI coding agents follow an architecture in Unity?

Give them rules they can't miss, and checks they can't skip. Add this repository as `.ai/` and run its install script: it sets up the rules, the [analyzers](analyzers) and the [verify loop](#how-verification-works) that checks every change. Instructions guide the agent, and the compiler enforces the mechanical rules.

### Does it work with Claude Code, Cursor, Copilot and Rider?

I use it with Claude Code, Copilot and Rider's AI Assistant. Claude Code reads `CLAUDE.md`, and Copilot and Rider read the [templates](templates) you copy into their fixed paths. Cursor and Codex read the same kind of files (a Cursor rule template and `AGENTS.md`), but I haven't tested them yet.

### Does it work with Unity MCP?

Yes. With the Unity CLI (`unity mcp`) or MCP for Unity, the agent verifies through the open Editor and may build prefabs with editor tools. It still never writes prefab or scene YAML as text. See [Editor tools](architecture/EDITOR_TOOLS.md).

### Which architecture does it use?

Strict MVC for uGUI: Models own state, Views render, Controllers receive input, and state flows by pull through parameterless events. No `Button`, `Toggle` or `Slider`, because each is a View and a Controller in one. ECS gameplay is out of scope.

### Do I need Fast IoC or the other packages?

No. [Fast IoC](https://github.com/sgonzalezrozo/unity-fast-ioc), [UI Scroller](https://github.com/sgonzalezrozo/unity-ui-scroller), [Screen System](https://github.com/sgonzalezrozo/unity-screen-system) and [UI Foundations](https://github.com/sgonzalezrozo/unity-ui-foundations) are optional. Agents detect them in `Packages/manifest.json` and use plain Unity forms when they're missing.

### Does it work with Unity 6, URP and HDRP?

It's written and tested against Unity 6 (`6000.3`). The rules cover uGUI code, so the render pipeline doesn't matter.

### How do I write an AGENTS.md or CLAUDE.md for a Unity project?

Start from this repository instead of a blank file. Add it as the `.ai/` submodule and run its install script, which creates a root `AGENTS.md` and `CLAUDE.md` that point to it, as [Use it in a project](#use-it-in-a-project) shows. Put rules that only apply to one project in that project's root `AGENTS.md`.

### Are there Cursor rules for Unity?

Yes. Copy [`templates/cursor-rule.mdc`](templates/cursor-rule.mdc) to `.cursor/rules/`. It loads the full rule set from `.ai/AGENTS.md`.

### Is it free for commercial use?

Yes. It's MIT licensed.

### Does anyone else use it?

Not yet. It's version `0.4.1` by a single author, used only in my personal projects so far, and the rules still change. Feedback and issues are very welcome.

### Is there a sample project?

Not yet. A sample project that runs agents against the real packages, with the verify hook installed, will be published once it follows the current rules.

## Contributing

Bug reports, rule fixes and pull requests are welcome. Please open an issue before starting a large change. See the [contributing guide](.github/CONTRIBUTING.md) and [security policy](.github/SECURITY.md).

## Changelog

See the [changelog](CHANGELOG.md).

## License

Released under the [MIT License](LICENSE).
