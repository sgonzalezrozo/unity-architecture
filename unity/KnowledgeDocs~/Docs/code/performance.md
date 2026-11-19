# Performance and allocations

| ID | Rule |
|---|---|
| `PERF-01` | A feature isn't in a scene or memory before it's needed |
| `PERF-02` | A feature releases what it loaded when it closes |
| `PERF-03` | Nothing runs every frame unless the value changes every frame. Prefer events |

- Reuse collections with `.Clear()` in methods called often. Return empty collections, not `null`.
- `StringBuilder` for building strings in loops.
- Pool objects created often.
- Cache `WaitForSeconds` and similar.
- Tween callbacks with named methods; parameters in fields.
- `MaterialPropertyBlock` for per-instance material changes.
