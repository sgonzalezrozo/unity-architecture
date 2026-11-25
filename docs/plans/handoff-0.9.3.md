# Handoff: after 0.9.2

For the next session working on these rules. 0.9.2 made agents read less and made their output checkable; this is where it stands, what the measurements say, and what to try next. The first baseline is [0.9.1-inventory.md](../benchmarks/0.9.1-inventory.md).

## What 0.9.2 has

| Area | What | Where |
|---|---|---|
| Timing | Every prompt ends with one line: time, time to the first file, calls and rule docs before it, reads outside the packs, models, tokens, estimated cost at list prices | `templates/claude/hooks/log-timing.sh`, `templates/scripts/timing-report.sh`, `model-prices.json` |
| Task packs | One file per kind of task with the forks resolved, the package docs it relies on and verified symbols; the session start shows the index | `packs.json`, `templates/scripts/ai-packs.sh`, `OPT-07` |
| Project facts | Scenes, installers, `Client.asmdef` references, features, localization (installed / configured / used), the `Forget` helper | `templates/scripts/ai-facts.sh` |
| Fixed plan | `Logs/ai/plan.md` with closed decisions; the first plan of a turn is the approved contract | `PLAN-02`, `planning.md` |
| Data assets | A spec builds the asset; `verify.sh` builds missing ones before compiling | `EDIT-14`, `unity/Editor/AssetSpecs.cs` |
| Feature checker | `CHK-01` to `CHK-17`, run by the Stop hook on the task's test-scope folders, per session | `templates/scripts/check-feature.sh`, `EDITOR_TOOLS.md` |
| Rules found by testing | Mock and items Model (`MODEL-12`, `MODEL-13`), no lazy queries (`MODEL-02`), what never to ask, navigation on the root Model (`SCR-16`), clock row, fixed names, per-feature test assemblies (`ASM-03`), `IMPLEMENTATION.md` (`HAND-07`) | the rule files |
| Example 04 | The multi-source bento store with a popup, built from a real request; it passes the checker | `architecture/examples/04_MULTI_SOURCE_BENTO_STORE.md`, pack `example-store` |

## Measurements

All headless (`claude -p --permission-mode auto`), code only, in MyTools.

| Run | Model | Time | First file | Calls before | Cost | Checker at the end |
|---|---|---|---|---|---|---|
| Inventory, 0.9.1 baseline | Opus 5.5 | 5m 24s | 3m 57s | 22 | $1.90 | (no checker) |
| Inventory, packs (F2) | Opus 5.5 | 3m 46s | 1m 38s | 9 | $1.21 | (no checker) |
| Inventory, F2–F4 | Opus 5.5 | 4m 05s | 1m 50s | 7 | $1.23 | (no checker) |
| Inventory, F5 | Haiku 5.5 | 6m 36s | 1m 36s | 10 | $0.36 | passed by dropping the list (fixed by `CHK-13`) |
| Store, before example 04 | Haiku 5.5 | 12m 56s | 5m 47s | 15 | $1.23 | failing |
| Store, with example 04 | Haiku 5.5 | 10m 09s | 4m 42s | 23 | $1.13 | passes; stopped to ask for the popup's screen |
| Store, with example 04 | Opus 5.5 | 8m 08s | 3m 07s | 20 | $2.83 | passed, but used a string for the screen and copied `Forget` (both fixed, `CHK-16`, `CHK-17`) |

The decision so far: tune for Haiku. Opus is a little faster, but costs about 2.5 times as much for the same result, and the checker is what makes either model correct.

The scripts that ran these samples are not in the repository yet (see F8 below).

## Possible improvements, by impact

1. **Haiku still reads package source** after the packs (4 to 6 calls per run: `IScreenParameter`, `TaskExtensions`, `BaseClickController`, `IInstantiator`, `ISlot`). Options: document those signatures in each package's `Documentation~` and add them to the packs' verified symbols, as was done for UI Scroller's **Sources and slots**; or a `PreToolUse` hook that, once a pack was read, answers a read of `Packages/*/Runtime/*.cs` with "this is in the pack, see its section X" instead of running it.
2. **Calls before the first file are still 15 to 23** (target 5). Most are separate reads of the packs and facts. Ideas: tell the agent to read all its packs in one parallel call; print the facts and the index already at session start (done) and drop the agent's first `ls`/`cat` habit with an explicit first step in AGENTS.md.
3. **F8, the evaluation harness:** turn the sample scripts into `tools/eval/run.sh` and `report.sh` (snapshot, run, archive timing, plan, files and checker output, restore). The working versions are `run-sample-*.sh` from this session; the restore must work with the Editor open (add the feature, then remove it and restore the few files outside it, as the last version does).
4. **`CHK-02`, changes outside the feature**, is still unchecked. With the turn marker it can be done: files changed after the turn began, outside the feature folder and not named in `outside-feature`.
5. **Scope detection** reads only fixed phrases in English and Spanish (`task_scope` in `verify-on-stop.sh`). Make the scope question's labels exact in `TASK-01` and match on them, or record the answer in the session state when the agent asks.
6. **A screen that doesn't exist yet** is now an open question in the plan and `CHK-16` refuses a string, but the agent only finds out at compile time. The project facts could list the existing `ScreenIds` constants, so the plan knows before writing.
7. **UI Scroller:** one bento layout per list. Banners full width in only one section needs a layout per section (a package feature). Example 04 works around it with a full-width first tile in every section.
8. **Example 03** still injects its Model where a common parent exists (`ROOT-06`); align it with example 04.
9. **Example 04 isn't compiled in Unity:** `ScreenIds.StorePromotionPopup` needs the screen. A fixture project (or the rules' Unity package tests) could compile the examples.
10. **Two sessions in one project** share `Logs/verify/test-scope` and `Logs/ai/plan.md`; the hook copies them per session only when written during the turn, so a concurrent writer can still leak in. Rare in practice.
11. **Effort:** compare Haiku at low, medium and high on the Store request (cost per completed task, retries, checker result).
12. **Housekeeping:** refresh `model-prices.json` when prices change; projects need `install.sh --update` for the Copilot, Cursor and Rider copies; `ScreenSystem.Tests.PrefabHandleCacheTests.BundlesAreRetainedOnceForEachAddressThatLoads` failed once in a full run and passes alone (order-dependent, Screen System repository).

## How to start

- Read this file, `CHANGELOG.md` (0.9.2) and `docs/benchmarks/0.9.1-inventory.md`.
- Run `bash tools/lint-rules.sh` and the script tests (`tools/test-*.sh`) before and after any change.
- Measure with a sample before and after a change, code only, on the Store request in example 04, with Haiku.
