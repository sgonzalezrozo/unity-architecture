# UI Scroller: tamaños de slot

| Slot | Tamaño |
|---|---|
| `DefaultExtent > 0` | Fijo; no se mide nada |
| `DefaultExtent <= 0` | Medido con el layout del slot al mostrarse, y cacheado |
| Expandible con `DefaultExtent > 0` | Fijo cerrado; medido mientras está abierto |

Un slot medido necesita un layout group en su raíz con **Control Child Size** on y **Child Force Expand** off.

> [!RULE] LIST-06
> `Content` no tiene componentes de layout (`ContentSizeFitter`, `LayoutGroup`, `LayoutElement`), y la raíz del slot no tiene `ContentSizeFitter`: la lista pone esos tamaños.

> [!TIP]
> `InvalidateSize(index)` / `InvalidateAllSizes()` cuando el tamaño depende de algo que el slot no detecta solo.
