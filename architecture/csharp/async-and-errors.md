# Async, errors and logging

## Async

- `async Task` always. The only `async void` in the project is `Forget` itself.
- Never `.Result` or `.Wait()`.
- Accept a `CancellationToken` in anything that can outlive its screen.
- Start from sync code with `.Forget("Context")`, never `_ = Task`:

```csharp
public static async void Forget(this Task task, string context)
{
    try
    {
        await task;
    }
    catch (OperationCanceledException)
    {
    }
    catch (Exception exception)
    {
        Debug.LogError($"[{context}] Background task failed: {exception}");
    }
}
```

- Use `ConfigureAwait(false)` only in code that touches no Unity API afterwards, and never in a MonoBehaviour.
- Guard concurrent runs with a state or flag, and reset it in `finally`.

## Errors

- **Throw** for what should not happen: broken preconditions, missing resources.
- **Return `Result<T>`** or a state for what can happen: network failure, invalid input, not enough currency.
- Catch specific exceptions. Never swallow one without logging it.
- Validate public API parameters. Do not null-check injected or cached references.
- In a Model, `MODEL-03` decides which condition is ignored and which throws.
- A missing optional serialized component is a `LogWarning`, and the code degrades gracefully.

## Logging

- Prefix with context: `[TrophyRoom]`. Include IDs and reasons.
- `Log` for flow, `LogWarning` for recoverable issues, `LogError` for failures.
- Exceptions: `$"[Context] {ex.Message}\n{ex.StackTrace}"`.
- Remove verbose debug logs before committing.

## Resources

Clean up in `OnDestroy`, or `OnDisable` for subscriptions: cancel and dispose `CancellationTokenSource`, release Addressables, stop coroutines.

Pure C# classes that hold subscriptions implement `IDisposable`.

With `addressables`, load large textures and audio through it, and always release the handle.
