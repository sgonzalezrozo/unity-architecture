# Menus and shortcuts: UI Scroller

| Menu | For |
|---|---|
| **Window > UI Scroller > Bento Layout Editor** | Draw a bento layout and export it to JSON |
| **Assets > UI Scroller > New Scroll List** | A wizard that generates a list's scripts and prefabs |

> [!NOTE] LIST-09
> **New Scroll List** writes the list split the way the rules want: `{Name}ItemData`, `{Name}ItemSlotModel` (the `ISlot`), `{Name}ItemSlotView`, `{Name}Scroller`, `{Name}ListModel` (owns the items, `IItemSource`) and `{Name}ListView`, in the feature's namespace, and adds their assemblies to the folder's `.asmdef`. Expandable items open through `Toggle{Name}ItemController` on an `Action`. It passes the analyzers, and its prefabs follow the prefab rules (`Action`, `UI Content`, raycasts).

> [!WARNING]
> An older UI Scroller whose wizard writes `{Name}ItemController`, `{Name}ScrollList` and `{Name}Instantiator` breaks the rules: don't use it under `Assets/Client`. The agent never runs the wizard (`EDIT-13`): it writes the same files itself.

Adding the `Scroller` component to an empty UI object builds its `Viewport` and `Content`. The Inspector shows direction, layout (List, Grid, Auto Grid, Bento), spacing, padding, snapping and loop.
