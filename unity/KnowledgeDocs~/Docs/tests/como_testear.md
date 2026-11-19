# Cómo se escribe un test

- NUnit, **Arrange-Act-Assert**, una cosa por test.
- Nombre: `{Método}_{Condición}_{Resultado}`.
- Los Connectors se mockean con **NSubstitute**.

| ID | Regla |
|---|---|
| `TEST-05` | Deterministas: sin tiempo real, azar, red ni orden de ejecución. Se falsean con interfaces |
| `TEST-07` | Mockea solo bordes propios (Connectors, relojes). Usa Models reales |
| `TEST-09` | El código de test sigue los estándares; solo se relajan las lambdas y los límites de tamaño |

```csharp
[Test]
public void LoseLife_WhenNoLivesLeft_DoesNotFireEvent()
{
    LivesModel livesModel = new GameObject().AddComponent<LivesModel>();
    // Arrange, Act, Assert...
}
```
