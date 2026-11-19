# Con package o sin él

| Necesidad | Con package | Sin package |
|---|---|---|
| Model sin padre común o persistente | Fast IoC: C# puro, campo `internal` | Singleton C# puro |
| Click | UI Foundations: `BaseClickController` | `MonoBehaviour, IPointerClickHandler` |
| Aspectos excluyentes | `ViewStateMachine.SetState(name)` | Una raíz `GameObject` por estado |
| Lista dinámica | UI Scroller: `Scroller<T>` | `ScrollRect` con celdas reutilizadas |
| Pantalla mostrada / oculta | Screen System: `OnScreenShown()` / `OnScreenHidden()` | `OnEnable` / `OnDisable` del Controller |
| Abrir pantalla / volver | `ScreenManager.Instance.GoTo(...)` / `GoBack()` | Un Model de navegación |
| Popup | Pantalla tipo `Modal` | Prefab popup mostrado por una View |
| Parte compartida (barra superior) | Un layer | Un prefab anidado en cada pantalla |
| Asset grande | Addressables (libera el handle) | Referencia directa o `Resources` |
