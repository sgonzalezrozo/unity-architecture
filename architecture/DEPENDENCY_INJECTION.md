# Dependency injection

**Load when:** getting a reference, or writing bindings or installers.

Most Views and Controllers don't use injection: they find a Model on a common parent, even outside their scope (`SCOPE-05`). Injection is for rows 2 and 3 of [Where a Model lives](mvc/where-a-model-lives.md). A service locator MUST NOT be used in any case.

> **Fork `container`** · how injected Models, installers and bindings work. Open only the branch the [profile](OPTIONAL_PACKAGES.md#the-profile) names:
> - `fast-ioc`: [Fast IoC: injected Models](branches/fast-ioc/models.md), then [Fast IoC installers](branches/fast-ioc/installers.md) for bindings
> - `other-container`: [Another container: injected Models](branches/other-container/models.md)
> - `no-container`: [No container: singletons](branches/no-container/models.md)

## Reference acquisition

| Class | How |
|---|---|
| View or Controller, Model on a common parent | `GetComponentInParent<TModel>()`, cached once |
| View or Controller, no common parent or persistent Model | Injected, or the singleton without a container: see the branch |
| Inside a list slot | `GetComponentInParent<TSlotModel>()`, cached once |
| MonoBehaviour Model, Model outside MVC, configuration asset | Injected, or the singleton without a container: see the branch |
| Pure C# class | Constructor |

```csharp
public class TrophyRoomModule
{
    private readonly ITrophyRoomConnector connector;

    public TrophyRoomModule(ITrophyRoomConnector connector)
    {
        this.connector = connector;
    }
}
```

## Rules

These apply with any container. The branch adds its own.

| ID | Rule |
|---|---|
| `DI-02` | MonoBehaviour fields MUST be `private` or `internal` (`UA0008`). With Fast IoC, `internal` fields MUST have no attribute. |
| `DI-03` | `Initialize(...)` with parameters MUST NOT exist on a MonoBehaviour (`UA0006`). |
| `DI-04` | A MonoBehaviour MUST NOT have a constructor. |
| `DI-06` | Injected fields MUST NOT be null-checked. A failed injection should fail loudly. |
| `DI-07` | Primitives MUST NOT be bound. Put configuration in a typed class and bind that. |
| `DI-08` | A type MUST be bound once per scope. |
