# Violation patterns

| Violation | Correct form | Rule |
|---|---|---|
| `event Action<int> OnScoreChanged` | `event Action OnScoreChanged`, then read `scoreModel.Score` | `ARCH-04` |
| `public Action OnChanged { get; set; }` | `public event Action OnChanged;` | `MODEL-05` |
| `model.OnSelected?.Invoke()` in a Controller | `model.SelectItem(itemId)` | `ARCH-04` |
| `view.Initialize(model)` | `GetComponentInParent`, or an injected field for row 2 | `UA0006` |
| An inner View subscribes to `model.OnChanged` | Only the root View subscribes, and tells its inner Views what to show | `VIEW-03` |
| A View serializes the View of a nested prefab | The nested prefab's root View reads its own Model | `VIEW-03` |
| A View with 8 serialized fields | Group them into inner Views, 5 fields at most per View | `VIEW-07` |
| `view.RefreshButton.onClick += ...` | A Controller implementing `IPointerClickHandler` | `ARCH-05` |
| `if (model.State == Active) model.Buy();` in a Controller | `model.Buy()` validates internally | `CTRL-03` |
| View calls `module.LoadAsync()` | A Controller calls it and the View reads the result | `VIEW-02` |
| `internal DataService dataService` in a View | The View reads a Model | `ARCH-01` |
