# Tools Core: contenedores

Los packages (Screen System, UI Scroller) piden la inyección a Tools Core, nunca a un contenedor concreto. Funciona **sin contenedor**.

| Contenedor | Qué hacer |
|---|---|
| Fast IoC | Nada: se registra solo |
| VContainer | `builder.UseToolsCore();` en el `LifetimeScope` raíz |
| Zenject | `ZenjectToolsCore.Use(Container);` en un installer del `ProjectContext` |
| Otro | `ToolInjectionServices.MonoBehaviourInjector = new MyContainerInjector();` |

> [!NOTE]
> Un instanciador marcado `IInjectingPrefabInstantiator` evita la doble inyección.
