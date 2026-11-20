# UI Scroller: layouts and API

Branch `ui-scroller` of the `list` fork, after [UI Scroller lists](lists.md). Read it when a list needs expandable slots, measured sizes, a grid, a bento layout, a carousel or a pager.

## Expandable slots

An expandable slot implements `IExpandableSlot<T>`. The list sets `Owner`, `ItemIndex` and `IsExpanded` on every bind. The `IsExpanded` setter fires the same event as `Data`, and the click asks the list to open or close the item. Never redraw the View from the click directly: the list measures the slot, moves the slots after it and remembers the state when the slot is reused.

```csharp
public bool IsExpanded
{
    get => isExpanded;
    set
    {
        if (isExpanded == value)
            return;

        isExpanded = value;
        OnItemDataChanged?.Invoke();
    }
}

public IScroller Owner { get; set; }
public int ItemIndex { get; set; }

public void OnCollapsed()
    => IsExpanded = false;

public void ToggleExpanded()
{
    if (Owner.IsExpanded(ItemIndex))
        Owner.Collapse(ItemIndex);
    else
        Owner.Expand(ItemIndex);
}
```

## Slot sizes

| Slot | Size |
|---|---|
| `DefaultExtent > 0` | Fixed. Nothing is measured |
| `DefaultExtent <= 0` | Measured with the slot's Unity layout when shown, then cached |
| `DefaultExtent > 0`, expandable, `Expand(index)` without a size | Fixed when closed; measured with its layout while open |

A measured slot (or an expandable one) needs a layout group on its root with **Control Child Size** on and **Child Force Expand** off, and layout down to the element that grows, such as the text. The list reads the root's preferred size itself.

In a grid, slots stretch to fill their line. In a bento layout, the layout decides every tile's size: columns and tiles come from a **Layout JSON** (a TextAsset) or `SetBentoLayout(BentoLayout)`, and the row height from **Cell Aspect**. The slot stretches to its tile, so the Slot View lays out for any size.

## Layout choices

| Need | Settings |
|---|---|
| A list in any direction | **Layout: List**, **Direction** |
| A fixed or responsive grid | **Layout: Grid** (`slotsPerLine`) or **Auto Grid** (`targetSlotSize`) |
| Tiles of different sizes (featured, strips) | **Layout: Bento** with a Layout JSON; items never choose their size |
| Sections with headers | `SectionedScroller<TItem, THeader>`; **Section Spacing** adds space before every header except the first, **Header To Content Spacing** between a header and its content |
| A carousel | **Loop**, **Snap: Item**, **Snap Align: Center**; scale or fade the centred card from `IViewportPositionListener` on the Slot View |
| A carousel inside a vertical list | Nothing to set up: drags across a list's axis go to its parent. Each row's Slot Model gives the inner list its source |
| A pager | **Snap: Page** |
| An endless feed | A `PagedSource<T>` with an `IPageLoader<T>` |

Grids and bento don't expand. A looping list is a list or a bento layout (each round starts the bento layout again): no grid, sections or expanding. With a `PagedSource`, Loop uses the first page as the whole list and loads no more pages. A sectioned list doesn't page.

## UI Scroller API

| Member | Use |
|---|---|
| `SetSource(source)` | Give the list its source (starts it), or replace the source |
| `Refresh()` | Redraw after data changes. Call once per batch |
| `InvalidateSize(index)`, `InvalidateAllSizes()` | Measure again when a measured slot's size depends on something it can't notice itself |
| `Expand(index)`, `Collapse(index)`, `IsExpanded(index)`, `ExpandedCount` | Expandable slots |
| `ScrollToItem(index, align, duration, offset)`, `ScrollToStart(duration)`, `ScrollToEnd(duration)` | Jump or animate to a position (`ScrollAlign`: Start, Center, End, Nearest) |
| `SetBentoLayout(layout)`, `GetTile(index)` | Bento: change the layout, read where an item sits |
| `GetViewportPosition(index)`, `IViewportPositionListener` | Where a shown item sits in the viewport (0 centre, ±0.5 edges), for carousel effects |
| `ForceStopScrolling()`, `Clear()` | Stop momentum, remove all slots |
| `IsInitialized`, `IsScrolling`, `VisibleStartIndex`, `VisibleEndIndex`, `GetItemOffset(index)`, `GetItemSize(index)`, `ViewportSize`, `ContentSize` | Read state |
| `ItemExpanded`, `ItemCollapsed`, `Rebuilt`, `ContentSizeChanged`, `SnappedTo`, `PageLoaded`, `PageFailed`, `ReachedEnd` | Read-only events |
| `SectionedScroller`: `SetSource(SectionedSource<TItem, THeader>)`, `ScrollToSection(index, duration)` | Sections with headers (Header Prefab implements `ISlot<THeader>`) |
