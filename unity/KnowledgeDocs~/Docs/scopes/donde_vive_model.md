# Dónde vive cada Model

Usa la **primera fila** que encaje:

| # | Caso | Dónde vive | Cómo lo obtienen |
|:---:|---|---|---|
| 1 | Sus Views y Controllers pueden compartir padre | MonoBehaviour en el padre común más bajo | `GetComponentInParent<TModel>()` |
| 2 | No pueden, o debe persistir | C# puro creado por el contenedor (sin él: singleton) | Campo `internal` inyectado (o `TModel.Instance`) |
| 3 | Fuera de MVC: nadie de UI lo usa | Creado por el contenedor | No lo obtienen: solo otros Models |

> [!RULE] ROOT-06
> La inyección es la **excepción**. Si puede existir un padre común, el Model no se inyecta.

> [!RULE] ROOT-02
> `GetComponentInParent` en `Awake`, cacheado. Un singleton o un service locator no lo reemplazan.

> [!RULE] ROOT-08
> Views y Controllers no referencian un Model de la fila 3.

**Ver también:** [Cuándo inyectar](doc:di.cuando_inyectar) · [Singletons sin contenedor](doc:scopes.singletons) · [Qué es un scope](doc:scopes.que_es)
