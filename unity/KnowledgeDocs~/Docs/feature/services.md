# The Services folder

| File | Role |
|---|---|
| `{Feature}Module.cs` | Pure C# Model that wraps the feature's backend |
| `I{Feature}Connector.cs`, `{Feature}Connector.cs` | The calls: interface and implementation |
| `{Feature}Data.cs` | Backend data classes |
<!-- if: com.sgonzalezrozo.fast-ioc -->
| `{Feature}Installer.cs` | Fast IoC bindings |
<!-- endif -->
<!-- if: com.sgonzalezrozo.screen-system -->
| `ScreenDefinition` (`.asset`) | One per screen, from Screen System |
<!-- endif -->

> [!RULE] FEAT-01
> A feature doesn't reference another feature's Views, Controllers or scope internals. It may read a shared or injected Model.

<!-- if: com.sgonzalezrozo.screen-system -->
> [!NOTE]
> A screen that other features open keeps its `ScreenDefinition` in the feature where it was created. It never moves to `Shared/` and is never copied.
<!-- endif -->

**See also:** [The backend pieces](doc:backend.pieces) · [Folders](doc:feature.folders)
