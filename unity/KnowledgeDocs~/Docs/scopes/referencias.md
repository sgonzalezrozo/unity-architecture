# Cómo se obtienen las referencias

| Capa | Serializado | `internal` inyectado | `GetComponentInParent` | Constructor |
|---|---|---|---|---|
| **Model C# puro** | No | No | No | <color=#3FB950>Sí</color> |
| **Model MonoBehaviour** | No | Models | Models padre | No |
| **View** | Render, raíces de estado, config | Models fila 2 | Models fila 1 | No |
| **Controller** | Config | Models fila 2 | Models fila 1 | No |

- `internal` se reserva para campos inyectados; todo lo demás es `private`.
- No compruebes `null` en campos inyectados: si falla, que falle fuerte (`DI-06`).

> [!DONT]
> `view.Initialize(model)`, `[Inject]` o service locators (`UA0006`, `UA0007`).
