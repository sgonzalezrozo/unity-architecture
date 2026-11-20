# Screen System: navigation

Branch `screen-system` of the `navigation` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `navigation: screen-system`.

All UI lives in one persistent `ScreenSystem` object. A screen is a prefab plus the layer prefabs listed in its `LayerDefinition`; layers are found by Resources path or Addressables address, and screens that list the same layer share one instance. The package loads, orders, hides and unloads screens.

| Need | Form |
|---|---|
| Screen shown | `IScreenShow.OnScreenShown()`, on any component of the screen or of one of its layers (`SCR-05`) |
| Screen hidden | `IScreenHide.OnScreenHidden()` (`SCR-05`) |
| Open a screen | `await ScreenManager.Instance.GoTo(ScreenIds.ShopMain)`, with the generated `ScreenIds` constants (`SCR-07`, `SCR-12`) |
| Go back | `await ScreenManager.Instance.GoBack()`; the Escape key does it too |
| Popup or confirmation | A screen whose `ScreenDefinition` type is `Modal` (`SCR-09`) |
| Blocking message (connection lost) | A screen whose type is `Alert`, closed with `DismissAlert()` (`SCR-09`) |
| Part shared by several screens (top bar, background, navigation bar) | A layer prefab listed in each screen's `LayerDefinition` (`SCR-04`) |
| Animate a screen | Per layer; the intro starts from `OnScreenShown()`, the outro plays before calling `GoTo` (`SCR-10`) |

A popup is a screen whose `ScreenDefinition` type is `Modal`, opened with `GoTo` and closed with `GoBack`. One modal is open at a time, an `alert` blocks navigation until `DismissAlert()`, `GoTo(screen, value)` passes a typed value to `IScreenParameter<T>` components, and `GoToForResult<T>` awaits a modal's answer from `CloseWithResult(value)` (`SCR-07` to `SCR-09`). The package's README documents the rest; for anything not listed there, read how existing features do it, and ask if there is no precedent.

Pass what the navigation is about (which trophy to show) with `GoTo(screen, value)`. The [backend example](../../examples/01_BACKEND_FEATURE_TROPHY_ROOM.md) does this with `TrophyRoomModule.SelectTrophy`.

| ID | Rule |
|---|---|
| `SCR-01` | Feature code MUST open and close screens only through `ScreenManager`. It MUST NOT `SetActive` a screen, instantiate a screen or layer prefab, or load a scene to show UI. |
| `SCR-02` | Code MUST NOT set `Canvas.sortingOrder` or UI Toolkit sorting on screens or layers. The package sets it from the stack and the `LayerDefinition`. |
| `SCR-03` | Code MUST NOT unload screens, release their Addressables handles, or turn off a screen covered by another. A single scene load unloads every screen except **Persist Over Scenes** ones, the splash and the quit confirmation. |
| `SCR-04` | A part repeated across screens MUST be one layer prefab listed in each screen's `LayerDefinition`, not a copy in each screen. Describe it in the plan; never edit the `LayerDefinition` asset as text (`EDIT-06`). |
| `SCR-05` | Work that runs when a screen shows or hides MUST use `IScreenShow` / `IScreenHide` (or `IScreenLifecycle`). Hidden layers stay active, so `OnEnable` and `OnDisable` don't run. A layer shared with the previous screen stays visible and doesn't get the callbacks again. |
| `SCR-06` | Boot code MUST `await ScreenManager.WhenReadyAsync()` before the first `SetRoot`, and stop if it returns `null`. Don't poll `ScreenManager.Instance`. A call before initialization logs an error and returns `NotReady`. |
| `SCR-07` | Navigation calls return `NavigationResult` (converts to `bool`; `Status` says why it didn't happen). A call made while another is running is ignored and returns `Transitioning` (`IsTransitioning` tells); calls are never queued. `GoTo` for a screen already in the stack returns to it like `PopTo`, removing the screens above. A tab bar is a shared layer whose buttons call `GoTo(tab, NavigationHistory.ClearToRoot)`, so back returns to the root. |
| `SCR-08` | Pass what a navigation is about with `GoTo(screen, value)`; components on the screen's layers receive it with `IScreenParameter<T>`, once, before `OnScreenShown`, and store it themselves. State shared by several screens stays in a Model (`ARCH-04`); see [Modals and navigation](../../FEATURE_STRUCTURE.md#modals-and-navigation). |
| `SCR-09` | By design, one modal is open at a time: close it before opening another. An alert opens over everything, blocks navigation and the Escape key, and closes only with `DismissAlert()`. For an answer (confirmation, picker), open it with `await screens.GoToForResult<T>(ScreenIds.X)` and the modal calls `CloseWithResult(value)`; check `Returned` before `Value`, since back gives `Dismissed`. |
| `SCR-10` | The package has no screen transition or animation API, and none is added: animations are the layers' job. An intro starts from `OnScreenShown()`. An outro plays first and calls `GoTo` when it completes (a sequence or tween's completion callback), since the screen is hidden at once and `OnScreenHidden()` comes too late to be seen. Don't fade out every layer of the fullscreen screen, or the camera background shows through; keep a background opaque. Hidden layers stay loaded until the scene changes, so restore what the outro changed in `OnScreenHidden()` or before the intro. |
| `SCR-11` | Screen components that need services are injected by the project's container through Tools Core (`fastIoC`: `internal` fields; VContainer: `builder.UseToolsCore()`; Zenject: `ToolsCoreInstaller`). Layers are injected once, before `Awake`, so components MAY rely on their dependencies in `Awake`. Screen System never requires Fast IoC. |
| `SCR-12` | Navigation MUST use the generated `ScreenIds` constants instead of string literals, so typos and renamed screens fail at compile time. |

The package ships its own agent rules in `Documentation~/agent-rules.md` (under `Packages/com.sgonzalezrozo.screen-system/` once installed). Read them before using an API not listed here.

Creating screens, layers and the special screens: [Screen System authoring](authoring.md).

Verify these symbols before use: `ScreenManager`, `ScreenDefinition`, `LayerDefinition`, `IScreenShow`, `IScreenHide`, `IScreenLifecycle`, `IScreenParameter<T>`, `ModalResult<T>`, `NavigationResult`, `NavigationHistory`, `ScreenIds`.
