# Feature structure

**Load when:** adding a feature or screen, placing a file, naming a type or describing a prefab hierarchy.

## Definition

A feature is usually one main screen plus modal popups. It may have several screens the user navigates between. A feature is not a scope: see [Scopes](MVC.md#scopes).

| ID | Rule |
|---|---|
| `FEAT-01` | A feature MUST NOT reference another feature's Views, Controllers or scope internals. It MAY read a Model that moved to a common parent or is injected. |

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
│   │   └── Services/
│   ├── Store/
│   ├── Inventory/
│   ├── HomePage/
│   └── Shared/
├── Art/        Source art: textures, sprites, materials, VFX, animations
├── Audio/      Source audio: SFX, Music, Voice
├── Fonts/
├── Scenes/     Scenes, each next to its own scripts
├── Editor/     Editor-only tools
├── Plugins/    Third-party SDKs
└── Tests/      EditMode and PlayMode test assemblies, one folder per feature
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

**Namespaces:** `Client.{Feature}`, flat for the whole feature. Folder names MUST NOT contain spaces.

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

With `screenSystem`, a popup is a screen whose `ScreenDefinition` type is `Modal`, opened with `GoTo` and closed with `GoBack`. One modal is open at a time, an `alert` blocks navigation until `DismissAlert()`, `GoTo(screen, value)` passes a typed value to `IScreenParameter<T>` components, and `GoToForResult<T>` awaits a modal's answer from `CloseWithResult(value)` (`SCR-07` to `SCR-09`). The package's README documents the rest; for anything not listed there, read how existing features do it, and ask if there is no precedent.

Pass what the navigation is about (which trophy to show) with `GoTo(screen, value)`. State that several screens share stays in a Model: if screen B and others need the selected trophy, screen A sets it on a shared Model and B reads it there. The [backend example](examples/01_BACKEND_FEATURE_TROPHY_ROOM.md) does this with `TrophyRoomModule.SelectTrophy`.

Scene transitions MUST go through one project scene loader, never `SceneManager` from feature code. Showing a menu screen is not the same as leaving a gameplay scene. With `screenSystem`, a single scene load cleans up the UI by itself (`SCR-03`).

## Assembly definitions

```
Assets/Client/Client.asmdef                  All client code, Shared/ included
```

Place an `.asmdef` inside the folder it should compile. An `.asmdef` directly in `Assets/` would capture the whole project.

| ID | Rule |
|---|---|
| `ASM-01` | All feature code compiles in `Client.asmdef`. A feature MUST NOT get its own `.asmdef`: the analyzers (`EDIT-03`), the prefab validator and the prefab specs only read the assembly named `Client`. |
| `ASM-02` | When a feature needs a package that is already in `Packages/manifest.json`, add that package's assembly to the `references` of `Client.asmdef`. This needs no approval; adding the package itself does (`OPT-03`). |
