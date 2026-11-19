# Determinismo y tests

> [!RULE] ARCH-07
> Lo que puede ser determinista, **lo es**. Mejor una herramienta (compilador, analyzer, test, script) que el criterio de alguien.

> [!RULE] ARCH-08
> Lo que se puede testear **tiene test**. La lógica que no se puede testear donde está, se mueve a donde sí.

## En runtime

- Mismo estado + mismo input = mismo resultado (`DET-05`).
- Los Models **no leen** el tiempo, el azar ni estado externo directamente: lo reciben por una interfaz, como `IClock` (`DET-06`).
- Nada depende de un orden indefinido: el orden de un `Dictionary`, o el `Awake` de objetos no relacionados (`DET-07`).

```csharp
public interface IClock
{
    long UtcNowUnixSeconds { get; }
}
```
