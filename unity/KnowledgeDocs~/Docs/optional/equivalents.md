# With or without a package

| Need | With the package | Without it |
|---|---|---|
| Model with no common parent, or persistent | Fast IoC: pure C#, `internal` field | Pure C# singleton |
| Click | UI Foundations: `BaseClickController` | `MonoBehaviour, IPointerClickHandler` |
| Mutually exclusive looks | `ViewStateMachine.SetState(name)` | One `GameObject` root per state |
| Dynamic list | UI Scroller: `Scroller<T>` | `ScrollRect` with reused cells |
| Screen shown / hidden | Screen System: `OnScreenShown()` / `OnScreenHidden()` | Controller `OnEnable` / `OnDisable` |
| Open a screen / go back | `ScreenManager.Instance.GoTo(...)` / `GoBack()` | A navigation Model |
| Popup | A `Modal` screen | A popup prefab shown by a View |
| Shared part (top bar) | A layer | A nested prefab in each screen |
| Large asset | Addressables (release the handle) | Direct reference or `Resources` |
