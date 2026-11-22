# Feature structure

**Load when:** adding a feature or screen, placing a file, naming a type or describing a prefab hierarchy.

## Definition

A feature is usually one main screen plus modal popups. It may have several screens the user navigates between. A feature is not a scope: see [Scopes](mvc/scopes.md#scopes).

| ID | Rule |
|---|---|
| `FEAT-01` | A feature MUST NOT reference another feature's Views, Controllers or scope internals. It MAY read a Model that moved to a common parent or is injected. |
| `FEAT-02` | Setup a person still has to do in Unity (`HAND-07`) MUST be written to `IMPLEMENTATION.md` at the feature root, `Assets/Client/{Feature}/IMPLEMENTATION.md`: one file per feature, whatever the number of screens. A later task on the feature updates that file. |

## Folders

`Assets/Client/` has one folder per feature. A feature has one folder per screen, plus `Services`.

```
Assets/
├── Client/
│   ├── TrophyRoom/
│   │   ├── MainRoom/
│   │   ├── EditRoom/
│   │   ├── DetailsTrophy/
│   │   ├── DetailsTrophySnapshot/
│   │   ├── Services/
│   │   ├── Tests/      The feature's EditMode tests and Client.TrophyRoom.Tests.asmdef
│   │   └── IMPLEMENTATION.md   Setup left to a person, when there is any (FEAT-02)
│   ├── Store/
│   ├── Inventory/
│   ├── HomePage/
│   └── Shared/
├── Art/        Source art: textures, sprites, materials, VFX, animations
├── Audio/      Source audio: SFX, Music, Voice
├── Fonts/
├── Scenes/     Scenes, each next to its own scripts
├── Editor/     Editor-only tools
└── Plugins/    Third-party SDKs
```

### Inside a screen folder

The C# for that screen and the prefabs built with it, side by side. No `Scripts/`, `Prefabs/` or `Views/` subfolders.

Art source files stay in `Assets/Art/` and `Assets/Audio/`. "Created assets" (prefabs) live with the code; "source assets" (`.png`, `.mp3`) do not.

A very large screen may use subfolders by section (`Tabs/`, `Members/`), never by file type.

### Inside `Services`

| File | Role |
|---|---|
| `{Feature}Module.cs` | Pure C# Model that wraps the feature's backend connection ([Backend integration](BACKEND_INTEGRATION.md)) |
| `I{Feature}Connector.cs`, `{Feature}Connector.cs` | Connector interface and implementation |
| `{Feature}Data.cs` | Data classes from the backend |
| `{Feature}Installer.cs` | Fast IoC bindings. Not needed without a container ([Dependency injection](DEPENDENCY_INJECTION.md)) |
| `ScreenDefinition` asset(s) | With `screenSystem`. One if the feature has a single screen. If there are several, see below |

### Inside `Tests`

The feature's tests and its own test assembly, `Client.{Feature}.Tests.asmdef` (`ASM-03`). It's the one folder named after what it holds: tests stay out of the game build, so they can't sit next to the screen they test. Tests of `Shared/` go in `Shared/Tests` the same way, with `Client.Shared.Tests.asmdef`.

### Multi-screen features

- Each screen has its own folder.
- A screen that other features can open keeps its `ScreenDefinition` in the feature where it was first created, which is its main usage. It never moves to `Shared/`.
- Other features refer to that screen; they do not copy it.

### `Shared/`

Only for things used by two or more features that belong to none of them: reusable prefabs, dialogs, formatters. The same subfolders-by-purpose rule applies.

## Naming

| Type | Pattern | Example |
|---|---|---|
| Screen Model | `{Screen}Model` | `EditRoomModel` |
| Feature Module | `{Feature}Module` | `TrophyRoomModule` |
| View | `{Name}View` | `TrophySlotView` |
| Controller | `{Action}Controller` | `ClaimTrophyController` |
| Input GameObject | `Action`, always. Its parent's name tells several apart (`INPUT-01`) | `Action` |
| State root GameObject | `{State}Root` | `LoadingRoot` |
| Rendering method | `Render{Subject}` | `RenderTrophyName` |
| Data | `{Name}Data` | `TrophyData` |
| Connector | `I{Feature}Connector`, `{Feature}Connector` | `ITrophyRoomConnector` |
| Installer | `{Feature}Installer` | `TrophyRoomInstaller` |
| Prefab | Same as its main element | `MainRoom.prefab`, `TrophySlot.prefab` |

**Namespaces:** `Client.{Feature}`, flat for the whole feature, and `Client.{Feature}.Tests` for its tests. Folder names MUST NOT contain spaces.

## Screen composition

```
TrophyRoomMain [MainRoomLoadController, MainRoomStateView]
├── Header
│   ├── TitleText (TextMeshProUGUI)
│   └── Close
│       ├── UI Content
│       └── Action (Image: alpha 0) [CloseController]
├── Content (static elements, tab content or a list)
└── Footer
```

**Hierarchy notation:**

| Form | Meaning |
|---|---|
| `Name (UnityType)` | GameObject with a Unity component |
| `Name (UnityType: setting)` | The same, with a required setting |
| `Name [ProjectType]` | GameObject with project MonoBehaviours |
| `Name (UnityType) [ProjectType]` | GameObject with both |

A MonoBehaviour Model sits on its scope root (`SCOPE-03`). Pure C# Models never appear in a hierarchy, because they aren't on any GameObject.

Rules:

- Separate static elements from dynamic ones. Dynamic content is either tab content or a UI Scroller.
- Each scope has its View at its root (`SCOPE-02`). Divide a large screen into scopes. Interactive elements carry their own Controller.
- Without `screenSystem`: screen prefabs have no Canvas of their own. They sit under an existing Canvas, which owns the `CanvasScaler`.
- With `screenSystem`: each screen prefab and each layer prefab has its own `Canvas` (uGUI) or `UIDocument` (UI Toolkit) at its root, and Screen System sets its sorting (`SCR-02`). A part shared by several screens is a layer, not part of each screen's hierarchy (`SCR-04`).

## Modals and navigation

Popups are separate prefabs in the screen folder that uses them. A modal's state lives in a Model like any other state.

How screens open, close and show popups depends on the package:

> **Fork `navigation`** · open only the branch the [profile](OPTIONAL_PACKAGES.md#the-profile) names:
> - `screen-system`: [Screen System: navigation](branches/screen-system/navigation.md), and [Screen System authoring](branches/screen-system/authoring.md) to create a screen or layer
> - `no-screen-system`: [Navigation without Screen System](branches/no-screen-system/navigation.md)

State that several screens share stays in a Model: if screen B and others need the selected trophy, screen A sets it on a shared Model and B reads it there (`ARCH-04`).

Scene transitions MUST go through one project scene loader, never `SceneManager` from feature code. Showing a menu screen is not the same as leaving a gameplay scene. With `screenSystem`, a single scene load cleans up the UI by itself (`SCR-03`).

## Assembly definitions

```
Assets/Client/Client.asmdef                          All client code, Shared/ included
Assets/Client/{Feature}/Tests/Client.{Feature}.Tests.asmdef   The feature's EditMode tests (Editor only)
```

Place an `.asmdef` inside the folder it should compile. An `.asmdef` directly in `Assets/` would capture the whole project.

| ID | Rule |
|---|---|
| `ASM-01` | All feature code compiles in `Client.asmdef`. A feature's code MUST NOT get its own `.asmdef` (its tests do, `ASM-03`): the analyzers (`EDIT-03`), the prefab validator and the prefab specs only read the assembly named `Client`. |
| `ASM-02` | When code uses a package that is already in `Packages/manifest.json`, `Client.asmdef` (and the feature's `Client.{Feature}.Tests.asmdef` when its tests use it) MUST list every assembly that package names in the **Assembly references** section of its `Documentation~/agent-rules.md` (summary in the table below), in the same change that adds the first `using`. Unity doesn't add them, and without them the build fails with `CS0246`. Check the `references` before compiling, and fix a `CS0246` on a package namespace by adding the reference, never by moving the code out of `Client` (`ASM-01`). The packages' wizards (**New Scroll List**, **New Screen**, **New Layer**, **New MonoInstaller**) add their own to the folder's `.asmdef`; code written by hand still needs this rule. This needs no approval; adding the package itself does (`OPT-03`). |
| `ASM-03` | A feature's EditMode tests MUST go in `Assets/Client/{Feature}/Tests/`, in the namespace `Client.{Feature}.Tests` (the Stop hook runs a feature's tests by that namespace), and compile in the feature's own assembly, `Client.{Feature}.Tests.asmdef` in that folder, written as the [template](#test-assembly) below. The agent creates it with the feature's first test: it's part of a tests scope (`TASK-01`), not test infrastructure (`TASK-03`). There is no project-wide test assembly and no `.asmref`. PlayMode tests, when a project has them, go in `{Feature}/Tests/PlayMode/` with `Client.{Feature}.PlayModeTests.asmdef`, the same template without `includePlatforms`. |

Assemblies each capability needs in `Client.asmdef`. The package's own `agent-rules.md` is the source; this table is a summary:

| Capability | Add to `references` |
|---|---|
| Always | `UnityEngine.UI`, `Unity.TextMeshPro` |
| `fastIoC` | `FastIoC` (installers), `FastIoC.Core` (`IInjectableForChildren`), `ToolsCore` (`IPrefabInstantiator`) |
| `uiScroller` | `UIScroller`, `ToolsCore` (`ISlot<T>` derives from a Tools Core interface) |
| `screenSystem` | `ScreenSystem`, `ToolsCore` |
| `uiFoundations` | `UIFoundations` |
| `com.sgonzalezrozo.ui-tweens` | `UITweens` |
| `addressables` | `Unity.Addressables`, `Unity.ResourceManager` |

### Test assembly

`Assets/Client/Inventory/Tests/Client.Inventory.Tests.asmdef`. Add to `references` the package assemblies the tests use (`ASM-02`), and to `precompiledReferences` `NSubstitute.dll` when they mock a Connector.

```json
{
    "name": "Client.Inventory.Tests",
    "rootNamespace": "Client.Inventory.Tests",
    "references": [
        "Client",
        "UnityEngine.TestRunner",
        "UnityEditor.TestRunner"
    ],
    "includePlatforms": [
        "Editor"
    ],
    "excludePlatforms": [],
    "allowUnsafeCode": false,
    "overrideReferences": true,
    "precompiledReferences": [
        "nunit.framework.dll"
    ],
    "autoReferenced": false,
    "defineConstraints": [
        "UNITY_INCLUDE_TESTS"
    ],
    "versionDefines": [],
    "noEngineReferences": false
}
```
