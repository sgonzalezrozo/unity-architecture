# Fast IoC installers

Branch `fast-ioc` of the `container` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `container: fast-ioc`.

One `BindingRecorder` per feature, in `Services/`.

```csharp
using FastIoC.API;

namespace Client.TrophyRoom
{
    [MonoInstaller("MainMenu", "TrophyRoom", Priority = 200)]
    public class TrophyRoomInstaller : BindingRecorder
    {
        public override void InstallBindings()
        {
            Bind<ITrophyRoomConnector>().To<TrophyRoomConnector>().AsSingle();
            Bind<IClock>().To<SystemClock>().AsSingle();
            Bind<TrophyRoomModule>().AsSingle();
        }
    }
}
```

`[MonoInstaller(sceneNames, Priority = n)]`: the scenes the installer applies to, and the install order (higher runs first). With no scene names, the installer is global.

| Priority | Use |
|---|---|
| 400 | Configuration |
| 300 | Shared services |
| 200 | Features |
| 100 and below | Feature details |

| ID | Rule |
|---|---|
| `DI-09` | **Assets > FastIoC > New MonoInstaller** writes a global `[MonoInstaller]` with no namespace in the folder you right-click. Run it on the feature's `Services/` folder, name it `{Feature}Installer`, then add the `Client.{Feature}` namespace, the scene names and the `Priority` from the table above. Leave it global only for bindings every scene needs. The agent writes the installer as a C# file in the same form instead (`EDIT-13`). |
| `DI-10` | Fast IoC regenerates its code by itself after every compile. The agent MUST NOT run **Tools > FastIoC > Setup** or **Regenerate Code**: they end in a modal dialog (`EDIT-13`). Setup runs once per project, by a person. When generation must run again and `editorBridge` is `true`, the agent calls `FastIoC.Editor.Generation.GenerationCoordinator.GenerateAllRetryingFailedCode()` through the code tool, then reads `GenerationStatus.json` (`EDIT-04`); without a bridge, it reads the status `verify.sh` reports, or reports the step as not verified. |
| `DI-11` | A feature MUST have `Services/{Feature}Installer.cs` when it binds anything: a configuration asset (`MODEL-12`), a row 2 or 3 Model, a Module or a Connector. A feature that binds nothing MUST NOT have one. Choosing a MonoBehaviour Model on the screen root (row 1) doesn't remove the installer when that Model needs a configuration asset: the asset is still bound there and injected into the Model. |

## What to bind

Bind Models, Modules and Connectors only. Never bind Views or Controllers: they are components on prefabs and receive their fields.

| Binding | Use |
|---|---|
| `Bind<T>().AsSingle()` | One shared instance, created on first use. Use this unless another lifetime is needed |
| `Bind<IT>().To<T>().AsSingle()` | Interface to implementation |
| `Bind<T>().AsCached()` | One cached instance, cleared when a scene unloads |
| `Bind<T>().AsTransient()` | A new instance per injection. This is also the lifetime when none is given |
| `Bind<T>().FromInstance(x)` | An existing instance, shared as a singleton |
| `Bind<T>().FromInstance("Path").AsSingle()` | A prefab or ScriptableObject loaded by name or `Assets/...` path |

FastIoC has no factory delegates. When creation needs custom logic, bind a factory class and inject it.

## Scope

- Use the feature's scene for anything that lives and dies with the feature.
- A dependency needed by several features goes in a shared scope with a higher priority.
- A scene-specific `AsSingle()` instance stays cached after its scene unloads. Use `AsCached()` to tie an instance to a scene.

Verify these symbols before use: `BindingRecorder`, `MonoInstaller`.
