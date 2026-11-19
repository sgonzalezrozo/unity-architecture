# Ejemplo: lista filtrada (Inventario)

Las pestañas filtran **una** lista y un panel de detalles muestra la selección. Todo local, sin backend.

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

- Pestañas de **una sola clase** View y una Controller; el enum serializado elige cuál.
- Como solo filtran, ninguna pestaña tiene su propio prefab de contenido.
- La lista filtrada no asigna memoria al cambiar de pestaña.
- La selección vive en `InventoryModel`, compartida por la lista y el panel.
