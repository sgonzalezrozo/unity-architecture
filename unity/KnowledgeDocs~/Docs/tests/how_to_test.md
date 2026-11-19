# How to write a test

- NUnit, **Arrange-Act-Assert**, one concern per test.
- Name: `{Method}_{Condition}_{Result}`.
- Mock Connectors with **NSubstitute**.

| ID | Rule |
|---|---|
| `TEST-05` | Deterministic: no real time, randomness, network or run order. Fake them through interfaces |
| `TEST-07` | Mock only boundaries you own (Connectors, clocks). Use real Models |
| `TEST-09` | Test code follows the standards; only the lambda ban and size limits are relaxed |

```csharp
[Test]
public void LoseLife_WhenNoLivesLeft_DoesNotFireEvent()
{
    LivesModel livesModel = new GameObject().AddComponent<LivesModel>();
    // Arrange, Act, Assert...
}
```
