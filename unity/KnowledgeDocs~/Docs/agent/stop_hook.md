# The Stop hook

A Claude Code hook won't let the agent finish with a broken build. It runs only when `Assets`, `Packages` or `ProjectSettings` changed, and gives up after **3 attempts** in a row.

| Message | What the agent does |
|---|---|
| "Unity hasn't compiled the latest script changes" | `refresh_unity`, reads the Console and stops again |
| "A prefab under Assets/Client changed..." | Runs `ClientPrefabsTests` |
| "The full EditMode suite is due" | Runs every EditMode test (at most every 2 h) |
| A prefab error with a rule ID | Rebuilds or fixes the prefab |
| A `CS...` or `UA00..` error | Fixes the code |
| "Verify passed" | Nothing: it can finish |

| Editor | The hook runs |
|---|---|
| Closed | `scripts/verify.sh` (compiles in batch; tests when due) |
| Open | `scripts/verify-editor.sh` (reads `Logs/verify/` written by the Editor) |

Exit codes: `0` passed, `1` failed, `2` couldn't run. With the Editor open and no Unity MCP, an out-of-date compile or due tests are reported as "couldn't check".
