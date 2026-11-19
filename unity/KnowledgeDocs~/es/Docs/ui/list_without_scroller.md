# Lista sin UI Scroller

Sin el package, la View de la lista solo **crea celdas** y activa tantas como items haya. Cada celda es un prefab (su propio scope) que **pide su item por posición**: nada se empuja.

```csharp
private void RenderVisibleItems()
{
    CreateMissingCells(inventoryModel.ItemCount);

    for (int i = 0; i < itemCells.Count; i++)
        itemCells[i].SetActive(i < inventoryModel.ItemCount);
}
```

```csharp
// En la View de la celda
private void RenderItem()
{
    int itemIndex = transform.GetSiblingIndex();

    if (itemIndex < inventoryModel.ItemCount)
        itemNameText.text = inventoryModel.GetItem(itemIndex).displayName;
}
```

> [!WARNING]
> Crea una celda por item: vale para listas cortas. Una lista larga necesita virtualización; **pregunta** antes de añadir un package.
