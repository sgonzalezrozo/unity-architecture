# Async

- `async Task` siempre. El único `async void` del proyecto es `Forget`.
- Nunca `.Result` ni `.Wait()`.
- `CancellationToken` en todo lo que pueda sobrevivir a su pantalla.
- Desde código síncrono: `.Forget("Contexto")`, nunca `_ = Task`.
- `ConfigureAwait(false)` solo si después no se toca la API de Unity, y nunca en un MonoBehaviour.
- Protege ejecuciones concurrentes con un estado o flag, y resetéalo en `finally`.

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
