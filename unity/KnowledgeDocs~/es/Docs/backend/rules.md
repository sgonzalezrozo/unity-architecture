# Reglas de datos del backend

| ID | Regla |
|---|---|
| `BE-01` | Los datos del backend **no se mutan**. Para aplicar un cambio, reemplaza la entrada con la respuesta del backend |
| `BE-02` | Timestamps en **segundos Unix**; el tiempo restante se calcula al leer |
| `BE-03` | Cada operación tiene un estado que una View pueda pintar. Una lista vacía es un resultado válido, no un fallo |
| `BE-04` | Evita cargas concurrentes con el propio estado: `return` si ya está cargando |
| `BE-05` | Una operación cancelada **no** es un fallo: restaura el estado anterior y no loguees error |

```csharp
public enum TrophyLoadState { Idle, Loading, Loaded, Failed }

public async Task LoadTrophiesAsync(CancellationToken cancellationToken)
{
    if (loadState == TrophyLoadState.Loading)
        return;
    // ...
}
```

> [!DONT]
> `trophy.isClaimed = true;` tras reclamar. Reemplaza el trofeo con el que devuelve el servidor.
