# Performance

Do the minimum that completely finishes the need (`ARCH-11`). An empty scene should run far faster than one with every feature ready to use.

| ID | Rule |
|---|---|
| `PERF-01` | A feature MUST NOT be in a scene or memory before it is needed. Load it when it opens. |
| `PERF-02` | A feature MUST release what it loaded when it closes. |
| `PERF-03` | Code MUST NOT run every frame unless the value changes every frame. Prefer events. |

## Allocations

Treat these as forbidden in all client code, not only hot paths, so that hot paths never need auditing:

- No lambdas or anonymous methods, except in tests. A named method can also be unsubscribed.
- No LINQ.
- `for` loops on `List<T>`. `foreach` is fine on arrays, and on dictionaries outside hot paths.

Also:

- Reuse collections with `.Clear()` in methods called often. Return empty collections, not `null`.
- Use `StringBuilder` for string building in loops.
- Pool objects created often.
- Cache `WaitForSeconds` and similar yield instructions.
- Give DOTween and other callbacks a named method. Store parameters in fields.
- Use `MaterialPropertyBlock` for per-instance material changes.
