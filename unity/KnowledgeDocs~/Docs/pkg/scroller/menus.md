# Menus and shortcuts: UI Scroller

| Menu | For |
|---|---|
| **Window > UI Scroller > Bento Layout Editor** | Draw a bento layout and export it to JSON |
| **Assets > UI Scroller > New Scroll List** | A wizard that generates a list's scripts and prefabs |

> [!CAUTION] LIST-09
> **New Scroll List isn't used under `Assets/Client`**: its code breaks the rules (an `ItemController` that renders, an `ItemModel` with no event, pushed data, no namespace, a `Button`). It's fine for a prototype **outside** `Assets/Client`.

Adding the `Scroller` component to an empty UI object builds its `Viewport` and `Content`. The Inspector shows direction, layout (List, Grid, Auto Grid, Bento), spacing, padding, snapping and loop.
