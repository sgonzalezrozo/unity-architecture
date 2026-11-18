# Prefabs

**Load when:** building, reviewing or describing a UI prefab, by hand, through a handoff or with editor tools.

A prefab's shape is predictable, so a person, an agent or a tool can build it and another can check it (`ARCH-07`, `DET-04`). The rules here add to the ones that already have a home: scopes in [MVC](MVC.md#scopes), input objects and visual states in [UI patterns](UI_PATTERNS.md), names and folders in [Feature structure](FEATURE_STRUCTURE.md), and the handoff in [Agent workflow](AGENT_WORKFLOW.md#prefab-handoff). None of them changes the MVC.

## Shape

```
QuitGameAlert                 root: Model and root View (SCOPE-02), scale 1, rotation 0
├── Background                raycast on: a screen's background blocks what's under it (PREFAB-14)
├── Title (TextMeshProUGUI)
├── Message (TextMeshProUGUI)
├── Cancel
│   ├── Background            raycast on: it has an Action (PREFAB-14)
│   ├── Text (TextMeshProUGUI)
│   └── Action                Image alpha 0, Cull Transparent Mesh, last child [CancelController]
└── Quit
    └── Container             a parent in between doesn't change any name
        ├── Background
        ├── Text (TextMeshProUGUI)
        └── Action            [QuitController]
```

- Each prefab is a scope with one root View on its root (`VIEW-03`). A nested prefab is another scope: nothing outside it references what's inside, its root View included.
- A View has at most 5 serialized fields. With more, it delegates to inner Views placed near the components they set (`VIEW-07`).
- Every input object is called `Action`; its class is named after what it does (`INPUT-01`).

## Rules

| ID | Rule |
|---|---|
| `PREFAB-01` | The root of a prefab MUST have scale `(1,1,1)` and rotation `0`. A visual scale or rotation goes on a `Visuals` child, which is what tweens animate. |
| `PREFAB-02` | An element that fills its container MUST use stretch anchors (0,0 to 1,1) with offsets or a layout's padding. A fixed-size element uses a point anchor. Fractional anchors (0.2 to 0.8) MUST NOT be used, except for a deliberate proportional split noted in the handoff. |
| `PREFAB-03` | An element with dynamic content MUST set its pivot toward where it grows: Y `1` if it grows down, `0.5, 0.5` if it grows from the center. |
| `PREFAB-04` | Text MUST be `TextMeshProUGUI`; `UnityEngine.UI.Text` MUST NOT be used. The prefab's own look (a sprite, a font, a material) is set on its components in the prefab, never through a View field (`VIEW-07`). An asset that depends on data, such as an item's icon, comes from the Model. |
| `PREFAB-05` | UI MUST NOT use `Animator` or `Animation`. Motion is a tween that a View starts when it reacts to a Model event, or that a layer starts from its lifecycle (`SCR-10`). |
| `PREFAB-06` | A prefab MUST NOT have persistent `UnityEvent` listeners or `EventTrigger` components. All input goes through a Controller (`ARCH-05`). |
| `PREFAB-07` | Rectangular clipping MUST use `RectMask2D`, not `Mask`. Use `Mask` only for shapes that aren't rectangles. |
| `PREFAB-08` | A container filled at runtime, such as a list's `Content` or the parent of instantiated items, MUST be empty in the prefab. |
| `PREFAB-09` | `Action` MUST have an `Image` with alpha 0, and **Cull Transparent Mesh** on in its `CanvasRenderer`, so it draws nothing and costs no overdraw. |
| `PREFAB-10` | A screen or layer has this shape: a stretch root, an optional `Background` and a `Content` inside the safe area. With Screen System, visibility belongs to the package. Without it, turn off the screen's own `Canvas`. `CanvasGroup` is only for fades and interaction. |
| `PREFAB-11` | A modal blocks what's behind it: with Screen System, through its background; without it, through a dimming `Background` with raycast on. Closing on a tap outside is an `Action` that stretches between the `Background` and the `Window`, with a `CloseController`; the `Window` blocks touches with its own `Background`, so only taps outside it close the modal. |
| `PREFAB-12` | Anything that animates or changes often MUST have its own nested `Canvas`, so the static part isn't rebuilt (`ARCH-11`). |
| `PREFAB-13` | A prefab SHOULD NOT go deeper than about 5 levels under its root. Justify it in the handoff when it does. |
| `PREFAB-14` | The `Background` of an element with an `Action` MUST have raycast on, so a touch doesn't reach what's under it. So does the `Background` of a screen, but not the one of each layer. This is the exception to `INPUT-03`. |

Press and hover feedback, such as scaling a button while it's pressed, has no rule yet: it needs a reusable component, like `BaseClickController`, that doesn't exist yet.

## Building a prefab

`UnityArchitecture.Prefabs.PrefabRecipes`, in the rules' package, builds the standard pieces already following these rules, so a prefab is a list of calls, not values set by hand. With a Unity MCP server, an agent calls them with `execute_code`; a person can call them from an Editor script.

| Recipe | Builds |
|---|---|
| `CreateRoot(name, components)` | A stretch root with scale 1 and rotation 0, with its Model and root View |
| `CreateScreenRoot(name, components)` | A root, a blocking `Background` and a `Content` |
| `CreateModalRoot(name, windowSize, closeController, components)` | A dimming `Background`, an optional close `Action`, and a centered `Window` with its own `Background` |
| `CreateSlotRoot(name, size, components)` | A list slot with a fixed size; UI Scroller sets its anchors |
| `AddBackground`, `AddVisuals`, `AddContainer`, `AddImage`, `AddText` | The pieces, with Raycast Target off on visuals and on in a `Background` |
| `AddAction(parent, controllerType)` | `Action`, last, with an invisible `Image` and Cull Transparent Mesh, or no `Image` when the Controller is its own `Graphic` |
| `AddStateRoots(parent, states)` | One `{State}Root` per state |
| `AddNestedPrefab(parent, path)` | An instance of another prefab, which stays its own scope |
| `ApplyStretch`, `ApplyPoint` | Stretch anchors, or a point anchor with a size |
| `SaveAndValidate(root, path)` | Saves the prefab and returns the validator's result |

With Screen System, create the screen or layer first with `ScreenAuthoring` (`SCR-13`) and build its content with the recipes. `PREFAB-03` (pivot) and `PREFAB-12` (nested Canvas) still depend on the content, so set them where the handoff says.

## Checking a prefab

The prefab validator (`TEST-12`) is an EditMode test in the rules' package, `com.sgonzalezrozo.unity-architecture`, which `install.sh` adds to `Packages/manifest.json` from `.ai/unity`. It loads every prefab under `Assets/Client` and fails with the prefab, the object and the rule ID of each error. It runs with the other tests: in `verify.sh`, and in the open Editor through `run_tests`.

| Checked | Rules |
|---|---|
| Errors | `PREFAB-01`, `-04` (legacy `Text`), `-05`, `-06`, `-09`, `-14`, `ARCH-05` (`Selectable` components), `INPUT-01`, `INPUT-02`, `INPUT-03`, `SCOPE-02` (Models), `SCOPE-04` (references into a nested prefab) and `VIEW-03` (inner Views without a root View) |
| Warnings, in the test output | `PREFAB-07` (`Mask`) and `PREFAB-13` (depth) |
| Not checked | `PREFAB-02`, `-03`, `-08`, `-10`, `-11` and `-12`, which need intent the prefab doesn't record. The handoff states them (`HAND-01`), and review checks them |

A nested prefab is another scope, so its insides are checked as its own asset, not from the prefab that nests it. Models, Views and Controllers are recognized by their class name in the `Client` assembly, like the analyzers. `VIEW-07` (5 serialized fields) is checked in code by `UA0016`.

Through a Unity MCP server, `UnityArchitecture.Prefabs.PrefabValidator.ValidateAsset(path)` returns the same results for one prefab, so an agent can check a prefab right after building it. **Tools > Unity Architecture > Validate Client Prefabs** runs it from the menu, and `-executeMethod UnityArchitecture.Prefabs.PrefabValidatorCommands.ValidateFromCommandLine` in batch mode, which exits with 1 when a prefab has an error.
