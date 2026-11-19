# Async

- `async Task` always. The only `async void` in the project is `Forget`.
- Never `.Result` or `.Wait()`.
- A `CancellationToken` in anything that can outlive its screen.
- From sync code: `.Forget("Context")`, never `_ = Task`.
- `ConfigureAwait(false)` only when no Unity API is touched afterwards, and never in a MonoBehaviour.
- Guard concurrent runs with a state or flag, and reset it in `finally`.

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
