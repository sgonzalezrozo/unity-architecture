# UI Scroller: una lista

Una lista **virtualizada**: solo cuesta lo que hay en pantalla, sin allocations al hacer scroll.

```csharp
public class ItemScroller : Scroller<ItemData>
{
}
```

```text
ItemList [ItemListView]
└── ItemScroller [ItemScroller]
    └── Viewport (RectMask2D, Canvas, GraphicRaycaster)
        └── Content (RectTransform)
```

El Model dueño de la lista implementa `IItemSource<T>`:

```csharp
public int ItemCount => items.Count;

public ItemData GetItem(int index)
{
    return items[index];
}
```

La View de la lista le da la fuente **una vez** y refresca en cada cambio:

```csharp
private void OnEnable()
{
    inventoryModel.OnItemsChanged += RenderItems;

    if (!itemScroller.IsInitialized)
        itemScroller.SetSource(inventoryModel);

    RenderItems();
}

private void RenderItems()
{
    itemScroller.Refresh();
}
```

> [!NOTE]
> `Scroller<T>` no es Model, View ni Controller: su sufijo es `Scroller`.
