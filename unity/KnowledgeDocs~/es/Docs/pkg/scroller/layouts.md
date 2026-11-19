# UI Scroller: qué layout usar

| Necesitas | Ajustes |
|---|---|
| Lista en cualquier dirección | **Layout: List**, **Direction** |
| Grid fijo o responsive | **Grid** (`slotsPerLine`) o **Auto Grid** (`targetSlotSize`) |
| Tiles de distintos tamaños | **Bento** con un Layout JSON |
| Secciones con cabecera | `SectionedScroller<TItem, THeader>` |
| Carrusel | **Loop**, **Snap: Item**, **Snap Align: Center** |
| Carrusel dentro de una lista vertical | Nada: los drags cruzados van al padre |
| Paginador | **Snap: Page** |
| Feed infinito | `PagedSource<T>` con un `IPageLoader<T>` |

> [!RULE] LIST-08
> El tamaño de un tile bento sale del **layout** (JSON o `SetBentoLayout`), nunca del item ni del slot.

> [!NOTE]
> Un loop no admite grid, secciones ni expandibles. Una lista con secciones no pagina.
