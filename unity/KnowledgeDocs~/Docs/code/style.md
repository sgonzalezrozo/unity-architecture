# Code style

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

- Guard clauses and early returns. In loops, invert and `continue`.
- One statement after `if`/`for`: next line, no braces.
- Braces on their own line. Expression-bodied `=>` on a new line.
- Explicit types, **never `var`**. `new()` when the type is on the left.
- No `#region`. No magic numbers: name timeouts, retries and thresholds.
- No boolean parameters that pick a code path: write two methods. (`SetVisible(bool)` is fine.)
- `out`/`ref` only in `Try*` methods.
- Law of Demeter: `player.GetCaptainHealth()`, not `player.Team.Captain.Health`.
