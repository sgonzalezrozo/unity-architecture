# UI Scroller: API

| Miembro | Uso |
|---|---|
| `SetSource(source)` | Da la fuente a la lista (la arranca) o la reemplaza |
| `Refresh()` | Redibuja tras cambiar datos; una vez por lote |
| `InvalidateSize(i)`, `InvalidateAllSizes()` | Volver a medir |
| `Expand(i)`, `Collapse(i)`, `IsExpanded(i)` | Slots expandibles |
| `ScrollToItem(i, align, duration, offset)` | Ir a un item (`ScrollAlign`: Start, Center, End, Nearest) |
| `ScrollToStart(d)`, `ScrollToEnd(d)` | Ir al principio o al final |
| `SetBentoLayout(layout)`, `GetTile(i)` | Bento |
| `GetViewportPosition(i)`, `IViewportPositionListener` | Posición en el viewport, para efectos de carrusel |
| `ForceStopScrolling()`, `Clear()` | Parar inercia, quitar slots |

Fuentes listas: `ListSource<T>`, `FilteredSource<T>`, `PagedSource<T>`, `SectionedSource<TItem, THeader>`.
