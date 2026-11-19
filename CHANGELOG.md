# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [0.6.4] - 2026-11-19

### Fixed

- The `.ai/unity` package's `package.json` names its author "Santiago González Rozo", like the other packages, so the Package Manager lists it with them instead of under a separate "sgonzalezrozo" group. It also has the documentation link, license, repository and keywords the other packages have, and declares its `com.unity.ugui` dependency (its prefab tools use uGUI and TextMeshPro).

## [0.6.3] - 2026-11-19

### Changed

- The Rules Guide's **Install packages** doc puts each package's git URL in its own code block, so every one has a **Copy** button, in English and Spanish. It also says Tools Core is needed only by Fast IoC, Screen System and UI Scroller.

## [0.6.2] - 2026-11-19

### Documentation

- The README's installation steps explain both questions `install.sh` asks (the optional analyzers, and running `verify.sh` once), and that the rules' package brings 50 tests: tests of the rules and their tools, not of the project's code, with one that checks the project's prefabs. The Setup Reference lists them.

## [0.6.1] - 2026-11-19

### Changed

- `install.sh` asks whether to install the optional analyzers on a first install from a terminal (default: no). `--analyzers` installs them and `--no-analyzers` skips them without asking; `--update` never asks and keeps analyzers already in the project. The README's installation steps say so.

## [0.6.0] - 2026-11-19

### Added

- `SCOPE-01` to `SCOPE-04`, the scope question: before planning a new feature or screen, the agent asks what to deliver (code only, code and prefabs, code and tests, or all of them), creates only that, and starts from the smallest feature that does what was asked. It doesn't write analyzers, editor tools, generators or test infrastructure unless asked by name; `DET-04` is now for the rules' maintainers only. `ARCH-08` and `TEST-01` ask for tests when the scope includes them; the code stays testable either way. A generic prompt such as "create the player health feature" had taken long, used many tokens and created more than was asked.
- The Rules Guide in Spanish. **Settings > Language** switches between English and Spanish; the Spanish docs live in `KnowledgeDocs~/es/` with the same ids and paths, and a doc missing in Spanish shows in English. The window's own labels are translated too.
- An **Other tools** section at the end of the Rules Guide home: the author's other packages with a short description, their git URL (with a Copy URL button) and an **Installed** label when the project has them.
- `docs/MCP_FOR_UNITY.md`, an installation guide for MCP for Unity on one page, and a matching Rules Guide doc, **Install MCP for Unity**.
- `docs/REFERENCE.md` (what `install.sh` creates, its options, updating, cloning, verification and installing by hand) and `docs/FAQ.md`, with the content that left the README.

### Changed

- The analyzers are optional. `install.sh` installs them only with `--analyzers`; a project that already has them keeps getting updates.
- The Stop hook ignores code generators' output (`Assets/FastIoC/Generated` and `*.g.cs`, such as Fast IoC's `FastIoC.InternalsVisibleTo.g.cs`), so a compile that regenerates code no longer looks like a new change and runs the verify again.
- The Rules Guide repaints on a mouse move only when the mouse moves onto or off something with a hover state, instead of on every move, and measures its category chips once per load.
- The README follows the packages' style: installation in three commands, how to update, and links to the guides.

## [0.5.0] - 2026-11-19

### Added

- The Rules Guide window (**Tools > Unity Architecture > Rules Guide**) in the `.ai/unity` package: short, human-readable docs drawn from the rules, with search, shown only for the packages a project has. It no longer throws a `NullReferenceException` when it opens with the Editor, before `EditorStyles` is ready.
- `ASM-01` and `ASM-02`: all feature code compiles in `Client.asmdef`, since the analyzers, the prefab validator and the specs read only that assembly; a package already in the manifest is added to its references without approval.
- MCP for Unity is optional everywhere. `install.sh` writes `.mcp.json` only with `--mcp`, or when the manifest already has MCP for Unity (`--no-mcp` never does), so a project without it doesn't see a failed server in every session. With the Editor open and no Unity MCP, `verify-editor.sh` reports an out-of-date compile or due tests as "couldn't check" instead of a failure the agent can't fix (`VERIFY_EDITOR_BRIDGE=1` or `0` overrides the detection). **Assets > Unity Architecture > Build Prefab From Spec** builds, validates and compares a prefab from the selected spec, so specs work without a bridge. The installation guide marks MCP for Unity as optional steps.
- Usage example 6, Add a list, has two new prompts with mockups: a store with sections (`SectionedScroller`) and an events list whose cards open to show a progress bar, a reward count and an Enter or Continue button (`IExpandableSlot`). The mockups are PNGs in `docs/images/`, built by `mockups.py`, and a new tip says to attach a PNG to a prompt.
- `OPT-01` covers every use of a package or tool, not only code: prefabs, assets, menu items, wizards and code-tool calls. A rule that names one applies only when its capability is `true`; otherwise the step uses the Unity form or is left out and reported. The new menu rules and `EDIT-13` name the capability each one needs.
- Rules for the packages' new menus. `EDIT-13`: the agent doesn't run a package menu item or wizard through the bridge, since most open a window or modal dialog that blocks the Editor; it calls the code API instead. `SCR-13` names **New Screen Feature**, **Add Screen to Feature…** and **Edit Prefab** (Screen System 0.5), with `ScreenAuthoring.CreateScreen` for agents. `SCR-15`: what to do with the `Background` that **New Layer** adds, and `ScreenAuthoring.CreateLayer` for agents. `DI-09`: where a **New MonoInstaller** goes and what to add to it (Fast IoC 0.10). `DI-10`: generation runs after each compile; agents call `GenerationCoordinator.GenerateAllRetryingFailedCode()`, not **Regenerate Code**. `LIST-09`: **New Scroll List** (UI Scroller 0.7) isn't used under `Assets/Client`, because its output breaks `ARCH-02`, `-03`, `-04`, `-05` and `LIST-02`.

- `PREFAB-17`: an element with an `Action` wraps everything the `Action` hits in one `UI Content` child, the `Action`'s only sibling, so a press tween punches what was hit while the hit area stays still. A modal's close `Action` is the exception. The validator checks it, `PrefabRecipes.AddUIContent` builds it, and specs take a `uiContent` type. The validator also finds an element's `Background` inside `UI Content` for `PREFAB-14`. The diagrams in Prefabs, UI patterns, MVC, Feature structure and the three examples show the new shape; each example says how its Controllers change with `uiFoundations`.
- Prefabs says that with `uiFoundations`, click Controllers derive from `BaseClickController` (`OPT-02`), and that the `Client` assembly references `UIFoundations`. The prefab pilot had used `IPointerClickHandler` in a project with UI Foundations installed.

- `docs/INSTALLATION.md`: step by step from a new Unity project: Git, the submodule, `install.sh`, MCP for Unity and its setup (HTTP Local, the server, the **Testing** and **Scripting Extensions** tool groups, Roslyn, one registration for Claude Code), connecting Claude Code, and troubleshooting. `docs/USAGE.md`: working with Claude Code, with the Editor open or closed, twelve example prompts and what the agent does with each, and the Stop hook's messages. The README, `llms.txt` and `install.sh`'s closing steps point to them.
- Editor tools lists the MCP for Unity tools the rules use, with the tool groups that are off by default, and `execute_code`'s C# 6 fallback without Roslyn. Prefabs gives the return types of `BuildFromSpec`, `Compare` and `ValidateAsset`, and the prefab validator's test name for a filtered run.
- From the prefab pilot, where an agent built three prefabs through MCP: `PREFAB-15` (every serialized reference a Model, View or Controller declares is assigned) and `PREFAB-16` (a `Background`, `Action` or overlay inside a layout group ignores it), both checked by the validator. Specs take `fields`, which assigns serialized fields by object path, `ignoreLayout`, and Unity's UI components such as `VerticalLayoutGroup`. `AddBackground` and `AddAction` keep themselves out of a parent's layout group.
- The Stop hook checks prefabs: when a prefab under `Assets/Client` changed, it runs the prefab validator on every stop, even between test runs. With the Editor open, `verify-editor.sh` asks the agent to run it through `run_tests` and shows its errors, from `Logs/verify/editor-prefabs.json`, which the test reporter writes. With it closed, the hook runs `verify.sh` filtered to that test.
- `prefabTools` capability, `EDIT-11` (build and change prefabs only through the recipes or a spec, called through the bridge's code tool) and `EDIT-12` (validate every prefab built or changed, and compare it with its spec).
- Prefab specs (`HAND-06`): the handoff table as JSON. `PrefabSpecs.BuildFromSpec` builds it with the recipes and validates it, and `PrefabSpecs.Compare` lists every difference between a spec and its prefab. A small JSON reader in the package keeps it free of dependencies, and bad specs fail with the line, column or object to fix.
- Prefab recipes: `PrefabRecipes` in the `.ai/unity` package builds roots, screens, modals, slots, backgrounds, text, images, state roots, nested prefabs and the `Action` object already following the prefab rules, and `SaveAndValidate` checks the result. A menu item and an `-executeMethod` entry point run the validator on `Assets/Client`.
- The prefab validator (`TEST-12`): a local package in `.ai/unity`, `com.sgonzalezrozo.unity-architecture`, that `install.sh` adds to `Packages/manifest.json` and to `testables`. An EditMode test checks every prefab under `Assets/Client` for the prefab rules a tool can check, with the prefab, object and rule ID in each error. `PrefabValidator.ValidateAsset(path)` gives the same results for one prefab, through a Unity MCP server.
- `architecture/PREFABS.md` with `PREFAB-01` to `PREFAB-14`: the root's transform, anchors, pivot, TextMeshPro, no `Animator`, no persistent `UnityEvent`, `RectMask2D`, empty runtime containers, the `Action` hitbox, screen and modal shape, nested Canvases, depth, and a `Background` with raycast on that blocks touches under an element with an `Action` or a screen. `AGENTS.md` routes prefab work to it.
- `VIEW-07` and `UA0016`: a View has at most 5 serialized fields. With more, it delegates to inner Views placed near the components they set, and it serializes components and inner Views, not assets.
- Deliberate decisions in the Developer overview: where the rules differ from *Clean Code* on purpose, linked from `AGENTS.md` so agents don't "fix" them.
- `UA0015`: a `///` comment on a method, constructor, property, field, event or enum member fails the build. A class or other type may still have a short summary. It catches `///` whether or not the compiler parses documentation comments.
- Working with the Editor open, through a local Unity MCP server such as MCP for Unity (Coplay). `install.sh` writes `.mcp.json`, which registers the server on `localhost:8080`, and puts Editor scripts in `Assets/Editor/UnityArchitecture` that write every compile and test run to `Logs/verify/`. The test reporter only compiles when the Test Framework package is installed.
- `scripts/verify-editor.sh` checks the project from those results. The Stop hook uses it when the Editor is open (Unity holds `Temp/UnityLockfile`) and `verify.sh` when it's closed. It asks the agent to compile (`refresh_unity`) when a script changed after the last compile, and to run the tests (`run_tests`) when the last run started before the newest script change. It doesn't compare them with the last compile, since Unity compiles again after a test run. Script changes in local packages (`file:` entries in `Packages/manifest.json`) count too, except in folders ending in `~`.
- `EDIT-10`: with the Editor open, the agent compiles and runs the EditMode tests in the Editor before finishing.
- The Claude Code settings template allows `verify-editor.sh` and the read-only Unity MCP tools `read_console`, `refresh_unity`, `run_tests` and `get_test_job`.
- `install.sh --update` keeps a copied template you changed in your project, such as a customized hook or `verify.sh`, and lists it to merge by hand. It updates a copy only when it matches an earlier version of the template in the `.ai` repository's history, so nobody edited it. Before, it replaced any copy that differed.
- The Stop hook escapes its messages, so text with quotes or backslashes from the verify scripts stays valid JSON.

### Changed

- `OPT-04`: `OPT-02` wins over matching the code around a change; with a capability `true`, new code uses the package even where older code doesn't.
- Dependency injection says when Fast IoC's fields are ready: before `Awake` in the first scene, in scenes loaded later and in prefabs created with `IPrefabInstantiator` (Fast IoC 0.11), so Views and Controllers may use them in `Awake` and `OnEnable`.
- The C# standards say a project without a localization system uses English text until it has one (`DATA-01`).
- `INPUT-02` and `PREFAB-11`: a modal's close `Action` sits under the `Window`, which blocks touches with its own `Background`; the validator accepts it there. A modal dims with a `Background`, not a `Dimmer`, so it follows `INPUT-03`.
- The Editor reporters moved from `Assets/Editor/UnityArchitecture` to the `.ai/unity` package, so updating `.ai` updates them. `install.sh` removes the old copies nobody edited, and lists the edited ones to merge and delete by hand.
- `VIEW-03`: each scope has one root View, on its root, and only it subscribes to the Model. It may tell inner Views what to show, and they set their own components without reading the Model or subscribing. No View reaches into a nested prefab, its root View included. `UA0001` now lets a View reference a View, and still fails when a View references a Controller. `VIEW-01` applies to root Views.
- `INPUT-01`: the input object is always called `Action`, and its Controller class is named after what it does (`{Action}Controller`), whatever the hierarchy. `INPUT-03` allows a blocking `Background` with raycast on (`PREFAB-14`).
- The prefab handoff (`HAND-01`) lists pivot, scale and runtime containers too, and the examples use `Action`.
- The Stop hook only compiles on most stops. It runs the tests at most every two hours, and only when something changed since they last passed, so verifying doesn't slow down every change. `VERIFY_TESTS_EVERY_SECONDS` changes the interval, and only a full run the hook asked for counts as the last one, so filtered runs don't keep pushing it back. `verify.sh` and `verify-editor.sh` take `VERIFY_COMPILE_ONLY=1` to only compile. The full suite runs only when the hook asks for it.
- `TEST-11`: before finishing a change, the agent runs the tests directly related to it, existing and new, and they must pass. `EDIT-10` and the Definition of Done point to it. `verify.sh` takes `VERIFY_TEST_FILTER` to run only those tests with the Editor closed.

### Fixed

- The analyzers checked every assembly that references Client, not just Client: Unity hands an analyzer to those too, and Assembly-CSharp references Client automatically. In a project with code outside `Assets/Client`, every rule failed there, in third-party code and in generated code. They now check only the assembly named `Client`, so tests and the rest of `Assets` stay out, as the README already said.
- `install.sh` creates `Assets/Client/Client.asmdef` again in a new project, with a `Client.cs` note so Unity doesn't warn about an assembly definition with no scripts.

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
