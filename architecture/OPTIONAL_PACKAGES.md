# Optional packages

**Load when:** generating code that depends on a package.

Packages change the implementation. The [architecture](../AGENTS.md#architecture-invariants), the [MVC layer rules](MVC.md) and the [C# standards](CSHARP_STANDARDS.md) stay mandatory in every configuration.

## Capability detection

Run this once per task. Read `Packages/manifest.json`, and set each capability from `dependencies`:

| Capability | `true` when `dependencies` contains |
|---|---|
| `fastIoC` | `com.sgonzalezrozo.fast-ioc` |
| `uiScroller` | `com.sgonzalezrozo.ui-scroller` |
| `screenSystem` | `com.sgonzalezrozo.screen-system` |
| `uiFoundations` | `com.sgonzalezrozo.ui-foundations` |
| `addressables` | `com.unity.addressables` |

A capability that's `true` and used also means its assemblies in `Client.asmdef` (`ASM-02`, [the table](FEATURE_STRUCTURE.md#assembly-definitions)).

Also set `otherContainer = true` if the project uses another dependency injection container, such as Zenject or VContainer. Check the manifest and the existing code.

| ID | Rule |
|---|---|
| `OPT-01` | Nothing MUST use a package or tool whose capability is `false`: code, a prefab or asset, a menu item, a wizard or a code-tool call. A rule that names one applies only when its capability is `true`. Check the capability before the step; when it's `false`, use the Unity form from the [mapping](#mapping), or leave the step out and report it. |
| `OPT-02` | If a capability is `true`, new code SHOULD use that package. |
| `OPT-03` | An agent MUST NOT add a package without approval. See [When to ask](AGENT_WORKFLOW.md#when-to-ask). |
| `OPT-04` | Match the code around the change. Don't mix both forms in one feature. `OPT-02` wins: when a capability is `true`, new code uses the package even if older code around it doesn't. |
| `OPT-05` | No configuration may break an `ARCH` rule or the C# standards. |

## Mapping

| Need | Package form | Unity form |
|---|---|---|
| Model with no common parent, or that persists | `fastIoC`: pure C#, injected `internal` field. See [Where a Model lives](MVC.md#where-a-model-lives) | Pure C# singleton (`ROOT-07`) |
| Configuration asset for a Model | `fastIoC`: `Bind<T>().FromInstance("Path").AsSingle()`, injected `internal` field | Load it by address or path (`MODEL-10`) |
| Click input | `uiFoundations`: subclass of `BaseClickController` | `MonoBehaviour, IPointerClickHandler` |
| Raycast target | `uiFoundations`: `BaseClickController`, a transparent `Graphic` | Transparent `Image` on the input GameObject |
| Disable clicks | `uiFoundations`: `Interactable = false` | Disable the input GameObject, or place it in an inactive state |
| Mutually exclusive looks | `uiFoundations`: `ViewStateMachine.SetState(stateName)` | View with one `GameObject` root per state |
| Dynamic list | `uiScroller`: `Scroller<T>` (`SectionedScroller<TItem, THeader>` for sections) | [`ScrollRect` with reused cells](#list-without-ui-scroller) |
| Screen shown | `screenSystem`: `IScreenShow.OnScreenShown()`, on any component of the screen or of one of its layers (`SCR-05`) | Controller `OnEnable`, on the screen root |
| Screen hidden | `screenSystem`: `IScreenHide.OnScreenHidden()` (`SCR-05`) | Controller `OnDisable`, on the screen root |
| Open a screen | `screenSystem`: `await ScreenManager.Instance.GoTo(ScreenIds.ShopMain)`, with the generated `ScreenIds` constants (`SCR-07`, `SCR-12`) | [Navigation Model](#navigation-without-screensystem) |
| Go back | `screenSystem`: `await ScreenManager.Instance.GoBack()`; the Escape key does it too | [Navigation Model](#navigation-without-screensystem) |
| Popup or confirmation | `screenSystem`: a screen whose `ScreenDefinition` type is `Modal` (`SCR-09`) | A popup prefab in the screen folder, shown by a View |
| Blocking message (connection lost) | `screenSystem`: a screen whose type is `Alert`, closed with `DismissAlert()` (`SCR-09`) | A popup prefab over everything |
| Part shared by several screens (top bar, background, navigation bar) | `screenSystem`: a layer prefab listed in each screen's `LayerDefinition` (`SCR-04`) | A nested prefab in each screen |
| Animate a screen | `screenSystem`: per layer; the intro starts from `OnScreenShown()`, the outro plays before calling `GoTo` (`SCR-10`) | From the Controller's `OnEnable` / `OnDisable` |
| Load a large asset | `addressables`: release the handle | Direct reference or `Resources` |

If `otherContainer = true`, use that container's injection in place of the `fastIoC` form. Keep every other rule.

The examples in this repository use this profile: `fastIoC`, `uiScroller` and `screenSystem` are `true`, and `uiFoundations` is `false`. Apply this mapping to adapt them.

## List without UI Scroller

The list View only creates cells and shows as many as there are items. It holds GameObjects, never a cell View: each cell is a prefab, so its own scope (`VIEW-03`). Each cell finds the Model and pulls its own item by position, so no data is pushed (`ARCH-04`).

```csharp
public class InventoryListView : MonoBehaviour
{
    [SerializeField] private GameObject inventoryCellPrefab;
    [SerializeField] private RectTransform itemContainer;

    private readonly List<GameObject> itemCells = new();

    private InventoryModel inventoryModel;

    private void Awake()
    {
        inventoryModel = GetComponentInParent<InventoryModel>();
    }

    private void OnEnable()
    {
        inventoryModel.OnVisibleItemsChanged += RenderVisibleItems;
        RenderVisibleItems();
    }

    private void OnDisable()
    {
        inventoryModel.OnVisibleItemsChanged -= RenderVisibleItems;
    }

    private void RenderVisibleItems()
    {
        CreateMissingCells(inventoryModel.ItemCount);

        for (int i = 0; i < itemCells.Count; i++)
            itemCells[i].SetActive(i < inventoryModel.ItemCount);
    }

    private void CreateMissingCells(int requiredCellCount)
    {
        while (itemCells.Count < requiredCellCount)
            itemCells.Add(Instantiate(inventoryCellPrefab, itemContainer));
    }
}

public class InventorySlotView : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI itemNameText;

    private InventoryModel inventoryModel;

    private void Awake()
    {
        inventoryModel = GetComponentInParent<InventoryModel>();
    }

    private void OnEnable()
    {
        inventoryModel.OnVisibleItemsChanged += RenderItem;
        RenderItem();
    }

    private void OnDisable()
    {
        inventoryModel.OnVisibleItemsChanged -= RenderItem;
    }

    private void RenderItem()
    {
        int itemIndex = transform.GetSiblingIndex();

        if (itemIndex < inventoryModel.ItemCount)
            itemNameText.text = inventoryModel.GetItem(itemIndex).displayName;
    }
}
```

This creates one cell per item, so it fits short lists. A long list needs virtualization: ask before adding a package.

## Screen System

Applies when `screenSystem = true`. All UI lives in one persistent `ScreenSystem` object. A screen is a prefab plus the layer prefabs listed in its `LayerDefinition`; layers are found by Resources path or Addressables address, and screens that list the same layer share one instance. The package loads, orders, hides and unloads screens.

| ID | Rule |
|---|---|
| `SCR-01` | Feature code MUST open and close screens only through `ScreenManager`. It MUST NOT `SetActive` a screen, instantiate a screen or layer prefab, or load a scene to show UI. |
| `SCR-02` | Code MUST NOT set `Canvas.sortingOrder` or UI Toolkit sorting on screens or layers. The package sets it from the stack and the `LayerDefinition`. |
| `SCR-03` | Code MUST NOT unload screens, release their Addressables handles, or turn off a screen covered by another. A single scene load unloads every screen except **Persist Over Scenes** ones, the splash and the quit confirmation. |
| `SCR-04` | A part repeated across screens MUST be one layer prefab listed in each screen's `LayerDefinition`, not a copy in each screen. Describe it in the plan; never edit the `LayerDefinition` asset as text (`EDIT-06`). |
| `SCR-05` | Work that runs when a screen shows or hides MUST use `IScreenShow` / `IScreenHide` (or `IScreenLifecycle`). Hidden layers stay active, so `OnEnable` and `OnDisable` don't run. A layer shared with the previous screen stays visible and doesn't get the callbacks again. |
| `SCR-06` | Boot code MUST `await ScreenManager.WhenReadyAsync()` before the first `SetRoot`, and stop if it returns `null`. Don't poll `ScreenManager.Instance`. A call before initialization logs an error and returns `NotReady`. |
| `SCR-07` | Navigation calls return `NavigationResult` (converts to `bool`; `Status` says why it didn't happen). A call made while another is running is ignored and returns `Transitioning` (`IsTransitioning` tells); calls are never queued. `GoTo` for a screen already in the stack returns to it like `PopTo`, removing the screens above. A tab bar is a shared layer whose buttons call `GoTo(tab, NavigationHistory.ClearToRoot)`, so back returns to the root. |
| `SCR-08` | Pass what a navigation is about with `GoTo(screen, value)`; components on the screen's layers receive it with `IScreenParameter<T>`, once, before `OnScreenShown`, and store it themselves. State shared by several screens stays in a Model (`ARCH-04`); see [Modals and navigation](FEATURE_STRUCTURE.md#modals-and-navigation). |
| `SCR-09` | By design, one modal is open at a time: close it before opening another. An alert opens over everything, blocks navigation and the Escape key, and closes only with `DismissAlert()`. For an answer (confirmation, picker), open it with `await screens.GoToForResult<T>(ScreenIds.X)` and the modal calls `CloseWithResult(value)`; check `Returned` before `Value`, since back gives `Dismissed`. |
| `SCR-10` | The package has no screen transition or animation API, and none is added: animations are the layers' job. An intro starts from `OnScreenShown()`. An outro plays first and calls `GoTo` when it completes (a sequence or tween's completion callback), since the screen is hidden at once and `OnScreenHidden()` comes too late to be seen. Don't fade out every layer of the fullscreen screen, or the camera background shows through; keep a background opaque. Hidden layers stay loaded until the scene changes, so restore what the outro changed in `OnScreenHidden()` or before the intro. |
| `SCR-11` | Screen components that need services are injected by the project's container through Tools Core (`fastIoC`: `internal` fields; VContainer: `builder.UseToolsCore()`; Zenject: `ToolsCoreInstaller`). Layers are injected once, before `Awake`, so components MAY rely on their dependencies in `Awake`. Screen System never requires Fast IoC. |
| `SCR-12` | Navigation MUST use the generated `ScreenIds` constants instead of string literals, so typos and renamed screens fail at compile time. |
| `SCR-13` | With `screenSystem`, a person creates a screen with **Assets > Screen System > New Screen** (right-click the feature's folder under `Assets/Client`: the folder is the feature, and its name prefixes the screen IDs), and adds one to an existing feature with **Add Screen to Feature…** in a `ScreenDefinition`'s Inspector; **Edit Prefab** there opens the screen's prefab. With `editorBridge`, the agent calls `ScreenAuthoring.CreateScreen(featureDir, screenName, type)` instead (`EDIT-13`). Both make the same files: `{Feature}/{Screen}/{Screen}.prefab` and `{Feature}/Services/{Screen}.asset`, loadable and registered, so `ScreenIds` gets the new constant. `AddLayer`, `RemoveLayer` and `GetLayers` change a screen's layers. Never write their `.prefab` or `.asset` files as text (`EDIT-06`). |
| `SCR-14` | The splash and the quit confirmation are the screens the `ScreenManager` names (`SplashMain`, `QuitConfirmation` by default). Create them with **Tools > Screen System > Setup** (or **Create Special Screens** in the `ScreenManager` Inspector) or, with editor tools, `SpecialScreensCreator.Create()`; redesign their contents but keep their names. The quit modal's buttons call `QuitConfirmationLayer.Quit` and `Cancel`; feature code MUST NOT call `Application.Quit`. On WebGL and iOS, leave out the quit confirmation and turn off **Quit On Back At Root**. |
| `SCR-15` | With `screenSystem`, a layer is created in its feature's folder. **Assets > Screen System > New Layer** makes one with a full-screen `Background` Image, dimmed and with Raycast Target on: keep it only for a layer that needs a backdrop, and turn its raycast off, since only a screen's `Background` blocks touches (`PREFAB-14`); delete it otherwise. With `editorBridge`, the agent calls `ScreenAuthoring.CreateLayer(folder, layerName)`, which adds no `Background`, builds the content with the recipes (`prefabTools`; without it, writes the handoff), and lists the layer with `AddLayer` (`SCR-04`). |

The package ships its own agent rules in `Documentation~/agent-rules.md` (under `Packages/com.sgonzalezrozo.screen-system/` once installed). Read them before using an API not listed here.

## Navigation without ScreenSystem

A Model owns the current screen, and a View renders it. A Controller starts a load from `OnEnable`, because the screen root activates each time it is shown.

If navigation must persist across scenes, it is row 2 in [Where a Model lives](MVC.md#where-a-model-lives).

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

## Click Controller

These forms differ only in the base class. The `internal` field shows an injected Model. Otherwise, use `GetComponentInParent`: see [Where a Model lives](MVC.md#where-a-model-lives).

Plain Unity:

```csharp
public class LoseLifeController : MonoBehaviour, IPointerClickHandler
{
    internal LivesModel livesModel;

    public void OnPointerClick(PointerEventData eventData)
    {
        livesModel.LoseLife();
    }
}
```

UI Foundations:

```csharp
public class LoseLifeController : BaseClickController
{
    internal LivesModel livesModel;

    protected override void OnClick()
    {
        livesModel.LoseLife();
    }
}
```

`BaseClickController` derives from `Graphic`, so a Controller that cleans up in `OnDestroy` MUST use `protected override void OnDestroy()` and call `base.OnDestroy()`.

## Visual state View

These forms differ only in how the state is rendered. The `internal` field shows an injected Model. Otherwise, use `GetComponentInParent`: see [Where a Model lives](MVC.md#where-a-model-lives).

Plain Unity:

```csharp
public class PurchaseStateView : MonoBehaviour
{
    [SerializeField] private GameObject availableRoot;
    [SerializeField] private GameObject lockedRoot;
    [SerializeField] private GameObject ownedRoot;

    internal StoreModel storeModel;

    private void OnEnable()
    {
        storeModel.OnSelectedItemStateChanged += RenderPurchaseState;
        RenderPurchaseState();
    }

    private void OnDisable()
    {
        storeModel.OnSelectedItemStateChanged -= RenderPurchaseState;
    }

    private void RenderPurchaseState()
    {
        PurchaseState state = storeModel.SelectedItemState;

        availableRoot.SetActive(state == PurchaseState.Available);
        lockedRoot.SetActive(state == PurchaseState.Locked);
        ownedRoot.SetActive(state == PurchaseState.Owned);
    }
}
```

UI Foundations:

```csharp
public class PurchaseStateView : MonoBehaviour
{
    [SerializeField] private ViewStateMachine purchaseStateMachine;

    internal StoreModel storeModel;

    private void OnEnable()
    {
        storeModel.OnSelectedItemStateChanged += RenderPurchaseState;
        RenderPurchaseState();
    }

    private void OnDisable()
    {
        storeModel.OnSelectedItemStateChanged -= RenderPurchaseState;
    }

    private void RenderPurchaseState()
    {
        purchaseStateMachine.SetState(storeModel.SelectedItemState.ToString());
    }
}
```

Each state in `ViewStateMachine` needs a `CanvasGroup`. State names MUST match the enum values exactly.
