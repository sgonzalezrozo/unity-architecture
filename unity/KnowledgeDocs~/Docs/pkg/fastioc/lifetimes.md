# Binding lifetimes

| Binding | Use |
|---|---|
| `Bind<T>().AsSingle()` | One shared instance, created on first use. **The default** |
| `Bind<IT>().To<T>().AsSingle()` | Interface to implementation |
| `Bind<T>().AsCached()` | One instance, cleared when the scene unloads |
| `Bind<T>().AsTransient()` | A new instance per injection (also when none is given) |
| `Bind<T>().FromInstance(x)` | An existing instance, as a singleton |
| `Bind<T>().FromInstance("Path").AsSingle()` | A prefab or ScriptableObject by name or path |

- What lives and dies with the feature goes in the feature's scene.
- What several features use goes in a shared scope with a higher priority.
- A scene `AsSingle()` stays cached after the scene unloads: use `AsCached()` to tie it to the scene.

> [!NOTE]
> Fast IoC has no factory delegates: bind a factory class and inject it.
