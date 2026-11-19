# MVC en resumen

Tres capas, tres trabajos. Pulsa una capa para ver su detalle.

| Capa | Trabajo | Nunca |
|---|---|---|
| [**Model**](doc:model.que_es) | Guarda el estado, aplica reglas, avisa con eventos sin datos | Conocer Views, Controllers o componentes de Unity |
| [**View**](doc:view.forma) | Lee Models y pinta | Recibir input o llamar comandos |
| [**Controller**](doc:controller.forma) | Convierte un input en un comando | Cambiar algo visual o decidir |

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

**Ver también:** [Quién conoce a quién](doc:arquitectura.dependencias) · [Pull, nunca push](doc:arquitectura.pull_no_push) · [Dónde vive cada Model](doc:scopes.donde_vive_model) · [Crear un elemento de UI](doc:ui.crear_ui)
