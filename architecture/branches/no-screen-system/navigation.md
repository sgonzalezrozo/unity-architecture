# Navigation without Screen System

Branch `no-screen-system` of the `navigation` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `navigation: no-screen-system`.

| Need | Form |
|---|---|
| Screen shown | Controller `OnEnable`, on the screen root |
| Screen hidden | Controller `OnDisable`, on the screen root |
| Open a screen | [Navigation Model](#navigation-model) |
| Go back | [Navigation Model](#navigation-model) |
| Popup or confirmation | A popup prefab in the screen folder, shown by a View |
| Blocking message (connection lost) | A popup prefab over everything |
| Part shared by several screens (top bar, background, navigation bar) | A nested prefab in each screen |
| Animate a screen | From the Controller's `OnEnable` / `OnDisable` |

A popup is a prefab in the screen folder that uses it, and its open state lives in a Model like any other state.

## Navigation Model

A Model owns the current screen, and a View renders it. A Controller starts a load from `OnEnable`, because the screen root activates each time it is shown.

If navigation must persist across scenes, it is row 2 in [Where a Model lives](../../mvc/where-a-model-lives.md).

```csharp
public enum GameScreen { Home, Inventory }

public class NavigationModel : MonoBehaviour
{
    public event Action OnCurrentScreenChanged;

    private GameScreen currentScreen = GameScreen.Home;

    public GameScreen CurrentScreen => currentScreen;

    public void OpenScreen(GameScreen screen)
    {
        if (currentScreen == screen)
            return;

        currentScreen = screen;
        OnCurrentScreenChanged?.Invoke();
    }
}

public class ScreenStackView : MonoBehaviour
{
    [SerializeField] private GameObject homeRoot;
    [SerializeField] private GameObject inventoryRoot;

    private NavigationModel navigationModel;

    private void Awake()
    {
        navigationModel = GetComponentInParent<NavigationModel>();
    }

    private void OnEnable()
    {
        navigationModel.OnCurrentScreenChanged += RenderCurrentScreen;
        RenderCurrentScreen();
    }

    private void OnDisable()
    {
        navigationModel.OnCurrentScreenChanged -= RenderCurrentScreen;
    }

    private void RenderCurrentScreen()
    {
        homeRoot.SetActive(navigationModel.CurrentScreen == GameScreen.Home);
        inventoryRoot.SetActive(navigationModel.CurrentScreen == GameScreen.Inventory);
    }
}
```
