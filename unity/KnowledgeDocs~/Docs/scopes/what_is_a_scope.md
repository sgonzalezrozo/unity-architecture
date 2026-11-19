# What a scope is

A self-contained part of a feature with **one root GameObject** (usually a prefab root). A large feature splits into several scopes; a feature is **not** a scope.

```text
InventoryScreen.prefab [InventoryModel, InventoryView]      main scope
├── ItemList [InventoryListView]                            scope
└── ActionButtons [ActionButtonsView]                       scope
    ├── Action (Image: alpha 0) [ApplyController]
    └── Action (Image: alpha 0) [RevertController]
```

| ID | Rule |
|---|---|
| `SCOPE-01` | Nesting a prefab in another **doesn't** change its scope |
| `SCOPE-02` | The scope's Model and View sit on its root; Controllers on their input objects |
| `SCOPE-03` | The Model moves up to the lowest common parent only when another scope needs it |
| `SCOPE-04` | A View renders only inside its scope; its references don't leave it |
| `SCOPE-05` | A View or Controller **may** read a Model outside its scope (up the hierarchy or injected) |

**See also:** [Where a Model lives](doc:scopes.where_a_model_lives) · [Root View and inner Views](doc:view.inner_views)
