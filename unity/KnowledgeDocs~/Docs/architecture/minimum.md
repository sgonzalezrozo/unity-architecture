# Do the minimum

> [!RULE] ARCH-10
> No interface or abstraction without a **second use** or a test need.

> [!RULE] ARCH-11
> Do the minimum that completely finishes the need. A feature not in use **costs nothing** at runtime.

- An empty scene should run far faster than one with every feature ready to use.
- Load each feature when it opens and release it when it closes (`PERF-01`, `PERF-02`).

> [!DONT]
> An `IInventoryService` with a single implementation "just in case".
