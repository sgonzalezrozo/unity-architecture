# Determinism and tests

> [!RULE] ARCH-07
> Anything that can be deterministic **is**. A tool (compiler, analyzer, test, script) beats someone's judgment.

> [!RULE] ARCH-08
> Anything that can be unit tested **has tests**. Logic that can't be tested where it is moves to where it can.

## At runtime

- Same state plus same input gives the same result (`DET-05`).
- Models **don't read** time, randomness or external state directly: they receive them through an interface, such as `IClock` (`DET-06`).
- Nothing depends on undefined order: `Dictionary` enumeration, or the `Awake` order of unrelated objects (`DET-07`).

```csharp
public interface IClock
{
    long UtcNowUnixSeconds { get; }
}
```
