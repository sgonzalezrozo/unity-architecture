# Reglas de Fast IoC

| ID | Regla |
|---|---|
| `DI-01` | Nada de `[Inject]` (`UA0007`) |
| `DI-02` | Campos de MonoBehaviour `private` o `internal`; los `internal` sin atributo (`UA0008`) |
| `DI-03` | Nada de `Initialize(...)` con parámetros en un MonoBehaviour (`UA0006`) |
| `DI-04` | Un MonoBehaviour no tiene constructor |
| `DI-05` | No resuelvas desde `ContextRuntime` como service locator |
| `DI-06` | No compruebes `null` en campos inyectados |
| `DI-07` | No bindees primitivos: mete la config en una clase tipada |
| `DI-08` | Cada tipo se bindea una vez por scope |

> [!NOTE]
> Fast IoC empareja **por tipo**: el nombre del campo no importa. Por eso `internal` es la única señal de que un campo se inyecta.

> [!WARNING]
> No llames `Instantiate` para un prefab con campos inyectados: usa `IPrefabInstantiator`, o los campos quedan vacíos.
