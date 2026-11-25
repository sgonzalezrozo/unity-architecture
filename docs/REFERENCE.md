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

## How agents read the rules

An agent reads only what the task needs. `AGENTS.md` routes each task to short topic files (`architecture/mvc/`, `ui/`, `csharp/`, `workflow/`) instead of whole documents. Where a rule depends on a package, the topic file has a **fork**: a block with one file per branch, such as Fast IoC, another container or no container.

The [project profile](../architecture/OPTIONAL_PACKAGES.md#the-profile) decides each fork once. `scripts/ai-profile.sh` writes it from `Packages/manifest.json` and `.ai/capabilities.json`, and regenerates it only when one of them changes; Claude Code gets it at every session start, and the other assistants read `Logs/ai/profile.md`. So an agent opens one branch per fork and never reads the rules of a package the project doesn't have (`OPT-06`).

For maintainers, `bash tools/lint-rules.sh` checks the rules: every rule ID defined once, every fork listing its branches with files that exist, every relative link and anchor resolving. `bash tools/test-ai-profile.sh` tests the profile script.

## How the process scales

| Request | Process |
|---|---|
| Question, explanation, review | Answer directly |
| Small change inside existing classes | Make the change and summarize it |
| New feature, screen, class family or refactor | Ask the [scope question](../architecture/workflow/planning.md#scope-question) (code only, with prefabs, with tests), plan, wait for approval |

Before returning code, the agent runs the [pre-response checklist](../architecture/workflow/checklist.md#pre-response-checklist). The optional [analyzers](../analyzers) turn the mechanical items into compile errors.

## The rules' tests

The rules' Unity package (`com.sgonzalezrozo.unity-architecture`) is only the Rules Guide window, and has no tests, so installing the rules adds none to your project. The prefab validator and the tests of the prefab and asset tools belong to the enforcement package, which lists them in its own documentation.

## What install.sh creates

Assistants only read instructions from fixed places in your project, and a submodule can only add its own folder, so the installs put small files there. Run them from a terminal at the project root; double-clicking a `.sh` file opens it in an editor on most systems.

The rules' install (`.ai/templates/scripts/install.sh`) creates only:

| File | Read by | What it is |
|---|---|---|
| `.editorconfig` | Rider, Visual Studio | Formatting, `var`, braces and naming |
| `Packages/manifest.json` | Unity | Adds `com.sgonzalezrozo.unity-architecture` from `.ai/unity` to `dependencies`: the Rules Guide window |

Nothing reads the rules after that: they're documents. A separate, optional enforcement package (private for now) is what makes an AI read and follow them: its install runs this one first, then adds the instruction files every assistant reads (`AGENTS.md`, `CLAUDE.md`, Copilot, Cursor and Rider), `PROJECT_RULES.md` for your project's own rules, the Claude Code hooks, the verify and checker scripts, the generators of the AI context in `Logs/ai/`, and its Unity package with the prefab tools. Its documentation lists every file and option.

## Finish in your tools

- **Rider:** open `.aiassistant/rules/project.md` and set the rule's type to **Always**.
- **Rules for this project only:** with the enforcement package, write them in `PROJECT_RULES.md` (`AGENTS.md` is the package's). Never edit files inside `.ai`: the next update would overwrite them.

With the enforcement package, open the project with Claude Code and ask for a feature ([examples](USAGE.md#examples)). It reads the rules from `.ai` and yours from `PROJECT_RULES.md`, asks what to deliver (code only, with prefabs, with tests), and when it finishes the hook compiles and checks it. Either keep the project closed in Unity while it works, so the hook checks in batch mode, or keep it open with [MCP for Unity](#work-with-the-editor-open-mcp-for-unity), so the hook reads the Editor's own results. Batch mode can't open a project the Editor has open.

## Cloning a project that uses it

`git clone` leaves `.ai` (and `.ai-enforcement`, if the project uses it) empty. Fill them with:

```bash
git submodule update --init
```

Or clone with `git clone --recurse-submodules <url>`. `Logs/ai/` isn't committed: opening the project in Unity generates it (or run `scripts/ai-profile.sh`).

## Updating

One command gets the latest rules, refreshes the files at the root, and regenerates the AI context:

```bash
bash .ai/templates/scripts/update.sh
```

It updates the `.ai` submodule from GitHub, then runs the install again: the enforcement's install with `--update` when `.ai-enforcement` is there (it runs the rules' install first), or the rules' install alone. The copies get the new version, and are listed. A copy you changed in your project, such as a hook that also watches local packages, is asked about or kept: the scripts recognize an unchanged copy because it matches an earlier version in its repository's history. `PROJECT_RULES.md` is never touched. To update the enforcement itself, run `bash .ai-enforcement/templates/scripts/update.sh`.

Then commit, so everyone on the project gets the same versions:

```bash
git add .
git commit -m "Update Unity Architecture"
```

What changed is in `.ai/CHANGELOG.md` and `.ai-enforcement/CHANGELOG.md`. Teammates get it with `git pull` followed by `git submodule update --init`.

The files are copies rather than symbolic links because links need extra setup on Windows, and Copilot and Rider don't always follow them.

## Work with the Editor open (MCP for Unity)

This is optional: without it, the agent works with the Editor closed and everything else still applies. An agent can also work while the project is open in Unity, through a local Unity MCP server, such as [MCP for Unity](https://github.com/CoplayDev/unity-mcp) (by Coplay). Everything runs on your machine: Claude Code talks to the server on `localhost`, and the server talks to the open Editor.

1. In Unity, **Window > Package Manager > + > Add package from git URL**: `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity` (needs Python 3.10+ and `uv`).
2. In **Window > MCP for Unity**, choose the **HTTP Local** transport and click **Start Server**.
3. In the window's **Tools** section, turn on **Testing** (`run_tests`, `get_test_job`) and **Scripting Extensions** (`execute_code`). They're off by default, and the agent needs them to run tests and to build and validate prefabs.
4. Close Unity and run `bash .ai-enforcement/templates/scripts/install.sh --mcp`. It writes `.mcp.json`, which registers the server for Claude Code as `unityMCP` on `http://localhost:8080/mcp`, MCP for Unity's default. Don't also register it from the window, or Claude Code sees it twice. Open Claude Code in the project, approve the server, and check it with `/mcp`.
5. Keep the Editor open while the agent works.

The [installation guide](MCP_FOR_UNITY.md) has the details, including Roslyn for `execute_code` and what to allow in `.claude/settings.json`.

With the Editor open, the Stop hook can't run `verify.sh`, because batch mode can't open a project the Editor has open. The reporters in the enforcement's Unity package write each compile and test run to `Logs/verify/`, and the hook reads them with `scripts/verify-editor.sh`. If a script changed after the last compile, the hook asks the agent to compile (`refresh_unity`) through the MCP server before finishing. With the Editor open and no Unity MCP in the manifest, the hook can't ask, so it only reports that it couldn't check; close Unity for a full check.

## How verification works

`scripts/verify.sh` finds the Unity version in `ProjectSettings/ProjectVersion.txt` in Unity Hub's default folder, or in the folder set in **Hub > Preferences > Installs**; set `UNITY_PATH` to use another. It compiles the project and runs the EditMode tests; without the Test Framework package (`com.unity.test-framework`) it only compiles, and says so. `VERIFY_COMPILE_ONLY=1` makes it only compile. It fails on compiler and analyzer errors, and writes `Logs/verify/summary.json` for agents and CI, with the time the run started. Exit codes: `0` passed, `1` failed, `2` couldn't run. What the Stop hook runs and when is in the enforcement package's documentation.

With a Unity MCP server, such as the Unity CLI's `unity mcp` mode or [MCP for Unity](https://github.com/CoplayDev/unity-mcp), the agent reads the Console, runs tests and builds prefabs through the open Editor instead. [Editor tools](../architecture/EDITOR_TOOLS.md) says which tool checks what, and what an agent may do through a bridge.

## Installing without the script

The rules need nothing installed: read them in `.ai/`. Without the enforcement package, an assistant follows them once its instruction file points to them. Write the two entry files, and put your project's own rules in `PROJECT_RULES.md`:

`AGENTS.md`:

```markdown
# AGENTS.md

Read `.ai/AGENTS.md` completely: the architecture rules. Then open only the document it points to for your task.

Then read `PROJECT_RULES.md`: the rules for this project only.

@.ai/AGENTS.md
@PROJECT_RULES.md
```

`CLAUDE.md`:

```text
@AGENTS.md
```
