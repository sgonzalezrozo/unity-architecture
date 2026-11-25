<div align="center">

# Unity Architecture

<sub>DESIGNED & BUILT BY</sub><br>
**✦ [`SANTIAGO GONZÁLEZ ROZO (@sgonzalezrozo)`](https://github.com/sgonzalezrozo) ✦**

Architecture rules and a working process for Unity 6 projects built with AI coding agents: strict MVC for uGUI, examples and good practices, readable in the Editor.

[![Unity](https://img.shields.io/badge/Unity-6000.3%20tested-black?style=for-the-badge&logo=unity)](docs/INSTALLATION.md#what-you-need)
[![Version](https://img.shields.io/badge/version-0.9.4-blue?style=for-the-badge)](CHANGELOG.md)
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
git submodule add https://github.com/sgonzalezrozo/unity-architecture.git .ai
```

```bash
bash .ai/templates/scripts/install.sh
```

**On Windows**, run the scripts in Git Bash, or call the `.cmd` launcher from PowerShell or cmd: `.ai\templates\scripts\install.cmd`. A plain `bash` in PowerShell or cmd is WSL's launcher, which fails with "Windows Subsystem for Linux has no installed distributions".

The rules are documents: the architecture, the examples and the good practices. Read them in `.ai/`, or in the Editor with **Tools > Unity Architecture > Rules Guide**. The install adds only `.editorconfig` and the Rules Guide package, and asks before replacing a `.editorconfig` you already have. Nothing reads the rules by default: an AI reads and follows them through a separate, optional enforcement package (private for now), which adds the instruction files, the hooks and the checks.

Then commit:

```bash
git add .
git commit -m "Add Unity Architecture"
```

**Updating.** To get newer rules, run the update script and commit:

```bash
bash .ai/templates/scripts/update.sh
```

On Windows, outside Git Bash: `.ai\templates\scripts\update.cmd`.

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
* **[A build it can't skip](docs/REFERENCE.md#how-verification-works)**: with the optional enforcement package, a Claude Code hook checks the build when the agent finishes, and sends failures back to fix.
  It works with the Editor closed (batch mode) or open, through [MCP for Unity](docs/MCP_FOR_UNITY.md).
* **[Rules Guide in Unity](docs/USAGE.md#rules-guide)**: **Tools > Unity Architecture > Rules Guide** shows the rules for people, in English or Spanish.
  It lists only the docs for the packages you have, and links to the author's other tools.
* **[Every assistant](docs/REFERENCE.md#how-agents-read-the-rules)**: the rules are plain Markdown with a routing table, so Claude Code, Cursor, GitHub Copilot and Rider AI Assistant can all follow them; the optional enforcement package wires them in.
  Optional packages such as Fast IoC, Screen System and UI Scroller are detected, never required.

---

## Quickstart

With the enforcement package installed, open Claude Code at the project root and ask for a feature:

```text
Create the player health feature to show the player's health in the UI.
```

The agent starts with the project profile, reads only the rules the task needs, asks what to deliver, shows a short plan for you to approve, and builds it. When it stops, the hook checks the build. Say the scope up front to skip the question:

```text
Create the player health feature: code and prefabs, no tests.
```

More prompts that work, with the Editor open or closed: [Usage](docs/USAGE.md). Rules for one project only go in `PROJECT_RULES.md`; never edit files inside `.ai`.

---

## Contributing

Bug reports, rule fixes and pull requests are welcome. Open an issue before a large change, and run `bash tools/lint-rules.sh` after changing a rule: it checks rule IDs, forks and links. See the [contributing guide](.github/CONTRIBUTING.md) and the [security policy](.github/SECURITY.md). Released under the [MIT License](LICENSE).
