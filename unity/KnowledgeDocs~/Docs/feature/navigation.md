# Modals and navigation

- Popups are separate prefabs in the folder of the screen that uses them. Their state lives in a Model.
- Pass **what the navigation is about** (which trophy to show) as a parameter when opening.
- State that several screens share stays in a **Model**: screen A sets it, screen B reads it.

> [!RULE] Scenes
> Scene changes go through **one project scene loader**. Never `SceneManager` from feature code.

> [!NOTE]
> Showing a menu isn't the same as leaving a gameplay scene.
