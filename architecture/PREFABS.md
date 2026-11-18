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
| `PREFAB-11` | A modal blocks what's behind it: with Screen System, through its background; without it, through a `Dimmer` with raycast on. Closing on a tap outside is an `Action` that stretches between the background and the window, with a `CloseController`. |
| `PREFAB-12` | Anything that animates or changes often MUST have its own nested `Canvas`, so the static part isn't rebuilt (`ARCH-11`). |
| `PREFAB-13` | A prefab SHOULD NOT go deeper than about 5 levels under its root. Justify it in the handoff when it does. |
| `PREFAB-14` | The `Background` of an element with an `Action` MUST have raycast on, so a touch doesn't reach what's under it. So does the `Background` of a screen, but not the one of each layer. This is the exception to `INPUT-03`. |

Press and hover feedback, such as scaling a button while it's pressed, has no rule yet: it needs a reusable component, like `BaseClickController`, that doesn't exist yet.

## Checking a prefab

A prefab validator is planned: an EditMode test that loads each prefab under `Assets/Client` and checks the rules a tool can check (`PREFAB-01`, `-04` for text, `-05` to `-09`, `-13`, `-14`, plus `INPUT-02`, `INPUT-03`, `SCOPE-02`, `SCOPE-04` and `VIEW-07`). Until it exists, check them by reading the hierarchy back (`EDIT-05`) and in review. `PREFAB-03` and `PREFAB-12` can't be checked from the prefab alone, so the handoff states them (`HAND-01`).
