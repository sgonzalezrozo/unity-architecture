# Tipos de binding

| Binding | Uso |
|---|---|
| `Bind<T>().AsSingle()` | Una instancia compartida, creada al primer uso. **Por defecto** |
| `Bind<IT>().To<T>().AsSingle()` | Interfaz → implementación |
| `Bind<T>().AsCached()` | Una instancia que se limpia al descargar la escena |
| `Bind<T>().AsTransient()` | Una instancia nueva por inyección (también si no pones nada) |
| `Bind<T>().FromInstance(x)` | Una instancia existente, como singleton |
| `Bind<T>().FromInstance("Path").AsSingle()` | Un prefab o ScriptableObject por nombre o ruta |

- Lo que vive y muere con la feature, en la escena de la feature.
- Lo que usan varias features, en un scope compartido con más prioridad.
- Un `AsSingle()` de escena sigue cacheado tras descargarla: usa `AsCached()` para atarlo a la escena.

> [!NOTE]
> Fast IoC no tiene factory delegates: bindea una clase factory e inyéctala.
