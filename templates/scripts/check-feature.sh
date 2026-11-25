#!/usr/bin/env bash
# Checks a feature folder against the rules a tool can check, with no Unity and no model: the same result whatever
# agent or model wrote the feature. The Stop hook runs it for every feature a change touched, before compiling, and
# sends the failures back to the agent. Each failure names its check and the rule it enforces.
#
#   CHK-01 PLAN-02  the files match Logs/ai/plan.md, when the plan is for this feature
#   CHK-02 PLAN-02  a change outside every feature (CHECK_OUTSIDE_CHANGED) is named in the plan's outside-feature
#   CHK-03 DI-11    an installer exactly when the feature binds something
#   CHK-04 EDIT-14  every FromInstance("X") has X.asset or X.asset.json in the feature
#   CHK-05 ASM-03   tests compile in Tests/Client.{Feature}.Tests.asmdef, and there is no .asmref
#   CHK-06 HAND-07  Views without prefabs come with an IMPLEMENTATION.md in the fixed sections
#   CHK-07 naming   every namespace is Client.{Feature} (Client.{Feature}.Tests in Tests/)
#   CHK-08 LIST-10  a plan with list: sectioned has a SectionedScroller
#   CHK-09 TASK-05  file names start with the feature's name; a single screen folder is {Feature}Main
#   CHK-10 MODEL-12 (warning) a list or array of literals outside the mock
#   CHK-11 MODEL-13 the files a feature always needs: a screen Model when there are Views, the slots and data of a
#                   list, the header slot of a sectioned list, the items Model and its source; Views read the screen
#                   Model, never an injected items Model, mock or Module (ROOT-06)
#   CHK-12 MODEL-02 (warning) a query that builds state the first time it's called
#   CHK-13 PLAN-02  the plan keeps what was approved: the same scope, decisions and files as the first plan of the
#                   turn; the scope the user chose (TASK-01), with no tests or prefabs it excludes; a bento layout
#                   needs a list
#   CHK-14 TASK-05  every file is a row of the Feature files table: no other types (an enum, a layout class...)
#   CHK-15 LIST-08  a bento layout is {Feature}BentoLayout.json, never tile positions computed in C#
#   CHK-16 SCR-16   only a screen's root Model calls ScreenManager: never a View, Controller, slot, items Model or mock;
#          SCR-12   every screen it opens is a ScreenIds constant, never a string or a constant of its own: a screen that
#                   doesn't exist yet is an open question for the user
#   CHK-17 async    no Forget of the feature's own: ToolsCore.TaskExtensions (Tools Core package) is the one helper
#
# The Stop hook passes the session's plan (CHECK_PLAN), the approved plan (CHECK_APPROVED_PLAN) and the scope the
# user chose (CHECK_TASK_SCOPE: code, code+tests, code+prefabs, code+prefabs+tests or unknown). CHECK_OUTSIDE_CHANGED
# lists the project files changed this turn outside every feature, one per line; the hook leaves it empty when the
# turn has no mark, and then CHK-02 doesn't run.
#
# Usage, from the project root: scripts/check-feature.sh <Feature> [<Feature>...]
# Exit code 0 when every feature passes (warnings don't fail), 1 otherwise.
set -u

CLIENT="Assets/Client"
PLAN="Logs/ai/plan.md"
[ -n "${CHECK_PLAN:-}" ] && [ -f "$CHECK_PLAN" ] && PLAN="$CHECK_PLAN"
APPROVED="${CHECK_APPROVED_PLAN:-}"
TASK_SCOPE="${CHECK_TASK_SCOPE:-unknown}"
FAILURES=0
# The turn mark (CHECK_TURN_MARKER, set by the Stop hook). A manual run uses the newest Logs/verify/turn-* mark.
TURN_MARK="${CHECK_TURN_MARKER:-}"
[ -n "$TURN_MARK" ] || TURN_MARK="$(ls -t Logs/verify/turn-* 2>/dev/null | head -1)"

fail() {
    echo "$1"
    FAILURES=$((FAILURES + 1))
}

warn() {
    echo "warning $1"
}

# Success when the file was created or changed this turn (newer than the turn mark). Without a mark, every file counts.
turn_touched() {
    [ -n "$TURN_MARK" ] && [ -f "$TURN_MARK" ] || return 0
    [ "$1" -nt "$TURN_MARK" ]
}

# The C#, JSON, Markdown and spec files of a feature that this turn created or changed, relative to its folder. Files
# that were there before the turn (the user's, or other features') aren't part of the pipeline. Without .meta files.
feature_files() {
    local f
    (cd "$1" && find . -type f \( -name '*.cs' -o -name '*.json' -o -name '*.md' -o -name '*.asmdef' -o -name '*.prefab' \) \
        | sed 's|^\./||' | sort) | while IFS= read -r f; do
        turn_touched "$1/$f" && echo "$f"
    done
}

# The files the plan lists under Files:, when its Folder: is this feature.
plan_files() {
    local feature="$1"
    [ -f "$PLAN" ] || return 1
    grep -Eq "^Folder: *$CLIENT/$feature/?\$" "$PLAN" || return 1
    awk '
        /^Files:/ { inside = 1; next }
        inside && /^[^ ]/ { exit }
        inside && /^  [^ #]/ { sub(/^  /, ""); sub(/[[:space:]].*/, ""); print }
    ' "$PLAN" | sort -u
}

plan_value() {
    awk -v key="$1" '$1 == key ":" { print $2; exit }' "${2:-$PLAN}" 2>/dev/null
}

# A plan's contract: its folder, scope, decisions and files, without comments or notes.
plan_contract() {
    awk '
        /^Folder:|^Scope:/ { sub(/[[:space:]]*#.*/, ""); print; next }
        /^Decisions:/ { section = "decision"; next }
        /^Files:/ { section = "file"; next }
        /^[^ ]/ { section = "" }
        section != "" && /^  [^ #]/ { line = $0; sub(/[[:space:]]*#.*/, "", line); sub(/^ +/, "", line); print section " " line }
    ' "$1" | sort
}

plan_folder_is() {
    grep -Eq "^Folder: *$CLIENT/$2/?([[:space:]]|\$)" "$1" 2>/dev/null
}

check_plan() {
    local feature="$1" folder="$2" planned actual
    planned="$(plan_files "$feature")" || return 0
    # A planned file is missing when it isn't on disk, whether or not this turn touched it.
    while IFS= read -r missing; do
        [ -n "$missing" ] && [ ! -e "$folder/$missing" ] && echo "CHK-01 PLAN-02: $feature/$missing is in the plan but doesn't exist"
    done <<< "$planned"
    actual="$(feature_files "$folder" | sort -u)"
    comm -13 <(printf '%s\n' "$planned") <(printf '%s\n' "$actual") | while IFS= read -r extra; do
        [ -n "$extra" ] && echo "CHK-01 PLAN-02: $feature/$extra isn't in the plan: add it to Logs/ai/plan.md and ask, or remove it"
    done
}

check_installer() {
    local feature="$1" folder="$2" binds
    binds="$(find "$folder" -path '*/Services/*' \( -name 'Mock*.cs' -o -name '*ItemsModel.cs' -o -name '*Config.cs' \
        -o -name '*Module.cs' -o -name '*Connector.cs' \) 2>/dev/null | head -1)"
    if [ -n "$binds" ] && [ ! -f "$folder/Services/${feature}Installer.cs" ]; then
        fail "CHK-03 DI-11: $feature binds $(basename "$binds" .cs) but has no Services/${feature}Installer.cs"
    elif [ -z "$binds" ] && [ -n "$(find "$folder" -name '*Installer.cs' 2>/dev/null | head -1)" ]; then
        fail "CHK-03 DI-11: $feature has an installer but nothing to bind: remove it"
    fi
}

check_assets() {
    local feature="$1" folder="$2" name
    grep -rhoE 'FromInstance\("[^"]+"\)' "$folder" --include='*.cs' 2>/dev/null | sed 's/FromInstance("\(.*\)")/\1/' | sort -u |
        while IFS= read -r name; do
            case "$name" in */*) echo "CHK-04 DI-11: $feature passes a path to FromInstance(\"$name\"): pass the asset's name"; continue ;; esac
            [ -n "$(find "$folder" \( -name "$name.asset" -o -name "$name.asset.json" \) 2>/dev/null | head -1)" ] ||
                echo "CHK-04 EDIT-14: $feature binds FromInstance(\"$name\") but has no $name.asset.json spec"
        done
}

check_tests() {
    local feature="$1" folder="$2" asmdef
    if [ -n "$(find "$folder" -name '*.asmref' 2>/dev/null | head -1)" ]; then
        fail "CHK-05 ASM-03: $feature has an .asmref: tests compile in their own Tests/Client.$feature.Tests.asmdef"
    fi
    [ -n "$(find "$folder/Tests" -name '*.cs' 2>/dev/null | head -1)" ] || return 0
    asmdef="$folder/Tests/Client.$feature.Tests.asmdef"
    if [ ! -f "$asmdef" ]; then
        fail "CHK-05 ASM-03: $feature has tests but no Tests/Client.$feature.Tests.asmdef"
    elif ! grep -q "\"name\": *\"Client.$feature.Tests\"" "$asmdef" || ! grep -q "\"rootNamespace\": *\"Client.$feature.Tests\"" "$asmdef"; then
        fail "CHK-05 ASM-03: Tests/Client.$feature.Tests.asmdef needs name and rootNamespace Client.$feature.Tests"
    fi
}

check_handoff() {
    local feature="$1" folder="$2" doc="$folder/IMPLEMENTATION.md" previous=0 section line
    [ -n "$(find "$folder" -name '*View.cs' 2>/dev/null | head -1)" ] || return 0
    [ -z "$(find "$folder" -name '*.prefab' 2>/dev/null | head -1)" ] || return 0
    if [ ! -f "$doc" ]; then
        fail "CHK-06 HAND-07: $feature has Views and no prefabs, but no IMPLEMENTATION.md for the Unity work"
        return
    fi
    for section in "## Code" "## Prefabs" "## Inspector assignments"; do
        grep -qx "$section" "$doc" || fail "CHK-06 HAND-07: $feature/IMPLEMENTATION.md has no \"$section\" section"
    done
    for section in "## Code" "## Assets to create" "## Prefabs" "## Inspector assignments" "## First run" "## Play mode check"; do
        line="$(grep -nx "$section" "$doc" | head -1 | cut -d: -f1)"
        [ -n "$line" ] || continue
        [ "$line" -gt "$previous" ] || fail "CHK-06 HAND-07: $feature/IMPLEMENTATION.md has \"$section\" out of order"
        previous="$line"
    done
}

check_namespaces() {
    local feature="$1" folder="$2" file expected namespace
    while IFS= read -r file; do
        case "$file" in Tests/*) expected="Client.$feature.Tests" ;; *) expected="Client.$feature" ;; esac
        namespace="$(grep -m1 -E '^namespace ' "$folder/$file" | sed -E 's/^namespace +([A-Za-z0-9_.]+).*/\1/')"
        [ "$namespace" = "$expected" ] || fail "CHK-07 naming: $feature/$file is in namespace ${namespace:-none}, not $expected"
    done < <(feature_files "$folder" | grep '\.cs$')
}

check_list() {
    local feature="$1" folder="$2"
    plan_files "$feature" > /dev/null || return 0
    [ "$(plan_value list)" = sectioned ] || return 0
    grep -rqE ':[[:space:]]*SectionedScroller<' "$folder" --include='*Scroller.cs' ||
        fail "CHK-08 LIST-10: the plan says list: sectioned, but no Scroller in $feature derives from SectionedScroller"
}

check_names() {
    local feature="$1" folder="$2" file name screens
    while IFS= read -r file; do
        name="$(basename "$file")"
        case "$name" in
            "$feature"*|"Mock$feature"*|"I$feature"*|*Controller.cs|IMPLEMENTATION.md|"Client.$feature.Tests.asmdef") ;;
            *) fail "CHK-09 TASK-05: $feature/$file doesn't start with $feature (names are {Feature} or {Feature}{Subject})" ;;
        esac
    done < <(feature_files "$folder" | grep -v '\.asset\.json$')
    screens="$(cd "$folder" && find . -mindepth 1 -maxdepth 1 -type d ! -name Services ! -name Tests | sed 's|^\./||')"
    if [ "$(printf '%s' "$screens" | grep -c .)" = 1 ] && [ "$screens" != "${feature}Main" ]; then
        fail "CHK-09 TASK-05: $feature has one screen folder, $screens: name it ${feature}Main"
    fi
}

check_literals() {
    local feature="$1" folder="$2" file
    while IFS= read -r file; do
        case "$(basename "$file")" in Mock*) continue ;; esac
        grep -qE 'new (List<[^>]+>|[A-Za-z0-9_]+\[\]) *(\(\))? *\{[^}]*"' "$folder/$file" &&
            warn "CHK-10 MODEL-12: $feature/$file holds a list of literals: sample data goes in Services/Mock$feature""Items.cs"
    done < <(feature_files "$folder" | grep '\.cs$' | grep -v '^Tests/')
}

# A file whose name ends with the suffix, in the feature (any folder).
has_file() {
    [ -n "$(find "$1" -name "*$2" ! -name '*.meta' 2>/dev/null | head -1)" ]
}

check_required() {
    local feature="$1" folder="$2" file
    if has_file "$folder" "View.cs"; then
        [ -n "$(find "$folder" -name "${feature}*Model.cs" ! -name '*SlotModel.cs' ! -name '*ItemsModel.cs' ! -path '*/Services/*' 2>/dev/null | head -1)" ] ||
            fail "CHK-11 MODEL-13: $feature has Views but no screen Model ({Screen}/${feature}Model.cs, a MonoBehaviour on the screen root that reads the items Model)"
        while IFS= read -r file; do
            grep -qE 'internal +(Mock[A-Za-z0-9_]+|[A-Za-z0-9_]+ItemsModel|[A-Za-z0-9_]+Module) +[a-zA-Z_]' "$folder/$file" &&
                fail "CHK-11 ROOT-06: $feature/$file injects the items Model, mock or Module: a View reads the screen Model (GetComponentInParent)"
        done < <(cd "$folder" && find . -name '*View.cs' | sed 's|^\./||')
    fi
    if has_file "$folder" "Scroller.cs"; then
        for file in SlotModel.cs SlotView.cs ItemData.cs; do
            has_file "$folder" "$file" || fail "CHK-11 TASK-05: $feature has a Scroller but no ${feature}${file}"
        done
        if grep -rqE ':[[:space:]]*SectionedScroller<' "$folder" --include='*Scroller.cs'; then
            for file in SectionData.cs HeaderSlotModel.cs HeaderSlotView.cs; do
                has_file "$folder" "$file" || fail "CHK-11 LIST-10: $feature has a SectionedScroller but no ${feature}${file}"
            done
        fi
    fi
    if has_file "$folder" "ItemsModel.cs" && [ -z "$(find "$folder" -path '*/Services/*' \( -name 'Mock*Items.cs' -o -name '*Module.cs' \) 2>/dev/null | head -1)" ]; then
        fail "CHK-11 MODEL-12: $feature has an items Model but no source: Services/Mock${feature}Items.cs or a Module"
    fi
    if [ -n "$(find "$folder" -path '*/Services/*' -name 'Mock*Items.cs' 2>/dev/null | head -1)" ] && ! has_file "$folder" "ItemsModel.cs"; then
        fail "CHK-11 MODEL-13: $feature has a mock but no Services/${feature}ItemsModel.cs that builds the sources from it"
    fi
}

check_lazy_queries() {
    local feature="$1" folder="$2" file
    while IFS= read -r file; do
        grep -qE 'if *\([^)]*(Count|SectionCount|Length) *== *0\)' "$folder/$file" && grep -qE 'public [A-Za-z<>, ]+ Get[A-Za-z]*\(' "$folder/$file" &&
            warn "CHK-12 MODEL-02: $feature/$file may build state inside a query (a Get method with an empty check): build it in the constructor"
    done < <(cd "$folder" && find . -name '*Model.cs' | sed 's|^\./||')
}

# A prefab made this turn. With the turn mark (CHECK_TURN_MARKER), prefabs that were there before the turn don't count:
# the user's own prefabs, such as one made with Screen System before the task, aren't the task's scope. Without the mark,
# any prefab counts.
made_prefab() {
    if [ -n "$TURN_MARK" ] && [ -f "$TURN_MARK" ]; then
        [ -n "$(find "$1" -name '*.prefab' -newer "$TURN_MARK" 2>/dev/null | head -1)" ]
    else
        has_file "$1" ".prefab"
    fi
}

check_contract() {
    local feature="$1" folder="$2" scope layout list
    if [ -f "$APPROVED" ] && plan_folder_is "$APPROVED" "$feature"; then
        if ! plan_folder_is "$PLAN" "$feature"; then
            fail "CHK-13 PLAN-02: the approved plan for $feature is gone from Logs/ai/plan.md: restore it"
        else
            diff <(plan_contract "$APPROVED") <(plan_contract "$PLAN") | grep '^[<>]' | while IFS= read -r change; do
                # Moving the plan to the scope the user chose is a fix, not a change: the new Scope, and tests it excludes.
                if [ "$TASK_SCOPE" != unknown ]; then
                    case "$change" in
                        "> Scope: $TASK_SCOPE"|"< Scope: "*) continue ;;
                    esac
                    case "$TASK_SCOPE" in *tests*) ;; *) case "$change" in "< file Tests/"*) continue ;; esac ;; esac
                fi
                case "$change" in
                    "<"*) echo "CHK-13 PLAN-02: $feature's plan dropped \"${change#< }\" after it was approved: do what the plan says, or ask the user" ;;
                    ">"*) echo "CHK-13 PLAN-02: $feature's plan added \"${change#> }\" after it was approved: ask the user first" ;;
                esac
            done
        fi
    fi
    plan_folder_is "$PLAN" "$feature" && scope="$(plan_value Scope)"
    if [ "$TASK_SCOPE" != unknown ] && [ -n "${scope:-}" ] && [ "$scope" != "$TASK_SCOPE" ]; then
        echo "CHK-13 TASK-01: $feature's plan says Scope: $scope, but the user chose $TASK_SCOPE"
    fi
    [ "$TASK_SCOPE" != unknown ] && scope="$TASK_SCOPE"
    if [ -n "${scope:-}" ]; then
        case "$scope" in *tests*) ;; *) [ -d "$folder/Tests" ] && echo "CHK-13 TASK-02: $feature has Tests/, but the scope is $scope: remove them and list the tests in the report" ;; esac
        case "$scope" in *prefabs*) ;; *) made_prefab "$folder" && echo "CHK-13 TASK-02: $feature has prefabs made this turn, but the scope is $scope: describe them in IMPLEMENTATION.md" ;; esac
    fi
    if plan_folder_is "$PLAN" "$feature"; then
        layout="$(plan_value layout)"; list="$(plan_value list)"
        [ "$layout" = bento ] && [ "$list" = none ] && echo "CHK-13 LIST-10: $feature's plan has layout: bento with list: none: a bento layout is a list's (a Scroller with its slots)"
    fi
}

# The Feature files table as patterns, with F the feature's name and an optional {Subject}.
check_table() {
    local feature="$1" folder="$2" file name f="$1" subject='([A-Z][A-Za-z0-9]*)?'
    while IFS= read -r file; do
        name="$(basename "$file")"
        case "$file" in
            IMPLEMENTATION.md) continue ;;
            Tests/*) printf '%s' "$name" | grep -Eq "^($f.*Tests\.cs|Client\.$f\.Tests\.asmdef)\$" && continue ;;
            Services/Resources/*) printf '%s' "$name" | grep -Eq "^$f${subject}Config\.asset\.json\$" && continue ;;
            Services/*) printf '%s' "$name" | grep -Eq "^($f${subject}(ItemsModel|Config|Installer|Module|Connector|Data|SystemClock|Format)|Mock$f${subject}Items|I$f${subject}(Connector|Clock))\.cs\$" && continue ;;
            */*) printf '%s' "$name" | grep -Eq "^($f${subject}(Model|View|ListView|Scroller|SlotModel|SlotView|ItemData|SectionData|HeaderSlotModel|HeaderSlotView)\.cs|[A-Z][A-Za-z0-9]*Controller\.cs|$f${subject}BentoLayout\.json|$f${subject}(Slot|HeaderSlot)?\.prefab|$f${subject}(Slot|HeaderSlot)?\.json)\$" && continue ;;
        esac
        fail "CHK-14 TASK-05: $feature/$file isn't a row of the Feature files table (planning.md): fold it into a listed file, or ask before adding a new kind"
    done < <(feature_files "$folder")
}

check_bento() {
    local feature="$1" folder="$2"
    if grep -rqE '(class|struct|enum) +[A-Za-z0-9_]*(Bento|Tile)[A-Za-z0-9_]*|new +Bento(Tile|Pattern|Span|Layout) *\(' "$folder" --include='*.cs' 2>/dev/null; then
        fail "CHK-15 LIST-08: $feature computes a bento layout in C#: write ${feature}BentoLayout.json and assign it to the Scroller's Layout JSON"
    fi
    if plan_folder_is "$PLAN" "$feature" && [ "$(plan_value layout)" = bento ] && [ -z "$(find "$folder" -name "*BentoLayout.json" 2>/dev/null | head -1)" ]; then
        fail "CHK-15 LIST-08: $feature's plan has layout: bento but no ${feature}BentoLayout.json"
    fi
}

check_navigation() {
    local feature="$1" folder="$2" file
    while IFS= read -r file; do
        case "$(basename "$file")" in
            *View.cs|*Controller.cs|*SlotModel.cs|*ItemsModel.cs|Mock*.cs) ;;
            *) continue ;;
        esac
        grep -q 'ScreenManager' "$folder/$file" &&
            echo "CHK-16 SCR-16: $feature/$file uses ScreenManager: navigation is a command on the screen's root Model, which the Controller calls"
    done < <(feature_files "$folder" | grep '\.cs$')
    # Every navigation call names its screen with a generated ScreenIds constant.
    grep -rnoE '\.(GoTo|GoToForResult|PopTo|SetRoot)(<[^>]*>)? *\( *[^,)]+' "$folder" --include='*.cs' 2>/dev/null | while IFS= read -r match; do
        argument="${match#*(}"; argument="${argument# }"
        case "$argument" in
            ScreenIds.*) ;;
            *) echo "CHK-16 SCR-12: ${match%%:*} opens a screen with $argument instead of a ScreenIds constant: if the screen doesn't exist yet, ask the user to create it first (Open questions)" | sed "s|$CLIENT/||" ;;
        esac
    done
}

check_forget() {
    local feature="$1" folder="$2"
    grep -rqE 'static +(async +)?void +Forget *\(' "$folder" --include='*.cs' 2>/dev/null &&
        fail "CHK-17 async: $feature defines its own Forget: use ToolsCore.TaskExtensions.Forget from the Tools Core package"
}

# CHK-02: a change outside the features is declared in the plan's outside-feature line, with its reason. The line is
# matched by path, so "outside-feature: Client.asmdef (adds Fast IoC.Core)" declares Client.asmdef.
check_outside() {
    [ -n "${CHECK_OUTSIDE_CHANGED:-}" ] || return 0
    local declared path
    # The plan's decision line sits under Decisions (indented) in the fixed form, or at column 0 in older plans.
    declared="$(grep -E '^[[:space:]]*outside-feature:' "$PLAN" 2>/dev/null | sed 's/^[[:space:]]*outside-feature://')"
    while IFS= read -r path; do
        [ -n "$path" ] || continue
        case "$declared" in
            *"$path"*) ;;
            *) fail "CHK-02 PLAN-02: $path changed outside the features and outside-feature doesn't name it: name it with its reason after asking the user, or revert it" ;;
        esac
    done <<< "$CHECK_OUTSIDE_CHANGED"
}

[ $# -gt 0 ] || { sed -n '2,36p' "$0"; exit 2; }
check_outside
for feature in "$@"; do
    folder="$CLIENT/$feature"
    [ -d "$folder" ] || continue
    while IFS= read -r line; do
        [ -n "$line" ] && fail "$line"
    done < <(check_plan "$feature" "$folder"; check_assets "$feature" "$folder"; check_contract "$feature" "$folder"; check_navigation "$feature" "$folder")
    check_installer "$feature" "$folder"
    check_tests "$feature" "$folder"
    check_handoff "$feature" "$folder"
    check_namespaces "$feature" "$folder"
    check_list "$feature" "$folder"
    check_names "$feature" "$folder"
    check_literals "$feature" "$folder"
    check_required "$feature" "$folder"
    check_lazy_queries "$feature" "$folder"
    check_table "$feature" "$folder"
    check_bento "$feature" "$folder"
    check_forget "$feature" "$folder"
done
exit $(( FAILURES > 0 ))
