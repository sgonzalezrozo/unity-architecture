# Screen System: concepts

A **layer-based** UI manager for uGUI and UI Toolkit. All UI lives in one persistent `ScreenSystem` object.

- A **screen** = a prefab + an ordered list of **layers** (`LayerDefinition`), like layers in an image editor.
- A top bar or background is **one** layer that any screen lists; screens share the instance.
- At most **one fullscreen, one modal and one alert** render at once. Behind a modal is a blurred snapshot.
- Screens load on request and unload on scene change.

| Type | Use |
|---|---|
| `Fullscreen` | A normal screen |
| `Modal` | A popup or confirmation; one open at a time |
| `Alert` | A blocking message (connection lost); closed with `DismissAlert()` |

> [!RULE] SCR-04
> A part repeated across screens is **one layer** listed in each `LayerDefinition`, not a copy.
