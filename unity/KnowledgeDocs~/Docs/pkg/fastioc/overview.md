# Fast IoC: overview

Dependency injection with **generated code** and no runtime reflection. Missing bindings and cycles are caught **before Play**.

- **Feature-owned installers:** an installer next to the feature's code, no central list.
- **Errors before Play:** cycles, missing bindings and invalid assets fail generation.
- **No reflection:** registries and injectors are generated at edit time; scenes are injected from a baked manifest.
- Singletons, scene-scoped and transient lifetimes, assets, `Lazy<T>`, `Func<T>`, prefab instantiation with data, and async initialization.

> [!NOTE]
> It adds the `FAST_IoC` define to every build target when it loads: commit that Player Settings change.

## How it's used here

| Class | Receives dependencies through |
|---|---|
| MonoBehaviour | An `internal` field with no attribute |
| Pure C# class | Its public constructor |
