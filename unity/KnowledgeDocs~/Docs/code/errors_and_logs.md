# Errors and logs

| Situation | What to do |
|---|---|
| Shouldn't happen (broken precondition, missing resource) | `throw` |
| Can happen (network, invalid input, not enough coins) | `Result<T>` or a state |
| An optional serialized component is missing | `LogWarning` and degrade gracefully |

- Catch **specific** exceptions. Never swallow one without logging it.
- Validate public API parameters. Don't null-check injected or cached references.

## Logs

- Prefix with context: `[TrophyRoom]`, plus IDs and reasons.
- `Log` for flow, `LogWarning` for recoverable issues, `LogError` for failures.
- Remove debug logs before committing.
