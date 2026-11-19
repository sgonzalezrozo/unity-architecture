# Pull, nunca push

> [!RULE] ARCH-04
> Si A conoce a B, **A** lee de B y hace todo el trabajo. B nunca prepara, formatea ni entrega datos para A. Los eventos **no tienen parámetros**: avisan, y el que escucha lee el Model.

> [!DONT] Push
> ```csharp
> public event Action<int> OnScoreChanged;
> OnScoreChanged?.Invoke(score);
> ```

> [!DO] Pull
> ```csharp
> public event Action OnScoreChanged;
> // La View: scoreText.text = scoreModel.Score.ToString();
> ```

> [!NOTE]
> El analyzer `UA0004` falla el build si un evento tiene parámetros. Única excepción aceptada: el `Data` de un Slot Model de lista (`LIST-02`).
