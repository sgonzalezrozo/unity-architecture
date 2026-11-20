# Screen System: authoring

Branch `screen-system` of the `navigation` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `navigation: screen-system`.

How a screen, a layer and the special screens are created. Prefab content follows [Prefabs](../../PREFABS.md); the layer and screen files are never written as text (`EDIT-06`).

| ID | Rule |
|---|---|
| `SCR-13` | With `screenSystem`, a person creates a screen with **Assets > Screen System > New Screen** (right-click the feature's folder under `Assets/Client`: the folder is the feature, and its name prefixes the screen IDs), and adds one to an existing feature with **Add Screen to Feature…** in a `ScreenDefinition`'s Inspector; **Edit Prefab** there opens the screen's prefab. With `editorBridge`, the agent calls `ScreenAuthoring.CreateScreen(featureDir, screenName, type)` instead (`EDIT-13`). Both make the same files: `{Feature}/{Screen}/{Screen}.prefab` and `{Feature}/Services/{Screen}.asset`, loadable and registered, so `ScreenIds` gets the new constant. `AddLayer`, `RemoveLayer` and `GetLayers` change a screen's layers. Never write their `.prefab` or `.asset` files as text (`EDIT-06`). |
| `SCR-14` | The splash and the quit confirmation are the screens the `ScreenManager` names (`SplashMain`, `QuitConfirmation` by default). Create them with **Tools > Screen System > Setup** (or **Create Special Screens** in the `ScreenManager` Inspector) or, with editor tools, `SpecialScreensCreator.Create()`; redesign their contents but keep their names. The quit modal's buttons call `QuitConfirmationLayer.Quit` and `Cancel`; feature code MUST NOT call `Application.Quit`. On WebGL and iOS, leave out the quit confirmation and turn off **Quit On Back At Root**. |
| `SCR-15` | With `screenSystem`, a layer is created in its feature's folder. **Assets > Screen System > New Layer** makes one with a full-screen `Background` Image, dimmed and with Raycast Target on: keep it only for a layer that needs a backdrop, and turn its raycast off, since only a screen's `Background` blocks touches (`PREFAB-14`); delete it otherwise. With `editorBridge`, the agent calls `ScreenAuthoring.CreateLayer(folder, layerName)`, which adds no `Background`, builds the content with the recipes (`prefabTools`; without it, writes the handoff), and lists the layer with `AddLayer` (`SCR-04`). |

Verify these symbols before use: `ScreenAuthoring`, `SpecialScreensCreator`.
