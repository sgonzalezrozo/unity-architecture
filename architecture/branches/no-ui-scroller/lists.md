# Lists without UI Scroller

Branch `no-ui-scroller` of the `list` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `list: no-ui-scroller`.

The list View only creates cells and shows as many as there are items. It holds GameObjects, never a cell View: each cell is a prefab, so its own scope (`VIEW-03`). Each cell finds the Model and pulls its own item by position, so no data is pushed (`ARCH-04`).

```csharp
public class InventoryListView : MonoBehaviour
{
    [SerializeField] private GameObject inventoryCellPrefab;
    [SerializeField] private RectTransform itemContainer;

    private readonly List<GameObject> itemCells = new();

    private InventoryModel inventoryModel;

    private void Awake()
    {
        inventoryModel = GetComponentInParent<InventoryModel>();
    }

    private void OnEnable()
    {
        inventoryModel.OnVisibleItemsChanged += RenderVisibleItems;
        RenderVisibleItems();
    }

    private void OnDisable()
    {
        inventoryModel.OnVisibleItemsChanged -= RenderVisibleItems;
    }

    private void RenderVisibleItems()
    {
        CreateMissingCells(inventoryModel.ItemCount);

        for (int i = 0; i < itemCells.Count; i++)
            itemCells[i].SetActive(i < inventoryModel.ItemCount);
    }

    private void CreateMissingCells(int requiredCellCount)
    {
        while (itemCells.Count < requiredCellCount)
            itemCells.Add(Instantiate(inventoryCellPrefab, itemContainer));
    }
}

public class InventorySlotView : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI itemNameText;

    private InventoryModel inventoryModel;

    private void Awake()
    {
        inventoryModel = GetComponentInParent<InventoryModel>();
    }

    private void OnEnable()
    {
        inventoryModel.OnVisibleItemsChanged += RenderItem;
        RenderItem();
    }

    private void OnDisable()
    {
        inventoryModel.OnVisibleItemsChanged -= RenderItem;
    }

    private void RenderItem()
    {
        int itemIndex = transform.GetSiblingIndex();

        if (itemIndex < inventoryModel.ItemCount)
            itemNameText.text = inventoryModel.GetItem(itemIndex).displayName;
    }
}
```

This creates one cell per item, so it fits short lists. A long list needs virtualization: ask before adding a package.
