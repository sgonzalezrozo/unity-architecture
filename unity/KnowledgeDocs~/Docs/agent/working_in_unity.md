# Rules when touching Unity

> [!RULE] EDIT-06
> `.prefab`, `.unity`, `.asset` or `.meta` YAML is never written as text. Unity's serializer owns those files.

- A moved file moves with its `.meta`.
- Generated code and external packages aren't changed.
- A serialized field is never renamed without `[FormerlySerializedAs]`.
- Stay within the agreed scope: mention other problems, but don't fix them unasked.

> [!RULE] API
> The agent **doesn't invent APIs**. Beyond what's documented, it reads the package source or asks.
