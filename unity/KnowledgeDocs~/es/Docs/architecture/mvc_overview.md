# MVC en resumen

Tres capas, tres trabajos. Pulsa una capa para ver su detalle.

| Capa | Trabajo | Nunca |
|---|---|---|
| [**Model**](doc:model.what_is_a_model) | Guarda el estado, aplica reglas, avisa con eventos sin datos | Conocer Views, Controllers o componentes de Unity |
| [**View**](doc:view.shape) | Lee Models y pinta | Recibir input o llamar comandos |
| [**Controller**](doc:controller.shape) | Convierte un input en un comando | Cambiar algo visual o decidir |

```flow
Click -> LoseLifeController -> LivesModel.LoseLife() -> OnLivesChanged:amarillo -> LivesView
```

```text
LivesScreen.prefab [LivesModel, LivesView]
├── UI Content
│   └── RemainingLivesText (TextMeshProUGUI)
└── Action (Image: alpha 0) [LoseLifeController]
```

> [!TIP]
> Las capas se reconocen por el **sufijo del nombre**: `*Model` / `*Module`, `*View`, `*Controller`. Los analyzers usan esos sufijos.

**Ver también:** [Quién conoce a quién](doc:architecture.dependencies) · [Pull, nunca push](doc:architecture.pull_not_push) · [Dónde vive cada Model](doc:scopes.where_a_model_lives) · [Crear un elemento de UI](doc:ui.create_ui)
