# Example: filtered list (Inventory)

Tabs filter **one** list, and a details panel shows the selection. All local, no backend.

```text
InventoryScreen
├── Tabs
│   ├── WeaponsTab [InventoryTabView]          inventoryTab = Weapons
│   │   ├── UI Content (ActiveRoot, InactiveRoot)
│   │   └── Action (Image: alpha 0) [SelectTabController]
│   ├── ArmorTab
│   └── ConsumablesTab
├── ItemList [InventoryListView]
│   └── InventoryScroller [InventoryScroller]
└── Details [InventoryDetailsView]
    ├── EmptyRoot
    └── SelectedItemRoot
        └── Drop (UI Content + Action [DropItemController])
```

- Tabs from **one** View class and one Controller class; the serialized enum picks which.
- Since they only filter, no tab has its own content prefab.
- The filtered list allocates nothing when the tab changes.
- The selection lives in `InventoryModel`, shared by the list and the panel.
