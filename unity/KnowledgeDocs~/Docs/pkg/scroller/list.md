# UI Scroller: a list

A **virtualized** (recycled) list: it costs only what's on screen, with no allocations while scrolling.

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

The Model that owns the list implements `IItemSource<T>`:

```csharp
public int ItemCount => items.Count;

public ItemData GetItem(int index)
{
    return items[index];
}
```

The list View gives it the source **once** and refreshes on each change:

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
> `Scroller<T>` isn't a Model, View or Controller: its suffix is `Scroller`.
