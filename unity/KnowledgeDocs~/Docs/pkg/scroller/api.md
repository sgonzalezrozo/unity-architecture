# UI Scroller: API

| Member | Use |
|---|---|
| `SetSource(source)` | Give the list its source (starts it), or replace it |
| `Refresh()` | Redraw after data changes; once per batch |
| `InvalidateSize(i)`, `InvalidateAllSizes()` | Measure again |
| `Expand(i)`, `Collapse(i)`, `IsExpanded(i)` | Expandable slots |
| `ScrollToItem(i, align, duration, offset)` | Go to an item (`ScrollAlign`: Start, Center, End, Nearest) |
| `ScrollToStart(d)`, `ScrollToEnd(d)` | Go to the start or end |
| `SetBentoLayout(layout)`, `GetTile(i)` | Bento |
| `GetViewportPosition(i)`, `IViewportPositionListener` | Position in the viewport, for carousel effects |
| `ForceStopScrolling()`, `Clear()` | Stop momentum, remove slots |

Ready-made sources: `ListSource<T>`, `FilteredSource<T>`, `PagedSource<T>`, `SectionedSource<TItem, THeader>`.
