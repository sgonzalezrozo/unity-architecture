# Setup reference

[← Back to README](../README.md)

Everything the README's three commands set up, how to keep it current, and how verification works. For a step-by-step guide from a new Unity project, see [Installation](INSTALLATION.md).

## What's included

| File | Purpose |
|---|---|
| [Installation](INSTALLATION.md) | Step by step, from a new Unity project to an agent building a checked feature: Git, the submodule, MCP for Unity and its setup |
| [Usage](USAGE.md) | Working with Claude Code: prompts that work, with the Editor open or closed, and the Stop hook's messages |
| [MCP for Unity](MCP_FOR_UNITY.md) | Optional: install and set up MCP for Unity so the agent works with the Editor open |
| [FAQ](FAQ.md) | Project status and common questions |
| [AGENTS.md](../AGENTS.md) | Entry point: stack, philosophy and where to read next |
| [Developer overview](../architecture/DEVELOPER_OVERVIEW.md) | One-file summary for human developers |
| [Agent workflow](../architecture/AGENT_WORKFLOW.md) | Task classification, scope question, plan format, checklist, Definition of Done and Git |
| [MVC](../architecture/MVC.md) | How Models, Views and Controllers work together |
| [Feature structure](../architecture/FEATURE_STRUCTURE.md) | Folders, naming, and screen composition |
| [Dependency injection](../architecture/DEPENDENCY_INJECTION.md) | Bindings, installers and references |
| [Backend integration](../architecture/BACKEND_INTEGRATION.md) | How features talk to a backend |
| [UI patterns](../architecture/UI_PATTERNS.md) | Clickable elements, visual states, tabs, lists and layouts |
| [Prefabs](../architecture/PREFABS.md) | The shape of a UI prefab: root, `Action`, backgrounds, anchors, masks and the `PREFAB-xx` rules |
| [Optional packages](../architecture/OPTIONAL_PACKAGES.md) | How an agent detects optional packages and adapts its code |
| [C# standards](../architecture/CSHARP_STANDARDS.md) | Style, performance, async, logging and tests |
| [Editor tools](../architecture/EDITOR_TOOLS.md) | How an agent verifies its work with Unity MCP, the Unity CLI or `verify.sh` |
| [Examples](../architecture/examples) | Three complete features with invented names: a backend feature, custom input and a filtered list |
| [Templates](../templates) | `.editorconfig`, Copilot, Cursor and Rider rules, `verify.sh`, a Claude Code Stop hook, and `install.sh` and `update.sh` to put them in your project and keep them current |
| [Analyzers](../analyzers) | Optional Roslyn analyzers that turn the mechanical rules into compile errors (`install.sh --analyzers`) |
| [Unity package](../unity) | `com.sgonzalezrozo.unity-architecture`: prefab recipes, JSON specs, the prefab validator, and the reporters that write each compile and test run in the open Editor to `Logs/verify/` |

## How the process scales

| Request | Process |
|---|---|
| Question, explanation, review | Answer directly |
| Small change inside existing classes | Make the change and summarize it |
| New feature, screen, class family or refactor | Ask the [scope question](../architecture/AGENT_WORKFLOW.md#scope-question) (code only, with prefabs, with tests), plan, wait for approval |

Before returning code, the agent runs the [pre-response checklist](../architecture/AGENT_WORKFLOW.md#pre-response-checklist). The optional [analyzers](../analyzers) turn the mechanical items into compile errors.

## The rules' tests

`install.sh` adds the rules' package (`com.sgonzalezrozo.unity-architecture`) to `Packages/manifest.json`, under both `dependencies` and `testables`, and Unity runs the tests of every package in `testables`. That's why a brand-new project reports **50 tests**. None of them test your code: they're tests of the rules and the tools that apply them.

| File | Tests | What it checks |
|---|---|---|
| `ClientPrefabsTests` | 1 | **Your prefabs**: that everything under `Assets/Client` follows the prefab rules (`PREFAB-xx`). It passes while there are no prefabs |
| `PrefabValidatorTests` | 22 | The prefab validator itself |
| `PrefabSpecsTests` | 15 | Building a prefab from a JSON spec |
| `PrefabRecipesTests` | 8 | The prefab recipes |
| `PrefabSpecCommandsTests` | 4 | The **Build Prefab From Spec** menu item |

Only the first one is about your project, and it's why the package is in `testables`: that's how the Stop hook checks your prefabs. The other 49 check the tools and run in your project as a side effect; they're fast. Your own tests, once the agent writes them, add to this count.

## What install.sh creates

Assistants only read instructions from fixed places in your project, and a submodule can only add its own folder, so `install.sh` puts small entry files there, pointing to `.ai`. Run it from a terminal at the project root; double-clicking a `.sh` file opens it in an editor on most systems.

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
| `.mcp.json` | Claude Code | Registers a local Unity MCP server (MCP for Unity) on `localhost:8080`. Never replaced |
| `.claude/hooks/verify-on-stop.sh`, `.claude/settings.json` | Claude Code | Runs `verify.sh` when the agent finishes and sends failures back. Also allows `verify.sh` and read-only `git` commands, so Claude doesn't ask for each one |
| `Assets/Client/Analyzers/UnityArchitecture.Analyzers.dll` | Unity | Only with `--analyzers`: the optional [analyzers](../analyzers) make the mechanical rules compile errors. Prebuilt, so no .NET SDK needed |
| `Assets/Client/Client.asmdef`, `Client.cs` | Unity | Only when `Assets/Client` doesn't exist yet: the assembly that holds the project's code |
| `Packages/manifest.json` | Unity | Adds `com.sgonzalezrozo.unity-architecture` from `.ai/unity` to `dependencies` and `testables`: the prefab validator, and the reporters that write each compile and test run in the open Editor to `Logs/verify/` |

Files that already exist are kept, so running it again is safe. If your project already had a `.claude/settings.json`, the script says so: add the Stop hook and the allowed commands from `.ai/templates/claude/settings.json` to it yourself. In a new project the script creates `Assets/Client/Client.asmdef`, with a `Client.cs` note so Unity doesn't warn about an empty assembly. The optional analyzers (`--analyzers`) check only the `Client` assembly, not third-party code or tests.

At the end it offers to run `scripts/verify.sh` once. Say yes, with the project closed in Unity: the first batch-mode run imports the whole project, which can take longer than the hook waits, and later runs are quick. `--verify` runs it without asking, `--no-verify` skips it.

| Option | Effect |
|---|---|
| `--update` | Also refreshes copies nobody changed after updating `.ai` |
| `--verify` / `--no-verify` | Runs `scripts/verify.sh` at the end without asking, or skips it |
| `--mcp` / `--no-mcp` | Registers MCP for Unity in `.mcp.json`, or never does. By default only when the manifest already has it |
| `--analyzers` / `--no-analyzers` | Installs the optional Roslyn analyzers in `Assets/Client/Analyzers`, or skips them. Without either, a first install from a terminal asks (default: no). Once installed, `--update` keeps them current and never asks |

## Finish in your tools

- **Rider:** open `.aiassistant/rules/project.md` and set the rule's type to **Always**.
- **Rules for this project only:** write them in your root `AGENTS.md`, under "Rules for this project only". Never edit files inside `.ai`: the next update would overwrite them.

That's it: open the project with Claude Code and ask for a feature ([examples](USAGE.md#examples)). It reads the rules from `.ai`, asks what to deliver (code only, with prefabs, with tests), and when it finishes the hook compiles and runs the tests, and sends any failure back for it to fix. Either keep the project closed in Unity while it works, so the hook checks in batch mode, or keep it open with [MCP for Unity](#work-with-the-editor-open-mcp-for-unity), so the hook reads the Editor's own results. Batch mode can't open a project the Editor has open.

## Cloning a project that uses it

`git clone` leaves `.ai` empty. Fill it with:

```bash
git submodule update --init
```

Or clone with `git clone --recurse-submodules <url>`.

## Updating

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

## Work with the Editor open (MCP for Unity)

This is optional: without it, the agent works with the Editor closed and everything else in the rules still applies. An agent can also work while the project is open in Unity, through a local Unity MCP server, such as [MCP for Unity](https://github.com/CoplayDev/unity-mcp) (by Coplay). Everything runs on your machine: Claude Code talks to the server on `localhost`, and the server talks to the open Editor. There's no other server or pipeline to set up.

1. In Unity, **Window > Package Manager > + > Add package from git URL**: `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity` (needs Python 3.10+ and `uv`).
2. In **Window > MCP for Unity**, choose the **HTTP Local** transport and click **Start Server**.
3. In the window's **Tools** section, turn on **Testing** (`run_tests`, `get_test_job`) and **Scripting Extensions** (`execute_code`). They're off by default, and the agent needs them to run tests and to build and validate prefabs.
4. Close Unity and run `bash .ai/templates/scripts/install.sh --mcp`. It writes `.mcp.json`, which registers the server for Claude Code as `unityMCP` on `http://localhost:8080/mcp`, MCP for Unity's default. Without `--mcp`, `install.sh` writes it only when the manifest already has MCP for Unity, so a project that doesn't use it never sees a failed server. Don't also register it from the window, or Claude Code sees it twice. Open Claude Code in the project, approve the server, and check it with `/mcp`.
5. Keep the Editor open while the agent works.

The [installation guide](MCP_FOR_UNITY.md) has the details, including Roslyn for `execute_code` and what to allow in `.claude/settings.json`.

With the Editor open, the Stop hook can't run `verify.sh`, because batch mode can't open a project the Editor has open. The reporters in the `.ai/unity` package, which `install.sh` adds to the manifest, write each compile and test run to `Logs/verify/`, and the hook reads them with `scripts/verify-editor.sh`. If a script changed after the last compile, the hook asks the agent to compile (`refresh_unity`) through the MCP server before finishing. When the tests are due, it also asks the agent to run them (`run_tests`). With the Editor open and no Unity MCP in the manifest, the hook can't ask for either, so it only reports that it couldn't check and lets the agent finish; close Unity for a full check.

## How verification works

`scripts/verify.sh` finds the Unity version in `ProjectSettings/ProjectVersion.txt` in Unity Hub's default folder, or in the folder set in **Hub > Preferences > Installs**; set `UNITY_PATH` to use another. It compiles the project and runs the EditMode tests; without the Test Framework package (`com.unity.test-framework`) it only compiles, and says so. It fails on compiler and analyzer errors, and writes `Logs/verify/summary.json` for agents and CI. Exit codes: `0` passed, `1` failed, `2` couldn't run. When Claude Code finishes, the hook runs it if `Assets`, `Packages` or `ProjectSettings` changed, and sends failures back to the agent. It gives up after three attempts in a row. The hook only compiles on most stops: it runs the tests at most every two hours, when something changed since they last passed (`VERIFY_TESTS_EVERY_SECONDS` changes the interval, and `VERIFY_COMPILE_ONLY=1` makes `verify.sh` only compile). Close the project in the Editor while the agent works, or the hook can't check anything.

With a Unity MCP server, such as the Unity CLI's `unity mcp` mode or [MCP for Unity](https://github.com/CoplayDev/unity-mcp), the agent reads the Console, runs tests and builds prefabs through the open Editor instead. [Editor tools](../architecture/EDITOR_TOOLS.md) says which tool checks what, and what an agent may do through a bridge.

## Installing without the script

Each file the script creates comes from `.ai/templates`, except `AGENTS.md` and `CLAUDE.md`, and the analyzers, which come from `.ai/analyzers/prebuilt` with `.ai/analyzers/dll.meta.template` as their `.meta`. To do it by hand, copy them to the paths in the table above, make `scripts/verify.sh` and the hook executable, and write the two entry files:

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
