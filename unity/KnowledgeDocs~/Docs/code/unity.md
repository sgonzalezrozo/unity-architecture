# Unity good practices

- **Never rename a serialized field** in use without `[FormerlySerializedAs("oldName")]`: the Inspector data is lost.
- Cache components in `Awake`. No `GetComponent` in `Update`.
- A GameObject doesn't call `SetActive` on itself: its parent controls visibility.
- Avoid `OnValidate` and decorative `[Header]` attributes.
- Serializable data classes: `[Serializable]` with public fields (Unity doesn't serialize auto-properties).
- Check your Unity version's C# level before using newer syntax.

## Cleanup

Clean up in `OnDestroy` (or `OnDisable` for subscriptions): cancel and dispose `CancellationTokenSource`, release Addressables, stop coroutines. Pure C# classes that hold subscriptions implement `IDisposable`.
