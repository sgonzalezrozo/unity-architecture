# UI Scroller: lists

Branch `ui-scroller` of the `list` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `list: ui-scroller`.

Dynamic lists and grids MUST use UI Scroller: `Scroller<T>`, or `SectionedScroller<TItem, THeader>` for sections with headers.

`Scroller<T>` is generic, so declare one concrete class per data type. It isn't a Model, View or Controller: the suffix is `Scroller`.

```csharp
public class ItemScroller : Scroller<ItemData>
{
}
```

Add it to an empty UI object that already has the size and anchors the list needs on screen. Adding the component builds the rest, and its inspector shows only direction, layout (List, Grid, Auto Grid, Bento), spacing, padding, snapping and loop:

```
ItemList [ItemListView]
└── ItemScroller [ItemScroller]
    └── Viewport (RectMask2D, Canvas, GraphicRaycaster)
        └── Content (RectTransform)

ItemSlot.prefab [ItemSlotModel, ItemSlotView]
├── UI Content [VerticalLayoutGroup when measured]
│   ├── ItemIcon (Image)
│   └── ItemNameText (TextMeshProUGUI)
└── Action (Image: alpha 0) [SelectItemController]
```

## Source

The Model that owns the list implements `IItemSource<T>`:

```csharp
public int ItemCount => items.Count;

public ItemData GetItem(int index)
{
    return items[index];
}

public IReadOnlyList<ItemData> GetAllItems()
{
    return items;
}
```

The list View gives the list its source once and refreshes it on each change:

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

`ListSource<T>`, `FilteredSource<T>` and `PagedSource<T>` (pages through an `IPageLoader<T>`) are ready-made sources. A paged source loads its next page by itself near the end of the list: don't call `Refresh()` for pages.

## Slot Model

A MonoBehaviour Model on the slot prefab. It implements the package's `ISlot<T>`; the `Model` suffix still decides its layer.

```csharp
public class ItemSlotModel : MonoBehaviour, IInjectableForChildren, ISlot<ItemData>
{
    private const float SLOT_HEIGHT = 120f;

    public event Action OnItemDataChanged;

    internal InventoryModel inventoryModel;

    private ItemData itemData;

    public float DefaultExtent => SLOT_HEIGHT;
    public bool IsSelected => itemData != null && inventoryModel.SelectedItemId == itemData.id;

    public ItemData Data
    {
        get => itemData;
        set
        {
            itemData = value;
            OnItemDataChanged?.Invoke();
        }
    }

    public void SelectItem()
    {
        if (itemData != null)
            inventoryModel.SelectItem(itemData.id);
    }
}
```

## Rules

| ID | Rule |
|---|---|
| `LIST-01` | With the packages, `IInjectableForChildren` gives the slot its `internal` fields, and `ISlot<T>` (or `IExpandableSlot<T>`) is how the list sets `Data`. |
| `LIST-02` | The `Data` setter (and `IsExpanded`) MUST fire an event, and the Slot View MUST redraw from it. Pooled slots stay active out of view, so a reused slot's `OnEnable` doesn't run: `OnEnable` alone shows stale content. This is the one accepted push, and it MUST stop at the Slot Model. |
| `LIST-03` | Slot Views and Controllers MUST get the Slot Model with `GetComponentInParent<TSlotModel>()` in `Awake`. |
| `LIST-04` | Slots MUST NOT be instantiated by hand or call `Initialize(data)`. |
| `LIST-05` | A Slot Model exists to serve its slot, so it MAY expose derived values for that slot's Views. This is the one exception to `ARCH-04`. |
| `LIST-06` | Content MUST NOT have layout components (`ContentSizeFitter`, `LayoutGroup`, `LayoutElement`), and the slot's root MUST NOT have a `ContentSizeFitter`: the list sets those sizes itself. |
| `LIST-07` | Item state (selected, expanded, unlocked) MUST live in the item or a Model, never in the slot: the slot shows another item later. |
| `LIST-08` | A bento tile's size MUST come from the layout (Layout JSON or `SetBentoLayout`), never from the item or the slot. Bento layouts are data: write the JSON, don't compute tile positions in code. |
| `LIST-09` | With `uiScroller`, a person MAY start a list with **Assets > UI Scroller > New Scroll List**, when its output is the Model, View and Controller split: `{Name}ItemData`, `{Name}ItemSlotModel` (the `ISlot<T>`, whose `Data` setter fires an event, `LIST-02`), `{Name}ItemSlotView`, `{Name}Scroller`, `{Name}ListModel` (owns the items and implements `IItemSource<T>`) and `{Name}ListView`, in the feature's namespace, with `Toggle{Name}ItemController` on an `Action` for expandable items. It adds the assemblies the scripts need to the folder's `.asmdef` (`ASM-02`). An older UI Scroller whose wizard writes `{Name}ItemController`, `{Name}ScrollList` and `{Name}Instantiator` MUST NOT be used under `Assets/Client`: that output breaks `ARCH-02`, `-03`, `-04`, `-05` and `LIST-02`. The agent doesn't run the wizard (`EDIT-13`): it writes the same files itself. A bento layout is drawn by a person in **Window > UI Scroller > Bento Layout Editor**, or written as JSON by the agent (`LIST-08`). |

Expandable slots, slot sizes, grids, bento, carousels and the API: [UI Scroller layouts](lists-layouts.md).

Verify these symbols before use: `Scroller<T>`, `SectionedScroller<TItem, THeader>`, `ISlot<T>`, `IExpandableSlot<T>`, `IScroller`, `IItemSource<T>`, `ListSource<T>`, `FilteredSource<T>`, `PagedSource<T>`, `IPageLoader<T>`, `SectionedSource<TItem, THeader>`, `BentoLayout`, `ScrollAlign`.
