# Eventos de un Model

> [!RULE] MODEL-05
> Siempre `public event Action OnAlgoChanged;`, en pasado.

> [!RULE] MODEL-04
> Los comandos pueden tener parámetros. Los eventos **nunca** (`UA0004`).

> [!RULE] MODEL-06
> Lanza el evento **solo si el estado cambió**.

> [!RULE] MODEL-07
> Un Model puede suscribirse a otro con un **método con nombre**, y se desuscribe en `OnDestroy()` (MonoBehaviour) o en `Dispose()` (C# puro).

| Mal | Bien |
|---|---|
| `event Action<int> OnScoreChanged` | `event Action OnScoreChanged` |
| `public Action OnChanged { get; set; }` | `public event Action OnChanged;` |
| `OnChanged += () => Render();` | `OnChanged += Render;` |
