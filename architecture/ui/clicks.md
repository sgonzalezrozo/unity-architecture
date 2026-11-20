# Clicks and input

## Selectable replacements

| Do not use | Use |
|---|---|
| `Button` | Graphic plus click Controller |
| `Toggle` | View with On and Off roots, plus click Controller |
| `Slider` | `Image` fill plus Controller with `IPointerDownHandler` and `IDragHandler` |
| `Dropdown` | Modal with a list |
| `TMP_InputField` | Allowed. The one exception to `ARCH-05` |

## Clickable elements

```
CloseButton
├── UI Content (what the Action hits; a press tween punches it: PREFAB-17)
│   └── Visuals
│       ├── Background (Image, raycastTarget on: blocks what's under it)
│       └── Label (TextMeshProUGUI, raycastTarget off)
└── Action (Image: alpha 0, raycastTarget on) [CloseController]
```

| ID | Rule |
|---|---|
| `INPUT-01` | The Controller MUST sit on a dedicated child named `Action`, separate from the visuals. The class is named after what it does, `{Action}Controller`, whatever the hierarchy around it. With several actions, every input object is still `Action`: its parent's name tells them apart. |
| `INPUT-02` | `Action` MUST have its own raycast target that fills the element, and MUST be the last sibling. Pointer events bubble to parents, not to siblings. The one exception is a modal's close `Action`, under the `Window`, which blocks touches with its own `Background` (`PREFAB-11`). |
| `INPUT-03` | Visual-only Graphics MUST have `raycastTarget` off. The exception is a `Background` that blocks touches from reaching what's under it: the one of an element with an `Action`, and the one of a screen (`PREFAB-14`). |
| `INPUT-04` | In a multi-state element, `Action` MUST be inside the state that accepts input, so other states can't be clicked. |
| `INPUT-05` | A screen-level Controller MUST handle only lifecycle events, never input from a child element. |

> **Fork `input`** · the click Controller's base class and raycast target. Open only the branch the [profile](../OPTIONAL_PACKAGES.md#the-profile) names:
> - `ui-foundations`: [UI Foundations: click Controllers](../branches/ui-foundations/clicks.md)
> - `no-ui-foundations`: [Click Controllers without UI Foundations](../branches/no-ui-foundations/clicks.md)
