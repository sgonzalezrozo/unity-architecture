# Verification order

The cheapest check first; stop at the first failure:

```flow
Compile + analyzers -> EditMode tests -> Generation status -> Play mode check -> Report:green
```

| Step | Editor open (MCP) | Editor closed (`verify.sh`) |
|---|---|---|
| Compile | `refresh_unity` and read the Console | `verify.sh` (exit `1` lists errors) |
| Tests | `run_tests` with a filter | `VERIFY_TEST_FILTER="..." scripts/verify.sh` |
| Generation | Read `GenerationStatus.json` | `verify.sh` reads it |
| Play mode | Automated (`EDIT-07`) | Manual step |

> [!RULE] EDIT-03
> Analyzer errors (`UA0001`...) are compile errors: fix the code. Never suppress them or move code out of the analyzed assembly.

Every report ends like this:

```text
Verified: compile and analyzers (verify.sh), 14 EditMode tests passed
Not verified: Play mode check for TrophyRoom (manual)
```
