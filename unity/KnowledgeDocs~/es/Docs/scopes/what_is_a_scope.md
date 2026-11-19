# Qué es un scope

Una parte autocontenida de una feature con **un GameObject raíz** (normalmente la raíz de un prefab). Una feature grande se parte en varios scopes; una feature **no** es un scope.

```text
InventoryScreen.prefab [InventoryModel, InventoryView]      scope principal
├── ItemList [InventoryListView]                            scope
└── ActionButtons [ActionButtonsView]                       scope
    ├── Action (Image: alpha 0) [ApplyController]
    └── Action (Image: alpha 0) [RevertController]
```

| ID | Regla |
|---|---|
| `SCOPE-01` | Anidar un prefab en otro **no** cambia su scope |
| `SCOPE-02` | El Model y la View van en la raíz del scope; los Controllers, en sus objetos de input |
| `SCOPE-03` | El Model sube al padre común más bajo solo si otro scope lo necesita |
| `SCOPE-04` | Una View solo pinta dentro de su scope; sus referencias no salen de él |
| `SCOPE-05` | Una View o Controller **sí** puede leer un Model de fuera (subiendo o por inyección) |

**Ver también:** [Dónde vive cada Model](doc:scopes.where_a_model_lives) · [View raíz e inner Views](doc:view.inner_views)
