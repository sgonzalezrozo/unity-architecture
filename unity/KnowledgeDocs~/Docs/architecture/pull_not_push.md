# Pull, never push

> [!RULE] ARCH-04
> If A knows B, **A** reads from B and does all the work. B never prepares, formats or delivers data for A. Events have **no parameters**: they signal a change, and the listener reads the Model.

> [!DONT] Push
> ```csharp
> public event Action<int> OnScoreChanged;
> OnScoreChanged?.Invoke(score);
> ```

> [!DO] Pull
> ```csharp
> public event Action OnScoreChanged;
> // The View: scoreText.text = scoreModel.Score.ToString();
> ```

> [!NOTE]
> Analyzer `UA0004` fails the build when an event has parameters. The one accepted exception: a list Slot Model's `Data` (`LIST-02`).
