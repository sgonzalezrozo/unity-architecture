#!/usr/bin/env python3
"""Compares the runs saved by run.sh: did the same request give the same plan, the same files, the same checks and
the same rules followed? Usage: python3 tools/eval/report.py <out-dir>"""
import glob, json, os, re, sys

out = sys.argv[1]
runs = sorted(glob.glob(os.path.join(out, "run-*")), key=lambda p: int(p.rsplit("-", 1)[1]))


def load(path):
    try:
        return open(path, encoding="utf-8").read()
    except OSError:
        return ""


def stage_json(run, name):
    try:
        return json.load(open(os.path.join(run, name), encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def plan_files(run):
    return {m.group(1) for m in re.finditer(r"^  ([A-Za-z][\w/.{}-]*/[\w./-]+)", load(os.path.join(run, "plan.md")), re.M)}


def transcript(run):
    rows = []
    for line in load(os.path.join(run, "transcript.jsonl")).splitlines():
        try:
            rows.append(json.loads(line))
        except ValueError:
            pass
    return rows


def metrics(run):
    m = {"run": os.path.basename(run)}
    calls = []
    for r in transcript(run):
        if r.get("type") != "assistant":
            continue
        for c in r.get("message", {}).get("content", []) or []:
            if isinstance(c, dict) and c.get("type") == "tool_use":
                calls.append((c.get("name"), c.get("input", {})))
    first_write = next((i for i, (n, _) in enumerate(calls) if n in ("Write", "Edit")), None)
    m["calls_before_write"] = first_write if first_write is not None else "none"
    m["questions"] = sum(1 for n, _ in calls if n == "AskUserQuestion")
    m["tests_run"] = sum(1 for n, i in calls if n == "mcp__unityMCP__run_tests") + sum(
        1 for n, i in calls if n == "Bash" and "verify" in str(i.get("command", ""))
        and "VERIFY_COMPILE_ONLY=1" not in str(i.get("command", "")))
    m["package_reads"] = sum(1 for n, i in calls if re.search(r"Personal/Packages|unity-(screen-system|ui-|fast-ioc|tools-core)", str(i)))
    m["pack_reads"] = sum(1 for n, i in calls if n == "Read" and "/packs/" in str(i.get("file_path", "")))
    m["rule_reads"] = sum(1 for n, i in calls if n == "Read" and "/architecture/" in str(i.get("file_path", "")))
    s1, s2 = stage_json(run, "stage1.json"), stage_json(run, "stage2.json")
    m["seconds"] = load(os.path.join(run, "seconds.txt")).strip() or "?"
    m["cost"] = round(sum(float(s.get("total_cost_usd") or 0) for s in (s1, s2)), 3)
    report = (s2 or s1).get("result", "")
    m["table_gaps"] = "Table gaps" in report
    m["outside_packs"] = "Outside packs" in report
    m["check"] = "passed" if re.search(r"exit=0\s*$", load(os.path.join(run, "check.txt"))) else "failed"
    try:
        m["compile"] = json.load(open(os.path.join(run, "verify-summary.json"))).get("result", "not run")
    except (OSError, ValueError):
        m["compile"] = "not run"
    m["plan_files"] = plan_files(run)
    m["written"] = set(load(os.path.join(run, "files.txt")).split())
    return m


rows = [metrics(r) for r in runs]
cols = ["run", "seconds", "cost", "questions", "calls_before_write", "pack_reads", "rule_reads", "package_reads",
        "tests_run", "table_gaps", "outside_packs", "check", "compile"]
print("| " + " | ".join(cols) + " |")
print("|" + "---|" * len(cols))
for m in rows:
    print("| " + " | ".join(str(m[c]) for c in cols) + " |")

plans = [m["plan_files"] for m in rows if m["plan_files"]]
if plans:
    common, union = set.intersection(*plans), set.union(*plans)
    print(f"\nPlan files: {len(union)} in some run, {len(common)} in every run.")
    for m in rows:
        extra, missing = sorted(m["plan_files"] - common), sorted(common - m["plan_files"])
        if extra or missing:
            print(f"  {m['run']}: extra {extra}, missing {missing}")
written = [m["written"] for m in rows if m["written"]]
if written:
    print(f"Files written: {len(set.union(*written))} in some run, {len(set.intersection(*written))} in every run.")
