# Installer de una feature

Un `BindingRecorder` por feature, en `Services/`.

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

| Prioridad | Uso |
|---|---|
| 400 | Configuración |
| 300 | Servicios compartidos |
| 200 | Features |
| 100 o menos | Detalles de feature |

> [!RULE] Qué se bindea
> Models, Modules y Connectors. **Nunca** Views ni Controllers: son componentes de prefabs.
