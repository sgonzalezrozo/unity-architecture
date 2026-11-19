# Llamadas async y red

> [!RULE] BE-06
> Solo los **Controllers** lanzan comandos async, con `.Forget("Contexto")` y un `CancellationToken` propio.

> [!RULE] BE-07
> El Controller cancela y libera su token en `OnDestroy`.

<!-- if: com.sgonzalezrozo.screen-system -->
```csharp
public class MainRoomLoadController : MonoBehaviour, IScreenShow
{
    internal TrophyRoomModule trophyRoomModule;

    private readonly CancellationTokenSource destroyCancellation = new();

    public void OnScreenShown()
    {
        trophyRoomModule.LoadTrophiesAsync(destroyCancellation.Token).Forget("TrophyRoom.LoadTrophies");
    }

    private void OnDestroy()
    {
        destroyCancellation.Cancel();
        destroyCancellation.Dispose();
    }
}
```
<!-- else -->
```csharp
public class MainRoomLoadController : MonoBehaviour
{
    internal TrophyRoomModule trophyRoomModule;

    private readonly CancellationTokenSource destroyCancellation = new();

    private void OnEnable()
    {
        trophyRoomModule.LoadTrophiesAsync(destroyCancellation.Token).Forget("TrophyRoom.LoadTrophies");
    }

    private void OnDestroy()
    {
        destroyCancellation.Cancel();
        destroyCancellation.Dispose();
    }
}
```
<!-- endif -->

<!-- if: com.sgonzalezrozo.screen-system -->
- La carga arranca en `OnScreenShown()`, **nunca** en `Start()`: una pantalla puede mostrarse más de una vez.
<!-- else -->
- La carga arranca en `OnEnable` de la raíz de la pantalla, **nunca** en `Start()`: una pantalla puede mostrarse más de una vez.
<!-- endif -->
- Timeout de **15 s** por intento, máximo **3 intentos**, backoff exponencial con jitter en un helper compartido.
- Muestra que algo pasa en operaciones largas y permite cancelarlas.

> [!WARNING] Sin definir
> Tiempo real (WebSocket, polling), caché, batching y rate limiting no tienen patrón acordado: **pregunta**.
