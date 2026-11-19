# MVC at a glance

Three layers, three jobs. Click a layer to see its details.

| Layer | Job | Never |
|---|---|---|
| [**Model**](doc:model.what_is_a_model) | Owns state, applies rules, announces changes with parameterless events | Knows Views, Controllers or Unity components |
| [**View**](doc:view.shape) | Reads Models and renders | Handles input or calls commands |
| [**Controller**](doc:controller.shape) | Turns one input into one command | Changes visuals or decides anything |

```flow
Click -> LoseLifeController -> LivesModel.LoseLife() -> OnLivesChanged:yellow -> LivesView
```

```text
LivesScreen.prefab [LivesModel, LivesView]
├── UI Content
│   └── RemainingLivesText (TextMeshProUGUI)
└── Action (Image: alpha 0) [LoseLifeController]
```

> [!TIP]
> Layers are recognized by the **class name suffix**: `*Model` / `*Module`, `*View`, `*Controller`. The analyzers use those suffixes.

**See also:** [Who knows whom](doc:architecture.dependencies) · [Pull, never push](doc:architecture.pull_not_push) · [Where a Model lives](doc:scopes.where_a_model_lives) · [Build a UI element](doc:ui.create_ui)
