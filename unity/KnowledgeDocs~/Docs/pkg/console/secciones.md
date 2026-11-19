# Enhanced Console: secciones

Agrupa logs por sistema y oculta los que no necesitas, por nombre o regex, mirando el mensaje, el stack trace o ambos.

1. Etiqueta los logs con el prefijo de contexto que ya piden las reglas: `[Networking]`, `[Shop]`.
1. **Tools > Enhanced Console > Setup**.
1. Activa **SL** en la barra y elige **Sections...** para ocultar una sección.

```csharp
Debug.Log("[TrophyRoom] Loaded 12 trophies");
Debug.Log("[Shop] Purchase failed: not enough coins", gameObject);  // click selecciona el objeto
```

> [!TIP]
> El prefijo `[Feature]` de los logs (regla de logging) encaja directamente con las secciones.
