<div align="center">

# Unity Architecture Agents

<sub>DESIGNED & BUILT BY</sub><br>
**✦ [`SANTIAGO GONZÁLEZ ROZO (@sgonzalezrozo)`](https://github.com/sgonzalezrozo) ✦**

Architecture rules and a working process for AI coding agents on Unity 6: strict MVC for uGUI, a verify script, and a Claude Code hook that won't let an agent finish with a broken build.

[![Unity](https://img.shields.io/badge/Unity-6000.3%20tested-black?style=for-the-badge&logo=unity)](docs/INSTALLATION.md#what-you-need)
[![Version](https://img.shields.io/badge/version-0.9.0-blue?style=for-the-badge)](CHANGELOG.md)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

[**Installation**](#installation) • [**Key Features**](#key-features) • [**Quickstart**](#quickstart) • [**Usage**](docs/USAGE.md) • [**Rules**](AGENTS.md) • [**Developer Overview**](architecture/DEVELOPER_OVERVIEW.md)

<sub>[Installation Guide](docs/INSTALLATION.md) • [Setup Reference](docs/REFERENCE.md) • [MCP for Unity](docs/MCP_FOR_UNITY.md) • [FAQ](docs/FAQ.md) • [Changelog](CHANGELOG.md)</sub>

</div>

---

## Installation

Open a terminal at your project root, the folder with `Assets`, `Packages` and `ProjectSettings` (on Windows, Git Bash), and run:

```bash
git init
```

<sub>* Skip it if the project is already a Git repository.</sub>

```bash
git submodule add https://github.com/sgonzalezrozo/unity-architecture-agents.git .ai
```

```bash
bash .ai/templates/scripts/install.sh
```

**On Windows**, run the scripts in Git Bash, or call the `.cmd` launcher from PowerShell or cmd: `.ai\templates\scripts\install.cmd` (same options). A plain `bash` in PowerShell or cmd is WSL's launcher, which fails with "Windows Subsystem for Linux has no installed distributions".

It asks two questions:

1. **Install the optional analyzers?** They turn the mechanical rules (no `Button`, no LINQ, no `var`...) into compile errors in `Assets/Client`. Answer `n` unless you want them; you can add them later with `--analyzers`.
2. **Run scripts/verify.sh now?** Answer `y` with the project **closed** in Unity. It imports, compiles and tests the project once in batch mode (a few minutes), so the hook's checks are quick later. With `n`, the first check just happens later.

The installer also adds the rules' package to `Packages/manifest.json`, with its **50 tests**. They test the rules and their tools, not your code: one checks that your prefabs under `Assets/Client` follow the prefab rules, with one case per feature folder (a single case that passes while there are no prefabs), and the other 49 test the prefab validator, specs and recipes themselves. So a new project reports "Verify passed: 50 tests". [Which tests](docs/REFERENCE.md#the-rules-tests).

Then commit:

```bash
git add .
git commit -m "Add Unity Architecture Agents"
```

**Updating.** To get newer rules, run the update script and commit:

```bash
bash .ai/templates/scripts/update.sh
```

On Windows, outside Git Bash: `.ai\templates\scripts\update.cmd`.

It keeps your `.claude/settings.json`. If it predates the project profile, the script says so: add the SessionStart hook from `.ai/templates/claude/settings.json`, so Claude Code starts each session with the profile.

After cloning a project that uses the rules, or pulling a teammate's update, fill or sync the `.ai` folder:

```bash
git submodule update --init
```

What each command creates, the install options and how verification works: [Setup Reference](docs/REFERENCE.md). From a brand-new Unity project, step by step: [Installation Guide](docs/INSTALLATION.md).

---

## Key Features

* **[Strict MVC for uGUI](architecture/MVC.md)**: Models own state, Views render, Controllers receive input, and state flows by pull.
  Eleven invariants and the layer rules hold in every project, so agents and people write the same shapes.
* **[Asks before it builds](architecture/workflow/planning.md#scope-question)**: for a new feature the agent asks for code only, with prefabs, with tests, or all of them.
  It builds the smallest feature that does what you asked, and never adds analyzers or tools you didn't ask for.
* **[Reads only what it needs](docs/REFERENCE.md#how-agents-read-the-rules)**: a project profile, written once from `Packages/manifest.json`, tells the agent which branch of each package-dependent rule applies.
  It opens short topic files and one branch per fork, never the rules of packages you don't have: about half the rules it read before for the same task.
* **[A build it can't skip](docs/REFERENCE.md#how-verification-works)**: when the agent finishes, a Claude Code hook compiles and runs the tests, and sends failures back to fix.
  It works with the Editor closed (batch mode) or open, through [MCP for Unity](docs/MCP_FOR_UNITY.md).
* **[Rules Guide in Unity](docs/USAGE.md#rules-guide)**: **Tools > Unity Architecture > Rules Guide** shows the rules for people, in English or Spanish.
  It lists only the docs for the packages you have, and links to the author's other tools.
* **[Every assistant](docs/REFERENCE.md#what-installsh-creates)**: one install sets up Claude Code, Cursor, GitHub Copilot and Rider AI Assistant.
  Optional packages such as Fast IoC, Screen System and UI Scroller are detected, never required.

---

## Quickstart

Open Claude Code at the project root and ask for a feature:

```text
Create the player health feature to show the player's health in the UI.
```

The agent starts with the project profile, reads only the rules the task needs, asks what to deliver, shows a short plan for you to approve, and builds it. When it stops, the hook checks the build. Say the scope up front to skip the question:

```text
Create the player health feature: code and prefabs, no tests.
```

More prompts that work, with the Editor open or closed: [Usage](docs/USAGE.md). Rules for one project only go in the root `AGENTS.md`, under "Rules for this project only"; never edit files inside `.ai`.

---

## Contributing

Bug reports, rule fixes and pull requests are welcome. Open an issue before a large change, and run `bash tools/lint-rules.sh` after changing a rule: it checks rule IDs, forks and links. See the [contributing guide](.github/CONTRIBUTING.md) and the [security policy](.github/SECURITY.md). Released under the [MIT License](LICENSE).
