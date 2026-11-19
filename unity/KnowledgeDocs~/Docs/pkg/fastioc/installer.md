# A feature's installer

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

| Priority | Use |
|---|---|
| 400 | Configuration |
| 300 | Shared services |
| 200 | Features |
| 100 and below | Feature details |

> [!RULE] What to bind
> Models, Modules and Connectors. **Never** Views or Controllers: they're components on prefabs.
