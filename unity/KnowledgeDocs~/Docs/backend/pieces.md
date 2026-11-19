# The backend pieces

```flow
Backend:teal -> Connector:teal -> Module -> Event:yellow -> View reads the Module
Controller -> Module command
```

| Piece | Type | Job |
|---|---|---|
| `{Feature}Data` | Data class | The backend response as received |
| `I{Feature}Connector` | Interface | The calls the feature can make; lets tests fake the backend |
| `{Feature}Connector` | Implementation | Makes the calls, returns data, **holds no state** |
| `{Feature}Module` | Pure C# Model | Wraps the Connector and holds the feature's data |

## What goes where

| State | Lives in |
|---|---|
| Backend data, load state, selection shared between screens | **Module** (one per feature) |
| State of one screen only (sort order, an edit in progress) | That screen's Model |

**See also:** [Backend data rules](doc:backend.rules) · [Async and network](doc:backend.async_and_network) · [Trophy Room example](doc:examples.trophy_room)
