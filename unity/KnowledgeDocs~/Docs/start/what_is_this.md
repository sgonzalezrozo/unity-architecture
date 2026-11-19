# What this is

The **human version** of the rules coding agents follow (`AGENTS.md` and `architecture/`). The agent rules are normative and have IDs; these explain them with examples.

> [!TIP]
> The document icon on each card opens the original rule it comes from.

## What is mandatory

| Scope | Status |
|---|---|
| Architecture invariants (`ARCH-*`) | <color=#F85149>**Mandatory in every project**</color> |
| MVC layer rules | <color=#F85149>**Mandatory in every project**</color> |
| C# standards | <color=#F85149>**Mandatory in every project**</color> |
| Unity, C#, uGUI, TextMeshPro | Required runtime |
| Fast IoC, UI Scroller, Screen System, UI Foundations, Addressables | <color=#3FB950>**Optional**</color>: they change the implementation, never the architecture |

## Scope

All client code **except gameplay simulation** (usually ECS). Code after a wrapper that translates ECS to view code does follow them. Packages and tools, such as UI Scroller, don't have to.

> [!IMPORTANT]
> Code that breaks an invariant **is wrong even if it compiles and runs**.

**Where to go next:** [Install the rules](doc:start.install_rules) · [MVC at a glance](doc:architecture.mvc_overview) · [Build a UI element](doc:ui.create_ui) · [Folders](doc:feature.folders)
