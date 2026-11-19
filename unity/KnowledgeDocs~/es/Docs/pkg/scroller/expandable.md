# UI Scroller: slots expandibles

El slot implementa `IExpandableSlot<T>`. El click **pide a la lista** abrir o cerrar; nunca redibuja la View directamente: la lista mide el slot, mueve los de abajo y recuerda el estado.

```csharp
public IScroller Owner { get; set; }
public int ItemIndex { get; set; }

public void ToggleExpanded()
{
    if (Owner.IsExpanded(ItemIndex))
        Owner.Collapse(ItemIndex);
    else
        Owner.Expand(ItemIndex);
}
```

- El setter de `IsExpanded` lanza el mismo evento que `Data`.
- Por defecto, una sola tarjeta abierta (**Allow Multiple Expanded** off).
- Grids y bento no se expanden.
