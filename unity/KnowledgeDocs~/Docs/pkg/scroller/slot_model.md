# UI Scroller: Slot Model

A MonoBehaviour Model on the slot prefab, implementing `ISlot<T>`.

```csharp
public class ItemSlotModel : MonoBehaviour, IInjectableForChildren, ISlot<ItemData>
{
    private const float SLOT_HEIGHT = 120f;

    public event Action OnItemDataChanged;

    internal InventoryModel inventoryModel;

    private ItemData itemData;

    public float DefaultExtent => SLOT_HEIGHT;

    public ItemData Data
    {
        get => itemData;
        set
        {
            itemData = value;
            OnItemDataChanged?.Invoke();
        }
    }
}
```

| ID | Rule |
|---|---|
| `LIST-02` | The `Data` setter fires an event and the Slot View redraws from it (reused slots don't go through `OnEnable`). It's the **one accepted push** |
| `LIST-03` | Slot Views and Controllers get the Slot Model with `GetComponentInParent` in `Awake` |
| `LIST-04` | Slots are never instantiated by hand or given `Initialize(data)` |
| `LIST-05` | A Slot Model may expose derived values for its slot |
| `LIST-07` | Item state (selected, open) lives in the item or a Model, **never** in the slot |
