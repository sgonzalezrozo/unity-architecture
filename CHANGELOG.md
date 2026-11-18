# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Added

- Working with the Editor open, through a local Unity MCP server such as MCP for Unity (Coplay). `install.sh` writes `.mcp.json`, which registers the server on `localhost:8080`, and puts Editor scripts in `Assets/Editor/UnityArchitecture` that write every compile and test run to `Logs/verify/`. The test reporter only compiles when the Test Framework package is installed.
- `scripts/verify-editor.sh` checks the project from those results. The Stop hook uses it when the Editor is open (Unity holds `Temp/UnityLockfile`) and `verify.sh` when it's closed. It asks the agent to compile (`refresh_unity`) when a script changed after the last compile, and to run the tests (`run_tests`) when the last run started before the newest script change. It doesn't compare them with the last compile, since Unity compiles again after a test run. Script changes in local packages (`file:` entries in `Packages/manifest.json`) count too, except in folders ending in `~`.
- `EDIT-10`: with the Editor open, the agent compiles and runs the EditMode tests in the Editor before finishing.
- The Claude Code settings template allows `verify-editor.sh` and the read-only Unity MCP tools `read_console`, `refresh_unity`, `run_tests` and `get_test_job`.
- `install.sh --update` keeps a copied template you changed in your project, such as a customized hook or `verify.sh`, and lists it to merge by hand. It updates a copy only when it matches an earlier version of the template in the `.ai` repository's history, so nobody edited it. Before, it replaced any copy that differed.
- The Stop hook escapes its messages, so text with quotes or backslashes from the verify scripts stays valid JSON.

### Changed

- The Stop hook only compiles on most stops. It runs the tests at most every two hours, and only when something changed since they last passed, so verifying doesn't slow down every change. `VERIFY_TESTS_EVERY_SECONDS` changes the interval, and a passing test run in the open Editor counts as the last run. `verify.sh` and `verify-editor.sh` take `VERIFY_COMPILE_ONLY=1` to only compile. `EDIT-10` now asks for the tests when the hook does, not after every change.
- `install.sh` no longer creates `Assets/Client/Client.asmdef`: Unity warns about an assembly definition with no scripts, and the project's code may live in other folders. It installs the analyzers only when that file exists, and otherwise says how to add it.

## [0.4.1] - 2026-11-17

### Added

- `templates/scripts/install.sh` puts the entry files at the project root in one command: `AGENTS.md`, `CLAUDE.md`, `.editorconfig`, the Copilot, Rider and Cursor rules, `verify.sh` and the Claude Code hook. It keeps files that already exist; `--update` refreshes the copied templates, and never touches `AGENTS.md`, `CLAUDE.md` or `.claude/settings.json`.
- `templates/scripts/update.sh` gets the latest `.ai` from GitHub and runs `install.sh --update`.
- `install.sh` installs the analyzers from a prebuilt DLL in `analyzers/prebuilt`, with no .NET SDK needed, and creates `Assets/Client/Client.asmdef` when `Assets/Client` doesn't exist yet. It skips them, and says why, when `Assets/Client` has code but no `.asmdef`.
- `install.sh` offers to run `verify.sh` once at the end, so the first, slow batch-mode import happens before the hook needs it. `--verify` and `--no-verify` answer for you.
- The Claude Code settings template allows `verify.sh` and read-only `git` commands, so Claude doesn't ask for each one.
- `verify.sh` also finds Unity in the folder set in **Unity Hub > Preferences > Installs**.
- `analyzers/build.sh` updates `analyzers/prebuilt`, and the Unity project argument is optional.

### Fixed

- `verify.sh` never finished in a project without the Test Framework package, such as a new one: Unity ignores `-runTests` without it and stays open, so the hook waited until its 10-minute timeout. It now only compiles in that case, and says no tests ran.
- `SCR-14`: the special screens are created by **Setup** or the `ScreenManager` Inspector; Screen System 0.4.2 has no **Create Special Screens** menu item.

### Changed

- `CLAUDE.md` loads both `.ai/AGENTS.md` and the project's root `AGENTS.md`, so Claude Code also reads the project's own rules. The root `AGENTS.md` has a "Rules for this project only" section.
- README: "Use it in a project" is now five numbered steps, from `git init` to the first commit, with a table of the files at the root, how to clone a project that uses the rules, and how to update.

## [0.4.0] - 2026-11-17

### Added

- Lists: a layout choices table (list, grid, bento, sections, carousel, pager, endless feed) and what each layout can't combine with; bento tiles and Section Spacing.
- Lists: bento layouts can loop (bento carousels); with a paged source, Loop uses the first page as the whole list.
- Lists: carousel effects with `IViewportPositionListener` and `GetViewportPosition`, and nested lists (a carousel in a vertical list) with no setup.
- `LIST-08`: a bento tile's size comes from the layout (Layout JSON or `SetBentoLayout`), never from the item or the slot.
- `SCR-14`: the splash and the quit confirmation are created with **Create Special Screens** (or `SpecialScreensCreator.Create()`), keep their names, and the quit modal uses `QuitConfirmationLayer`; feature code never calls `Application.Quit`.

### Changed

- **Breaking:** Slot List is now **UI Scroller** (`com.sgonzalezrozo.ui-scroller`, namespace `UIScroller`, capability `uiScroller`). The rules, the examples and the API list use its names: `Scroller<T>`, `SectionedScroller<TItem, THeader>`, `IScroller` (an expandable slot's `Owner`). A concrete list class takes the `Scroller` suffix (`ItemScroller`). Slots keep their names (`ISlot<T>`, Slot Model, Slot View).
- Lists: the API table adds animated `ScrollToItem(index, align, duration, offset)`, `SetBentoLayout`, `GetTile`, `IsScrolling`, `ViewportSize` and `SnappedTo`.
- `SCR-10`: an outro plays before `GoTo` and navigates from its completion callback; `OnScreenHidden()` is too late. Keep a background opaque, and restore layers changed by an outro, since they stay loaded.
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
