# Fast IoC rules

| ID | Rule |
|---|---|
| `DI-01` | No `[Inject]` (`UA0007`) |
| `DI-02` | MonoBehaviour fields are `private` or `internal`; `internal` ones have no attribute (`UA0008`) |
| `DI-03` | No `Initialize(...)` with parameters on a MonoBehaviour (`UA0006`) |
| `DI-04` | A MonoBehaviour has no constructor |
| `DI-05` | Don't resolve from `ContextRuntime` as a service locator |
| `DI-06` | Don't null-check injected fields |
| `DI-07` | Don't bind primitives: put configuration in a typed class |
| `DI-08` | Each type is bound once per scope |

> [!NOTE]
> Fast IoC matches **by type**: the field name doesn't matter. That's why `internal` is the only sign that a field is injected.

> [!WARNING]
> Don't call `Instantiate` for a prefab with injected fields: use `IPrefabInstantiator`, or the fields stay empty.
