# Scopes

A scope is a self-contained part of a feature with one root GameObject, usually a prefab root. A feature is not a scope: a large feature is divided into several.

```
InventoryScreen.prefab [InventoryModel, InventoryView]      main scope
├── ItemList [InventoryListView]                            scope
└── ActionButtons [ActionButtonsView]                       scope
    ├── Action (Image: alpha 0) [ApplyController]
    └── Action (Image: alpha 0) [RevertController]
```

| ID | Rule |
|---|---|
| `SCOPE-01` | Nesting a prefab inside another MUST NOT change its scope. Its root stays the root. |
| `SCOPE-02` | A scope's Model and View MUST sit on its root. Controllers stay on their input objects (`INPUT-01`). |
| `SCOPE-03` | A Model MUST stay on its scope root. It moves to the lowest common parent only when another scope or feature needs it. |
| `SCOPE-04` | A View MUST render only inside its scope. Its serialized references MUST NOT point outside it. |
| `SCOPE-05` | A View or Controller MAY read a Model outside its scope, by looking up the hierarchy or through injection. |
