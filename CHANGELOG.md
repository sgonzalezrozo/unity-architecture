# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Added

- `SCR-14`: the splash and the quit confirmation are created with **Create Special Screens** (or `SpecialScreensCreator.Create()`), keep their names, and the quit modal uses `QuitConfirmationLayer`; feature code never calls `Application.Quit`.

### Changed

- `SCR-09`: a modal or alert can answer its caller with `GoToForResult<T>` and `CloseWithResult(value)`, instead of always writing the result to a Model.

## [0.3.0] - 2026-11-16

### Changed

- With `screenSystem`, screen and layer prefabs have their own `Canvas` or `UIDocument`. The "no Canvas of their own" rule now applies only without it.
- Modals and navigation with `screenSystem` are specified instead of "not specified yet".
- **Breaking:** Recyclable Scroller is now **Slot List** (`com.sgonzalezrozo.slot-list`, capability `slotList`). The rules, the examples and the API list use its names: `SlotList<T>`, `ISlot<T>`, `IExpandableSlot<T>`, `IItemSource<T>`, `DefaultExtent`, `SetSource`. Cells are slots: Slot Model, Slot View, `ItemSlot.prefab`, `GetComponentInParent<TSlotModel>()`.
- Lists: adding the component builds its Viewport (`RectMask2D`, `Canvas`, `GraphicRaycaster`) and Content; the list View calls `SetSource` once and `Refresh()` after changes; paged sources load pages by themselves.
- `LIST-02`: pooled slots stay active, so a reused slot's `OnEnable` doesn't run; the Slot View redraws from the `Data` (and `IsExpanded`) event.
- C# standards: a short `///` summary on a class is allowed; still none on members.

### Added

- Screen System rules `SCR-01` to `SCR-13`: navigate only through `ScreenManager`, never set sorting, never unload or turn off screens by hand, share repeated parts as layers in `LayerDefinition`, use `IScreenShow`/`IScreenHide` instead of `OnEnable`/`OnDisable`, `await ScreenManager.WhenReadyAsync()` at boot, navigation returns `NavigationResult` and ignores (never queues) calls during a transition, `GoTo` works like `PopTo` for a screen in the stack, `GoTo(tab, NavigationHistory.ClearToRoot)` for tab bars, pass a value with `GoTo(screen, value)` to `IScreenParameter<T>`, one modal and one alert at a time by design, no screen transitions (animations live in layers), injection through Tools Core with any container and before `Awake`, generated `ScreenIds` constants instead of strings, and screens built with the wizard or `ScreenAuthoring`.
- Mapping rows for screen hidden, go back, popups, alerts, shared parts as layers, and animating a screen.
- `LayerDefinition`, `IScreenHide` and `IScreenLifecycle` in the API list.
- Lists: expandable slots (`IExpandableSlot<T>`, the click asks the list to open or close), slot sizes (fixed, measured with layout, or fixed when closed and measured when open), sections (`SectionedSlotList`) and the current API table.
- `LIST-06`: no layout components on Content, and no `ContentSizeFitter` on a slot's root.
- `LIST-07`: item state lives in the item or a Model, never in the slot.

## [0.2.0] - 2026-11-10

### Added

- Roslyn analyzers for the mechanical rules in the checklist.
- `UA0013` (serialized Model field) and `UA0014` (Model dependency cycle).
- `EDITOR_TOOLS.md`, with `EDIT` rules for verifying with Unity MCP, the Unity CLI or `verify.sh`, and checklist item 14.
- Templates for `verify.sh`, a Claude Code Stop hook and a Cursor rule. `verify.sh` fails on analyzer errors and failed Fast IoC generation, finds Unity on macOS, Linux and Windows, and writes `Logs/verify/summary.json`.
- An FAQ and `llms.txt`.
- `OPTIONAL_PACKAGES.md`, with capability detection, and list and navigation forms for projects without the packages.
- Stable rule IDs, RFC 2119 keywords and the enforcement of each invariant.
- A scope: the architecture rules cover client code, except ECS gameplay, packages and tools.
- `HAND` rules: what an agent must give a person who builds a prefab.
- `SCOPE` rules: a scope is one root GameObject, and a feature can hold several.
- `ARCH-09` to `ARCH-11`: no Model cycles, no abstraction without a need, and the minimum that finishes the need.
- `PERF` rules, `FEAT-01`, `MODEL-09` to `MODEL-11`, `LIST-05` and `TEST-07` to `TEST-10`.
- `ARCH-07` and the `DET` rules: anything that can be deterministic must be.
- `ARCH-08` and the `TEST` rules: anything that can be unit tested must be.

### Changed

- With an editor bridge, an agent may build prefabs through editor tools. The handoff table becomes its spec.
- **Breaking:** Tests for Model behavior are written first, and `MODEL-03` separates reachable conditions from bugs.
- **Breaking:** Fast IoC, Recyclable Scroller, Screen System and UI Foundations are optional. The architecture and code style stay mandatory.
- Models and Views sit on their scope root, and a Model moves up only when shared. Injection is the exception, for Models with no common parent or that persist. Without a container, those Models are singletons.
- Examples use `IPointerClickHandler` and `GameObject` state roots.
- The analyzers apply Fast IoC rules only when Fast IoC is in the compilation.
- **Breaking:** Renamed documents, the `Services And definitions` folder to `Services`, and `Actions` GameObjects to match their Controller.
- **Breaking:** Rendering methods are now `Render{Subject}`, and examples use full, specific member names.

### Fixed

- The API list and the navigation mapping name `ScreenManager`. `ScreenSystem` is only a namespace.
- `ViewStateMachine.SetState` replaces `SetActiveState`, which doesn't exist.
- Lists use a concrete `RecyclableScrollRect<T>` subclass and the real `IRecyclableDataSource<T>` members.
- `MonoInstaller` takes scene names, not a subscene.

### Documentation

- Removed links to packages and the sample project, which aren't published yet.

## [0.1.0] - 2026-11-05

### Added

- `AGENTS.md`, the architecture documents and three complete examples.
- Templates for Copilot and Rider's AI Assistant, and the `.editorconfig` the documents refer to.
