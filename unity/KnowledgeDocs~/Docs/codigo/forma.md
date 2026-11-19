# Forma del código

```csharp
public void Process(List<ItemData> items)
{
    if (items.Count == 0)
        return;

    for (int i = 0; i < items.Count; i++)
    {
        if (!items[i].isActive)
            continue;

        Apply(items[i]);
    }
}
```

- Guard clauses y returns tempranos. En bucles, invierte y `continue`.
- Una sola sentencia tras `if`/`for`: línea siguiente, sin llaves.
- Llaves en su propia línea. `=>` de métodos expression-bodied en línea nueva.
- Tipos explícitos, **nunca `var`**. `new()` cuando el tipo está a la izquierda.
- Sin `#region`. Sin números mágicos: nombra timeouts, reintentos y umbrales.
- Sin parámetros `bool` que elijan camino: dos métodos. (`SetVisible(bool)` sí vale.)
- `out`/`ref` solo en métodos `Try*`.
- Ley de Demeter: `player.GetCaptainHealth()`, no `player.Team.Captain.Health`.
