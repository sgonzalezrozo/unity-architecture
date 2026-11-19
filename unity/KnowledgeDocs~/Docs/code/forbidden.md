# Forbidden in client code

| <color=#F85149>Never</color> | <color=#3FB950>Instead</color> | Analyzer |
|---|---|---|
| Lambdas and anonymous methods | Named methods | `UA0009` |
| LINQ | `for` loops | `UA0010` |
| `var` | Explicit type | `UA0011` |
| `?.`, `??`, `??=` on Unity objects | `if (x == null)` | `UA0012` |
| `foreach` on `List<T>` | `for` | Review |
| `Action<T>` or `{ get; set; }` events | `public event Action OnChanged;` | `UA0004` |
| `async void`, `.Result`, `.Wait()` | `async Task` + `.Forget("Context")` | Review |
| `SceneManager` directly | The project's scene loader | Review |

> [!WARNING] Why no `?.` on Unity objects?
> It bypasses Unity's destroyed-object check: a destroyed object isn't `null` to C#, but it is to `==`.

> [!NOTE]
> Lambdas and LINQ are forbidden in **all** client code, not only hot paths, so hot paths never need an audit. Tests may use lambdas.
