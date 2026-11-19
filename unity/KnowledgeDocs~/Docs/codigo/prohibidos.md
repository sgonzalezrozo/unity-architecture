# Prohibido en código cliente

| <color=#F85149>Nunca</color> | <color=#3FB950>En su lugar</color> | Analyzer |
|---|---|---|
| Lambdas y métodos anónimos | Métodos con nombre | `UA0009` |
| LINQ | Bucles `for` | `UA0010` |
| `var` | Tipo explícito | `UA0011` |
| `?.`, `??`, `??=` sobre objetos de Unity | `if (x == null)` | `UA0012` |
| `foreach` sobre `List<T>` | `for` | Review |
| Eventos `Action<T>` o `{ get; set; }` | `public event Action OnChanged;` | `UA0004` |
| `async void`, `.Result`, `.Wait()` | `async Task` + `.Forget("Contexto")` | Review |
| `SceneManager` directo | El scene loader del proyecto | Review |

> [!WARNING] ¿Por qué `?.` con Unity?
> Salta el chequeo de "objeto destruido": un objeto destruido no es `null` para C#, pero sí para `==`.

> [!NOTE]
> Lambdas y LINQ están prohibidos en **todo** el código cliente, no solo en hot paths, para que los hot paths nunca necesiten auditoría. En tests sí se permiten lambdas.
