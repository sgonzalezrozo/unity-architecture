# A list without UI Scroller

Without the package, the list View only **creates cells** and activates as many as there are items. Each cell is a prefab (its own scope) that **pulls its item by position**: nothing is pushed.

```csharp
private void RenderVisibleItems()
{
    CreateMissingCells(inventoryModel.ItemCount);

    for (int i = 0; i < itemCells.Count; i++)
        itemCells[i].SetActive(i < inventoryModel.ItemCount);
}
```

```csharp
// In the cell's View
private void RenderItem()
{
    int itemIndex = transform.GetSiblingIndex();

    if (itemIndex < inventoryModel.ItemCount)
        itemNameText.text = inventoryModel.GetItem(itemIndex).displayName;
}
```

> [!WARNING]
> One cell per item: fine for short lists. A long list needs virtualization; **ask** before adding a package.
