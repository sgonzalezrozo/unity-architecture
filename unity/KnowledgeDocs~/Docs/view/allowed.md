# What a View can and can't do

| <color=#3FB950>Can</color> | <color=#F85149>Can't</color> |
|---|---|
| Read Model queries | Call a command, sync or async (`VIEW-02`) |
| Change activeness, color, size, text, alpha and sprites (`VIEW-05`) | Implement `IPointer*` or other input (`VIEW-04`, `UA0002`) |
| Format values for display | Know services or Connectors (`ARCH-01`) |
| Start a tween when it reacts to an event | Use `Animator` or `Animation` in UI (`PREFAB-05`) |

> [!DONT]
> A View that calls `module.LoadAsync()`.

> [!DO]
> A Controller calls the command, and the View reads the result.
