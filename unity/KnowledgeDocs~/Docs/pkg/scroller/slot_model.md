# UI Scroller: Slot Model

Un Model MonoBehaviour en el prefab del slot, que implementa `ISlot<T>`.

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

| ID | Regla |
|---|---|
| `LIST-02` | El setter de `Data` lanza un evento y la Slot View redibuja desde él (los slots reutilizados no pasan por `OnEnable`). Es el **único push aceptado** |
| `LIST-03` | Slot Views y Controllers obtienen el Slot Model con `GetComponentInParent` en `Awake` |
| `LIST-04` | Nunca se instancian slots a mano ni se llama `Initialize(data)` |
| `LIST-05` | El Slot Model puede exponer valores derivados para su slot |
| `LIST-07` | El estado del item (seleccionado, abierto) vive en el item o un Model, **nunca** en el slot |
