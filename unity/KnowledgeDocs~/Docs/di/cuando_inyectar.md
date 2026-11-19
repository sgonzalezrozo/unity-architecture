# Cuándo inyectar

La mayoría de Views y Controllers **no** usan inyección: encuentran su Model en un padre común con `GetComponentInParent`. La inyección es para las filas 2 y 3 de [Dónde vive cada Model](doc:scopes.donde_vive_model).

| Tienes | Mecanismo |
|---|---|
| Fast IoC | Campos `internal` inyectados |
| Otro contenedor (Zenject, VContainer) | Su propia inyección |
| Ninguno | Singleton `TModel.Instance` (`ROOT-07`) |

| Clase | Cómo obtiene la referencia |
|---|---|
| View / Controller, Model en padre común | `GetComponentInParent<TModel>()` cacheado |
| View / Controller, sin padre común o Model persistente | Campo `internal` |
| Model MonoBehaviour, config, Model fuera de MVC | Campo `internal` |
| Clase C# pura | Constructor |

> [!CAUTION]
> Un **service locator** no se usa en ningún caso.
