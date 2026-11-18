# UI patterns

**Load when:** building clickable elements, visual states, tabs, lists or layouts.

Patterns are mandatory. The packages that implement them are optional: see [Optional packages](OPTIONAL_PACKAGES.md).

## Selectable replacements

| Do not use | Use |
|---|---|
| `Button` | Graphic plus click Controller |
| `Toggle` | View with On and Off roots, plus click Controller |
| `Slider` | `Image` fill plus Controller with `IPointerDownHandler` and `IDragHandler` |
| `Dropdown` | Modal with a list |
| `TMP_InputField` | Allowed. The one exception to `ARCH-05` |

## Clickable elements

```
CloseButton
├── Visuals
│   ├── Background (Image, raycastTarget on: blocks what's under it)
│   └── Label (TextMeshProUGUI, raycastTarget off)
└── Action (Image: alpha 0, raycastTarget on) [CloseController]
```

| ID | Rule |
|---|---|
| `INPUT-01` | The Controller MUST sit on a dedicated child named `Action`, separate from the visuals. The class is named after what it does, `{Action}Controller`, whatever the hierarchy around it. With several actions, every input object is still `Action`: its parent's name tells them apart. |
| `INPUT-02` | `Action` MUST have its own raycast target that fills the element, and MUST be the last sibling. Pointer events bubble to parents, not to siblings. The one exception is a modal's close `Action`, under the `Window`, which blocks touches with its own `Background` (`PREFAB-11`). |
| `INPUT-03` | Visual-only Graphics MUST have `raycastTarget` off. The exception is a `Background` that blocks touches from reaching what's under it: the one of an element with an `Action`, and the one of a screen (`PREFAB-14`). |
| `INPUT-04` | In a multi-state element, `Action` MUST be inside the state that accepts input, so other states can't be clicked. |
| `INPUT-05` | A screen-level Controller MUST handle only lifecycle events, never input from a child element. |

## Visual states

Use for two or more mutually exclusive looks of one element, such as Loading, Loaded and Failed.

```
PurchaseArea [PurchaseStateView]
├── AvailableRoot
│   ├── PriceText (TextMeshProUGUI)
│   └── Action (Image: alpha 0) [BuyController]
├── LockedRoot
│   └── LockIcon (Image)
└── OwnedRoot
    └── OwnedBadge (Image)
```

| ID | Rule |
|---|---|
| `STATE-01` | The Model MUST expose the state, preferably as an enum. |
| `STATE-02` | The View MUST render every root from that state in one method. See [the code](OPTIONAL_PACKAGES.md#visual-state-view). |
| `STATE-03` | One state set per concern. Nest them if needed. |
| `STATE-04` | A View inside an inactive root is disabled, so it MUST read the Model again in `OnEnable`. |
| `STATE-05` | To show or hide one element, use `CanvasGroup` or the View's own logic. |

## Tabs

Tab content is static: nested in the prefab at edit time, never instantiated at runtime. Expensive content SHOULD load when its tab opens (`PERF-01`).

```
InventoryScreen
├── Tabs
│   ├── WeaponsTab [InventoryTabView]
│   │   ├── ActiveRoot
│   │   ├── InactiveRoot
│   │   └── Action (Image: alpha 0) [SelectTabController]
│   └── ArmorTab (same components, different serialized tab)
└── Content [TabContentView]
    ├── WeaponsContent (CanvasGroup)
    └── ArmorContent (CanvasGroup)
```

- One Model MUST hold the selected tab, preferably as an enum.
- Tab elements MUST share one View class and one Controller class. A serialized enum selects the tab.
- Each tab has its own prefab, nested in the screen.
- Hide tabs with `CanvasGroup` (`alpha`, `interactable`, `blocksRaycasts`) so their Views stay subscribed. Use `SetActive` when a hidden tab is expensive.
- Tabs that filter one list need no separate prefabs: see [Filtered list](examples/03_FILTERED_LIST_INVENTORY.md).

## Lists

If `uiScroller = true`, dynamic lists and grids MUST use UI Scroller: `Scroller<T>`, or `SectionedScroller<TItem, THeader>` for sections with headers. Otherwise, see [List without UI Scroller](OPTIONAL_PACKAGES.md#list-without-ui-scroller).

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

ItemSlot.prefab [ItemSlotModel, ItemSlotView, VerticalLayoutGroup when measured]
├── ItemIcon (Image)
├── ItemNameText (TextMeshProUGUI)
└── Action (Image: alpha 0) [SelectItemController]
```

### Source

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

### Slot Model

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

### Expandable slots

An expandable slot implements `IExpandableSlot<T>`. The list sets `Owner`, `ItemIndex` and `IsExpanded` on every bind. The `IsExpanded` setter fires the same event as `Data`, and the click asks the list to open or close the item. Never redraw the View from the click directly: the list measures the slot, moves the slots after it and remembers the state when the slot is reused.

```csharp
public bool IsExpanded
{
    get => isExpanded;
    set
    {
        if (isExpanded == value)
            return;

        isExpanded = value;
        OnItemDataChanged?.Invoke();
    }
}

public IScroller Owner { get; set; }
public int ItemIndex { get; set; }

public void OnCollapsed()
    => IsExpanded = false;

public void ToggleExpanded()
{
    if (Owner.IsExpanded(ItemIndex))
        Owner.Collapse(ItemIndex);
    else
        Owner.Expand(ItemIndex);
}
```

### Slot sizes

| Slot | Size |
|---|---|
| `DefaultExtent > 0` | Fixed. Nothing is measured |
| `DefaultExtent <= 0` | Measured with the slot's Unity layout when shown, then cached |
| `DefaultExtent > 0`, expandable, `Expand(index)` without a size | Fixed when closed; measured with its layout while open |

A measured slot (or an expandable one) needs a layout group on its root with **Control Child Size** on and **Child Force Expand** off, and layout down to the element that grows, such as the text. The list reads the root's preferred size itself.

In a grid, slots stretch to fill their line. In a bento layout, the layout decides every tile's size: columns and tiles come from a **Layout JSON** (a TextAsset) or `SetBentoLayout(BentoLayout)`, and the row height from **Cell Aspect**. The slot stretches to its tile, so the Slot View lays out for any size.

### Layout choices

| Need | Settings |
|---|---|
| A list in any direction | **Layout: List**, **Direction** |
| A fixed or responsive grid | **Layout: Grid** (`slotsPerLine`) or **Auto Grid** (`targetSlotSize`) |
| Tiles of different sizes (featured, strips) | **Layout: Bento** with a Layout JSON; items never choose their size |
| Sections with headers | `SectionedScroller<TItem, THeader>`; **Section Spacing** adds space before every header except the first, **Header To Content Spacing** between a header and its content |
| A carousel | **Loop**, **Snap: Item**, **Snap Align: Center**; scale or fade the centred card from `IViewportPositionListener` on the Slot View |
| A carousel inside a vertical list | Nothing to set up: drags across a list's axis go to its parent. Each row's Slot Model gives the inner list its source |
| A pager | **Snap: Page** |
| An endless feed | A `PagedSource<T>` with an `IPageLoader<T>` |

Grids and bento don't expand. A looping list is a list or a bento layout (each round starts the bento layout again): no grid, sections or expanding. With a `PagedSource`, Loop uses the first page as the whole list and loads no more pages. A sectioned list doesn't page.

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

### UI Scroller API

| Member | Use |
|---|---|
| `SetSource(source)` | Give the list its source (starts it), or replace the source |
| `Refresh()` | Redraw after data changes. Call once per batch |
| `InvalidateSize(index)`, `InvalidateAllSizes()` | Measure again when a measured slot's size depends on something it can't notice itself |
| `Expand(index)`, `Collapse(index)`, `IsExpanded(index)`, `ExpandedCount` | Expandable slots |
| `ScrollToItem(index, align, duration, offset)`, `ScrollToStart(duration)`, `ScrollToEnd(duration)` | Jump or animate to a position (`ScrollAlign`: Start, Center, End, Nearest) |
| `SetBentoLayout(layout)`, `GetTile(index)` | Bento: change the layout, read where an item sits |
| `GetViewportPosition(index)`, `IViewportPositionListener` | Where a shown item sits in the viewport (0 centre, ±0.5 edges), for carousel effects |
| `ForceStopScrolling()`, `Clear()` | Stop momentum, remove all slots |
| `IsInitialized`, `IsScrolling`, `VisibleStartIndex`, `VisibleEndIndex`, `GetItemOffset(index)`, `GetItemSize(index)`, `ViewportSize`, `ContentSize` | Read state |
| `ItemExpanded`, `ItemCollapsed`, `Rebuilt`, `ContentSizeChanged`, `SnappedTo`, `PageLoaded`, `PageFailed`, `ReachedEnd` | Read-only events |
| `SectionedScroller`: `SetSource(SectionedSource<TItem, THeader>)`, `ScrollToSection(index, duration)` | Sections with headers (Header Prefab implements `ISlot<THeader>`) |

## Layouts

```
ScreenRoot (fills parent, VerticalLayoutGroup)
├── Header (fixed or preferred height)
├── Content (flexible, fills the remainder)
└── Footer (fixed or preferred height)
```

- Layouts MUST fill the available space and adapt to their container.
- Use `LayoutGroup` with preferred and flexible sizes, not fixed positions.
- More than about 5 hierarchy levels is a warning sign.
- Test at several aspect ratios.
