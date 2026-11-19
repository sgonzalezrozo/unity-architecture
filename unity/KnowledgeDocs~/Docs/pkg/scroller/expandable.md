# UI Scroller: expandable slots

The slot implements `IExpandableSlot<T>`. The click **asks the list** to open or close; it never redraws the View directly: the list measures the slot, moves the ones below and remembers the state.

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

- The `IsExpanded` setter fires the same event as `Data`.
- One card open at a time by default (**Allow Multiple Expanded** off).
- Grids and bento don't expand.
