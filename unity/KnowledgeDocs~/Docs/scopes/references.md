# Getting references

| Layer | Serialized | Injected `internal` | `GetComponentInParent` | Constructor |
|---|---|---|---|---|
| **Pure C# Model** | No | No | No | <color=#3FB950>Yes</color> |
| **MonoBehaviour Model** | No | Models | Parent Models | No |
| **View** | Rendering, state roots, config | Row 2 Models | Row 1 Models | No |
| **Controller** | Config | Row 2 Models | Row 1 Models | No |

- `internal` is reserved for injected fields; everything else is `private`.
- Don't null-check injected fields: if injection fails, it should fail loudly (`DI-06`).

> [!DONT]
> `view.Initialize(model)`, `[Inject]` or service locators (`UA0006`, `UA0007`).
