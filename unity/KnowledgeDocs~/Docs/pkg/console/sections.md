# Enhanced Console: sections

Group logs by system and hide the ones you don't need, by name or regex, matching the message, the stack trace or both.

1. Tag logs with the context prefix the rules already ask for: `[Networking]`, `[Shop]`.
1. **Tools > Enhanced Console > Setup**.
1. Turn on **SL** in the toolbar and choose **Sections...** to hide a section.

```csharp
Debug.Log("[TrophyRoom] Loaded 12 trophies");
Debug.Log("[Shop] Purchase failed: not enough coins", gameObject);  // clicking selects the object
```

> [!TIP]
> The `[Feature]` log prefix (a logging rule) maps straight onto sections.
