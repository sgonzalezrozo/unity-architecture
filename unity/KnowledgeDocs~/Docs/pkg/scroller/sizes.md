# UI Scroller: slot sizes

| Slot | Size |
|---|---|
| `DefaultExtent > 0` | Fixed; nothing is measured |
| `DefaultExtent <= 0` | Measured with the slot's layout when shown, then cached |
| Expandable with `DefaultExtent > 0` | Fixed when closed; measured while open |

A measured slot needs a layout group on its root with **Control Child Size** on and **Child Force Expand** off.

> [!RULE] LIST-06
> `Content` has no layout components (`ContentSizeFitter`, `LayoutGroup`, `LayoutElement`), and the slot root has no `ContentSizeFitter`: the list sets those sizes.

> [!TIP]
> `InvalidateSize(index)` / `InvalidateAllSizes()` when a size depends on something the slot can't notice itself.
