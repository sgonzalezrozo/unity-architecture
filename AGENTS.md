# AGENTS.md

Normative entry point for coding agents working on a Unity project. Read this file completely, then load only the documents the routing table selects for the task.

- **Requirement keywords:** MUST, MUST NOT, SHOULD and MAY are used as defined in RFC 2119.
- **Rule IDs:** every rule has a stable ID. Cite the ID when you report or discuss a violation.
- **Source of truth:** each rule has one home. If two documents disagree, the document routed for that topic wins, and the conflict is a defect to report.
- **Human summary:** [Developer overview](architecture/DEVELOPER_OVERVIEW.md).
- **Deliberate decisions:** some rules differ from *Clean Code* on purpose. They're listed in the [Developer overview](architecture/DEVELOPER_OVERVIEW.md#10-deliberate-decisions); don't change them to match it.

## Scope

The architecture rules cover all client code except gameplay simulation, which is usually written in ECS. Code after a wrapper that translates ECS to view code does follow them, such as a View that uses an ECS-based tween tool. Packages and tools, such as UI Scroller, don't have to follow them, and how a tool works internally is not a violation.

## What is mandatory

| Scope | Status |
|---|---|
| Architecture invariants in this file | **Mandatory in every project** |
| [MVC](architecture/MVC.md) layer rules | **Mandatory in every project** |
| [C# standards](architecture/CSHARP_STANDARDS.md): code form, style and format | **Mandatory in every project** |
| Unity, C#, uGUI, TextMeshPro | Required runtime |
| Fast IoC, UI Scroller, Screen System, UI Foundations, Addressables | **Optional.** They change the implementation, never the architecture |

Take the capabilities and forks from the [project profile](architecture/OPTIONAL_PACKAGES.md#the-profile), `Logs/ai/profile.md` (`OPT-06`). In Claude Code it's already in your context from the session start; otherwise read it, and run `bash scripts/ai-profile.sh` when it's missing. Never detect packages from the manifest yourself. The same session start gives the [project facts](architecture/OPTIONAL_PACKAGES.md#rules) (`Logs/ai/project-facts.md`: scenes, installers, `Client.asmdef` references, features, localization) and the index of task packs.

Where a rule depends on a package, the document has a **fork**: a block that lists one file per branch. Open only the file of the branch the profile names, never the others.

## Architecture invariants

Strict MVC. Code that violates an invariant is incorrect even if it compiles and runs.

| ID | Rule | Enforced by |
|---|---|---|
| `ARCH-01` | Dependencies are one-way. A Model MAY reference only Models and configuration assets; a feature's root Model also calls the navigation package (`SCR-16`). A View MAY reference only Models, rendering components and its inner Views (`VIEW-03`). A Controller MAY reference only Models and input interfaces. Views and Controllers MUST NOT reference each other. | `UA0001` |
| `ARCH-02` | Models own all data and state. Views and Controllers MUST hold no state beyond cached references. | Review |
| `ARCH-03` | Views render and Controllers receive input. A View MUST NOT handle input or call a Model command. A Controller MUST NOT change anything visual. | `UA0002`, `UA0003`, review |
| `ARCH-04` | State flows by pull. If A references B, A reads from B and B never sends data to A. If A knows B, A MUST do all the work to get what it needs from B, and B MUST NOT prepare, format or deliver data for A. Events MUST have no parameters: they signal a change, and the listener reads the Model. | `UA0004`, review |
| `ARCH-05` | `Selectable` components MUST NOT be used: `Button`, `Toggle`, `Slider` and `Dropdown` combine View and Controller. Controllers implement `IPointer*` and `IDrag*` interfaces. `TMP_InputField` is the only exception. | `UA0005` |
| `ARCH-06` | Feature code and the prefabs built from it share a folder. Source art does not. | Review |
| `ARCH-07` | Anything that can be deterministic MUST be. Prefer a deterministic tool to agent judgment, and keep runtime logic reproducible. See [Determinism](architecture/workflow/determinism.md#determinism). | `verify.sh`, review |
| `ARCH-08` | Anything that can be unit tested MUST be testable, and MUST have unit tests when the task's scope includes tests ([scope question](architecture/workflow/planning.md#scope-question)). Logic that can't be tested where it is MUST move to where it can. See [Tests](architecture/csharp/tests.md#tests). | `verify.sh`, review |
| `ARCH-09` | Model dependencies MUST be acyclic. If two Models need each other, what they share MUST move to a new Model that needs neither. A shared Model MUST NOT reference a feature's Model. | `UA0014` |
| `ARCH-10` | Code MUST NOT add an interface or abstraction without a second use or a test need. | Review |
| `ARCH-11` | Do the minimum that completely finishes the need. A feature not in use MUST cost nothing at runtime. See [Performance](architecture/csharp/performance.md#performance). | Review |

```
Input event → Controller → Model command → state change → parameterless event → View reads Model → View renders
```

## Document routing

**With packs** (`Logs/ai/packs/` exists): read the pack of each part of the task, all in one call, and nothing else (`OPT-07`). A pack holds those rules with the forks resolved, the package documentation they rely on and the verified symbols. The Load column is for projects without packs.

Open only the parts the task needs. Each index ([MVC](architecture/MVC.md), [UI patterns](architecture/UI_PATTERNS.md), [C# standards](architecture/CSHARP_STANDARDS.md), [Agent workflow](architecture/AGENT_WORKFLOW.md)) lists its parts, if a task isn't in this table.

| Task | Pack | Load |
|---|---|---|
| Starting a feature, screen, refactor or anything touching `Shared/` | `new-feature`, `code-and-verify` | [Planning a task](architecture/workflow/planning.md) |
| A Model, View or Controller | `new-feature` | [Layers](architecture/mvc/layers.md), [Where a Model lives](architecture/mvc/where-a-model-lives.md), then the layer's rules: [Models](architecture/mvc/models.md), [Views](architecture/mvc/views.md), [Controllers](architecture/mvc/controllers.md) |
| Scopes, what a prefab root holds | `new-feature` | [Scopes](architecture/mvc/scopes.md) |
| Clicks, visual states, tabs, lists, layouts | `ui-input`, `ui-list`, `example-store` | The part of [UI patterns](architecture/UI_PATTERNS.md): [clicks](architecture/ui/clicks.md), [visual states](architecture/ui/visual-states.md), [tabs](architecture/ui/tabs.md), [lists](architecture/ui/lists.md), [layouts](architecture/ui/layouts.md) |
| New feature or screen, file location, naming, prefab hierarchy, navigation, `.asmdef` | `new-feature`, `navigation` | [Feature structure](architecture/FEATURE_STRUCTURE.md) |
| Building, reviewing or describing a UI prefab | `prefab` | [Prefabs](architecture/PREFABS.md), and [Prefab handoff](architecture/workflow/prefab-handoff.md) when a person builds it |
| Reference acquisition, injection, installers | `new-feature` | [Dependency injection](architecture/DEPENDENCY_INJECTION.md) |
| Backend calls | `backend` | [Backend integration](architecture/BACKEND_INTEGRATION.md) |
| Writing or reviewing C# | `code-and-verify` | [Code style](architecture/csharp/style.md); [performance](architecture/csharp/performance.md) for loading or allocations; [async and errors](architecture/csharp/async-and-errors.md) for `Task`, exceptions or logging |
| Tests | `tests` | [Tests](architecture/csharp/tests.md) |
| Verifying a change, Unity MCP or Unity CLI tools, `verify.sh` | `code-and-verify` | [Editor tools](architecture/EDITOR_TOOLS.md) |
| Finishing a task | `code-and-verify` | [Checklist and Definition of Done](architecture/workflow/checklist.md) |
| Git | | [Git](architecture/workflow/git.md) |

Read the closest example before generating a feature. They use one profile ([which](architecture/OPTIONAL_PACKAGES.md#forks)): adapt them with your branches.

| Example | Demonstrates |
|---|---|
| [Backend feature](architecture/examples/01_BACKEND_FEATURE_TROPHY_ROOM.md) | Folder layout, Module, Connector, list, async command, timer, tests |
| [Custom input](architecture/examples/02_CUSTOM_INPUT_SETTINGS.md) | `Toggle` and `Slider` replacements, reusable prefab, drag input |
| [Filtered list](architecture/examples/03_FILTERED_LIST_INVENTORY.md) | Tabs, filtered list, selection, details panel, no backend |
| [Multi-source bento store](architecture/examples/04_MULTI_SOURCE_BENTO_STORE.md) | Several sources as sections, bento JSON, mock and items Model, clock and countdown, navigation from the root Model, popup with its ID, handoff |

## Completion

A task is complete only when it passes the [pre-response checklist](architecture/workflow/checklist.md#pre-response-checklist) and the [Definition of Done](architecture/workflow/checklist.md#definition-of-done). Report what each tool verified and what wasn't verified ([Editor tools](architecture/EDITOR_TOOLS.md#reporting-back)).

## API policy

MUST NOT invent an API. A package's documented surface is in its branch files, each of which lists the symbols to verify before use; open them only through a fork. For anything else, read the package source or ask.
