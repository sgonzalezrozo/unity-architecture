# Tools Core: containers

Packages (Screen System, UI Scroller) ask Tools Core for injection, never a specific container. It works **with no container**.

| Container | What to do |
|---|---|
| Fast IoC | Nothing: it registers itself |
| VContainer | `builder.UseToolsCore();` in the root `LifetimeScope` |
| Zenject | `ZenjectToolsCore.Use(Container);` in a `ProjectContext` installer |
| Other | `ToolInjectionServices.MonoBehaviourInjector = new MyContainerInjector();` |

> [!NOTE]
> An instantiator marked `IInjectingPrefabInstantiator` prevents double injection.
