# UI Scroller: which layout

| You need | Settings |
|---|---|
| A list in any direction | **Layout: List**, **Direction** |
| A fixed or responsive grid | **Grid** (`slotsPerLine`) or **Auto Grid** (`targetSlotSize`) |
| Tiles of different sizes | **Bento** with a Layout JSON |
| Sections with headers | `SectionedScroller<TItem, THeader>` |
| A carousel | **Loop**, **Snap: Item**, **Snap Align: Center** |
| A carousel inside a vertical list | Nothing: cross-axis drags go to the parent |
| A pager | **Snap: Page** |
| An endless feed | `PagedSource<T>` with an `IPageLoader<T>` |

> [!RULE] LIST-08
> A bento tile's size comes from the **layout** (JSON or `SetBentoLayout`), never from the item or the slot.

> [!NOTE]
> A loop allows no grid, sections or expanding. A sectioned list doesn't page.
