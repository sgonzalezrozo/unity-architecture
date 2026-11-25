# Optional packages

**Load when:** a rule names a capability you need to understand, or the profile is missing. A fork never sends you here: it names its branch files itself.

Packages change the implementation. The [architecture](../AGENTS.md#architecture-invariants), the [MVC layer rules](MVC.md) and the [C# standards](CSHARP_STANDARDS.md) stay mandatory in every configuration.

## The profile

`Logs/ai/profile.md` says which capabilities are `true` in this project and which branch each fork resolves to. `scripts/ai-profile.sh` writes it from `Packages/manifest.json` and the table in [`capabilities.json`](../capabilities.json), the single list of capabilities that the agents, the Stop hook's tools and the Rules Guide window share. The script regenerates the profile only when the manifest, the table or a path it checks changed.

In Claude Code, a SessionStart hook runs the script and puts the profile in the agent's context, so the agent reads nothing to get it. Other agents read `Logs/ai/profile.md`, and run `bash scripts/ai-profile.sh` when it's missing.

| Capability | `true` when the project has |
|---|---|
| `fastIoC` | `com.sgonzalezrozo.fast-ioc` |
| `otherContainer` | VContainer or Zenject (Extenject): the package, or its folder under `Assets/Plugins` |
| `uiScroller` | `com.sgonzalezrozo.ui-scroller` |
| `screenSystem` | `com.sgonzalezrozo.screen-system` |
| `uiFoundations` | `com.sgonzalezrozo.ui-foundations` |
| `uiTweens` | `com.sgonzalezrozo.ui-tweens` |
| `uiAtom` | `com.sgonzalezrozo.ui-atom` |
| `addressables` | `com.unity.addressables` |
| `editorBridge`, `verifyScript`, `generationStatus`, `prefabTools` | The editor tools in [Editor capabilities](EDITOR_TOOLS.md#editor-capabilities) |

A capability that's `true` and used also means its assemblies in `Client.asmdef` (`ASM-02`, [the table](FEATURE_STRUCTURE.md#assembly-definitions)).

## Forks

A fork is a point where the rules depend on a package. The document that needs it states the concept once, then a fork block lists one file per branch:

```
> **Fork `list`** · open only the branch the profile names:
> - `ui-scroller`: [UI Scroller lists](branches/ui-scroller/lists.md)
> - `no-ui-scroller`: [Lists without UI Scroller](branches/no-ui-scroller/lists.md)
```

The profile names one branch per fork, so the agent opens one file and never reads the alternatives. Branches live in `architecture/branches/{branch}/`.

| Fork | Branches, first match wins | Decides |
|---|---|---|
| `container` | `fast-ioc` (`fastIoC`), `other-container` (`otherContainer`), `no-container` | How a Model with no common parent, or that persists, is created and reached; installers and bindings |
| `list` | `ui-scroller` (`uiScroller`), `no-ui-scroller` | Dynamic lists and grids |
| `navigation` | `screen-system` (`screenSystem`), `no-screen-system` | Opening and closing screens, popups, screen lifecycle events |
| `input` | `ui-foundations` (`uiFoundations`), `no-ui-foundations` | Click Controllers, raycast targets, visual state Views |

Where a package changes a line or two, such as Addressables for a large asset or a screen's own `Canvas`, the document states both forms in place: a fork would cost more to open than both forms cost to read.

The examples in this repository use this profile: `container: fast-ioc`, `list: ui-scroller`, `navigation: screen-system` and `input: no-ui-foundations`. Adapt them with the branch the profile names.

## Rules

| ID | Rule |
|---|---|
| `OPT-01` | Nothing MUST use a package or tool whose capability is `false`: code, a prefab or asset, a menu item, a wizard or a code-tool call. A rule that names one applies only when its capability is `true`. Check the capability before the step; when it's `false`, use the branch the profile names, or leave the step out and report it. |
| `OPT-02` | If a capability is `true`, new code SHOULD use that package. |
| `OPT-03` | An agent MUST NOT add a package without approval. See [When to ask](workflow/planning.md#when-to-ask). |
| `OPT-04` | Match the code around the change. Don't mix both forms in one feature. `OPT-02` wins: when a capability is `true`, new code uses the package even if older code around it doesn't. |
| `OPT-05` | No configuration may break an `ARCH` rule or the C# standards. |
| `OPT-06` | The agent MUST take capabilities and forks from the profile, not from `Packages/manifest.json`. At a fork it MUST open only the file of the branch the profile names, and MUST NOT open another branch's files to compare. When the profile is missing, it runs `scripts/ai-profile.sh` first. |
| `OPT-07` | When `Logs/ai/packs/` exists, the agent MUST read the pack of each part of its task (the Pack column of AGENTS.md, all needed packs in one call) instead of their sources, and MUST NOT open a source a pack already includes. Package APIs come from the pack's **Verified symbols** and the package documentation it includes; project data (scenes, installers, references, localization) comes from `Logs/ai/project-facts.md`. When something is missing, it opens that source. Its final report MUST end with `Outside packs:` followed by every file it opened that no pack included (rule files, package documentation or source), or `none`, so `packs.json` can be fixed. The timing hook logs the same list. |
