#!/usr/bin/env bash
# Tests templates/scripts/check-feature.sh: a feature that follows the rules passes, and each broken variant fails with
# exactly its check. Usage: bash tools/test-check-feature.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="$REPO/templates/scripts/check-feature.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILURES=0

# A correct feature: one sectioned bento list of runtime data from a mock, an installer, tests, and the handoff.
make_shop() {
    local root="$1" f="$1/Assets/Client/Shop"
    mkdir -p "$f/ShopMain" "$f/Services" "$f/Tests" "$1/Logs/ai"
    for name in ShopModel ShopItemData ShopListView ShopScroller ShopSlotModel ShopSlotView ShopSectionData ShopHeaderSlotModel ShopHeaderSlotView; do
        printf 'namespace Client.Shop\n{\n    public class %s { }\n}\n' "$name" > "$f/ShopMain/$name.cs"
    done
    printf 'using UIScroller;\nnamespace Client.Shop\n{\n    public class ShopScroller : SectionedScroller<ShopItemData, ShopSectionData> { }\n}\n' > "$f/ShopMain/ShopScroller.cs"
    printf '{ "columns": 3 }\n' > "$f/ShopMain/ShopBentoLayout.json"
    printf 'namespace Client.Shop\n{\n    public class MockShopItems { }\n}\n' > "$f/Services/MockShopItems.cs"
    printf 'namespace Client.Shop\n{\n    public class ShopItemsModel { }\n}\n' > "$f/Services/ShopItemsModel.cs"
    printf 'namespace Client.Shop\n{\n    public class ShopInstaller { void InstallBindings() { Bind<MockShopItems>().AsSingle(); } }\n}\n' > "$f/Services/ShopInstaller.cs"
    printf 'namespace Client.Shop.Tests\n{\n    public class ShopItemsModelTests { }\n}\n' > "$f/Tests/ShopItemsModelTests.cs"
    printf '{ "name": "Client.Shop.Tests", "rootNamespace": "Client.Shop.Tests" }\n' > "$f/Tests/Client.Shop.Tests.asmdef"
    printf '# Shop: implementation\n\n## Code\n\n## Prefabs\n\n## Inspector assignments\n\n## First run\n' > "$f/IMPLEMENTATION.md"
    {
        printf 'Feature: Shop\nFolder: Assets/Client/Shop\nDecisions:\n  list: sectioned                # LIST-10\nFiles:\n'
        (cd "$f" && find . -type f | sed 's|^\./|  |' | sort)
        printf 'Open questions:\n  none\n'
    } > "$1/Logs/ai/plan.md"
}

# Runs the check on a fresh copy changed by $2, and expects exactly the check $3 (or a pass when $3 is empty).
expect() {
    local label="$1" change="$2" expected="$3" project output code
    project="$TMP/$(echo "$label" | tr -c 'a-zA-Z0-9' '_')"
    make_shop "$project"
    (cd "$project/Assets/Client/Shop" && eval "$change")
    output="$(cd "$project" && bash "$CHECK" Shop 2>&1)"; code=$?
    if [ -z "$expected" ]; then
        if [ "$code" -eq 0 ] && ! grep -q '^CHK' <<< "$output"; then echo "ok    $label"; else echo "FAIL  $label: $output"; FAILURES=$((FAILURES + 1)); fi
        return
    fi
    if [ "$code" -ne 0 ] && [ "$(grep -c '^CHK' <<< "$output")" -ge 1 ] && ! grep '^CHK' <<< "$output" | grep -Eqv "^($expected) "; then
        echo "ok    $label"
    else
        echo "FAIL  $label (expected only $expected): $output"
        FAILURES=$((FAILURES + 1))
    fi
}

expect "a feature that follows the rules passes" ":" ""
expect "a file not in the plan" "printf 'namespace Client.Shop\n{ }\n' > ShopMain/ShopOfferModel.cs" "CHK-01"
expect "a planned file that's missing" "rm ShopMain/ShopBentoLayout.json" "CHK-01"
expect "data to bind but no installer" "rm Services/ShopInstaller.cs; sed -i.bak '/ShopInstaller/d' ../../../Logs/ai/plan.md" "CHK-03"
expect "a FromInstance without its spec" "printf 'namespace Client.Shop\n{ class ShopConfig { } }\n' > Services/ShopConfig.cs; printf 'namespace Client.Shop\n{ class ShopInstaller { void I() { Bind<ShopConfig>().FromInstance(\"ShopConfig\").AsSingle(); } } }\n' > Services/ShopInstaller.cs; sed -i.bak 's|^Open questions:|  Services/ShopConfig.cs\\
Open questions:|' ../../../Logs/ai/plan.md" "CHK-04"
expect "tests without their asmdef" "rm Tests/Client.Shop.Tests.asmdef; sed -i.bak '/asmdef/d' ../../../Logs/ai/plan.md" "CHK-05"
expect "Views without prefabs and no handoff" "rm IMPLEMENTATION.md; sed -i.bak '/IMPLEMENTATION/d' ../../../Logs/ai/plan.md" "CHK-06"
expect "a handoff section out of order" "printf '# Shop\n\n## Prefabs\n\n## Code\n\n## Inspector assignments\n' > IMPLEMENTATION.md" "CHK-06"
expect "a namespace that isn't the feature's" "sed -i.bak 's/namespace Client.Shop$/namespace Client.Store/' ShopMain/ShopModel.cs; rm ShopMain/ShopModel.cs.bak" "CHK-07"
expect "a sectioned plan without a SectionedScroller" "printf 'namespace Client.Shop\n{ class ShopScroller : Scroller<ShopItemData> { } }\n' > ShopMain/ShopScroller.cs" "CHK-08"
expect "a file named after another feature" "mv ShopMain/ShopSlotView.cs ShopMain/InventorySlotView.cs; sed -i.bak 's|ShopMain/ShopSlotView.cs|ShopMain/InventorySlotView.cs|' ../../../Logs/ai/plan.md" "CHK-09|CHK-14"
expect "a single screen folder not named ShopMain" "mv ShopMain Main; sed -i.bak 's|ShopMain/|Main/|' ../../../Logs/ai/plan.md" "CHK-09"

expect "Views but no screen Model" "rm ShopMain/ShopModel.cs; sed -i.bak '/ShopMain\/ShopModel.cs/d' ../../../Logs/ai/plan.md" "CHK-11"
expect "a View that injects the items Model" "printf 'namespace Client.Shop\n{ class ShopListView { internal ShopItemsModel shopItemsModel; } }\n' > ShopMain/ShopListView.cs" "CHK-11"
expect "a sectioned list without its header slot" "rm ShopMain/ShopHeaderSlotView.cs; sed -i.bak '/ShopHeaderSlotView/d' ../../../Logs/ai/plan.md" "CHK-11"
expect "a mock without the items Model" "rm Services/ShopItemsModel.cs; sed -i.bak '/ShopItemsModel.cs/d' ../../../Logs/ai/plan.md" "CHK-11"

expect "a type that isn't a table row" "printf 'namespace Client.Shop\n{ enum ShopRarity { Common } }\n' > ShopMain/ShopRarity.cs; sed -i.bak 's|^Open questions:|  ShopMain/ShopRarity.cs\\
Open questions:|' ../../../Logs/ai/plan.md" "CHK-14"
expect "a bento layout computed in C#" "printf 'namespace Client.Shop\n{ class ShopModel { object t = new BentoTile(0, 0, 2, 2); } }\n' > ShopMain/ShopModel.cs" "CHK-15"
expect "a bento plan with list none" "sed -i.bak 's|^  list: sectioned.*|  list: none|' ../../../Logs/ai/plan.md; printf '  layout: bento\n' > /dev/null; sed -i.bak 's|^Decisions:|Decisions:\\
  layout: bento|' ../../../Logs/ai/plan.md; rm ShopMain/ShopScroller.cs; sed -i.bak '/ShopScroller/d' ../../../Logs/ai/plan.md" "CHK-13|CHK-11"

# The plan approved at the start of the turn is the contract: dropping a decision after a rejection fails.
CONTRACT="$TMP/contract"; make_shop "$CONTRACT"
cp "$CONTRACT/Logs/ai/plan.md" "$CONTRACT/approved.md"
sed -i.bak 's|^  list: sectioned.*|  list: none|' "$CONTRACT/Logs/ai/plan.md"
out="$(cd "$CONTRACT" && CHECK_APPROVED_PLAN=approved.md bash "$CHECK" Shop)"
if grep -q 'CHK-13 PLAN-02: Shop.s plan dropped "decision list: sectioned"' <<< "$out" && grep -q 'added "decision list: none"' <<< "$out"; then echo "ok    a plan changed after approval fails"; else echo "FAIL  plan contract: $out"; FAILURES=$((FAILURES + 1)); fi

# The scope the user chose wins over the plan's, and excludes tests.
SCOPE="$TMP/scope"; make_shop "$SCOPE"
sed -i.bak 's|^Feature: Shop|Feature: Shop\
Scope: code+tests|' "$SCOPE/Logs/ai/plan.md"
out="$(cd "$SCOPE" && CHECK_TASK_SCOPE=code bash "$CHECK" Shop)"
if grep -q 'CHK-13 TASK-01: .*Scope: code+tests, but the user chose code' <<< "$out" && grep -q 'CHK-13 TASK-02: Shop has Tests/' <<< "$out"; then echo "ok    tests in a code-only scope fail"; else echo "FAIL  user scope: $out"; FAILURES=$((FAILURES + 1)); fi

expect "a Controller that navigates" "printf 'namespace Client.Shop\n{ class OpenOfferController { void OnClick() { ScreenManager.Instance.GoTo(ScreenIds.ShopOffer); } } }\n' > ShopMain/OpenOfferController.cs; sed -i.bak 's|^Open questions:|  ShopMain/OpenOfferController.cs\\
Open questions:|' ../../../Logs/ai/plan.md" "CHK-16"

# Moving the plan to the scope the user chose is allowed: Scope and the tests it excludes.
FIX="$TMP/fix"; make_shop "$FIX"
sed -i.bak 's|^Feature: Shop|Feature: Shop\
Scope: code+tests|' "$FIX/Logs/ai/plan.md"; cp "$FIX/Logs/ai/plan.md" "$FIX/approved.md"
rm -rf "$FIX/Assets/Client/Shop/Tests"; sed -i.bak -e 's|^Scope: code+tests|Scope: code|' -e '/Tests\//d' "$FIX/Logs/ai/plan.md"
out="$(cd "$FIX" && CHECK_APPROVED_PLAN=approved.md CHECK_TASK_SCOPE=code bash "$CHECK" Shop)"
if [ -z "$(grep '^CHK' <<< "$out")" ]; then echo "ok    moving the plan to the user's scope passes"; else echo "FAIL  scope fix: $out"; FAILURES=$((FAILURES + 1)); fi
expect "a formatting helper in Services is a table row" "printf 'namespace Client.Shop\n{ static class ShopFormat { } }\n' > Services/ShopFormat.cs; sed -i.bak 's|^Open questions:|  Services/ShopFormat.cs\\
Open questions:|' ../../../Logs/ai/plan.md" ""
expect "a clock behind an interface is a table row" "printf 'namespace Client.Shop\n{ interface IShopClock { } }\n' > Services/IShopClock.cs; printf 'namespace Client.Shop\n{ class ShopSystemClock { } }\n' > Services/ShopSystemClock.cs; sed -i.bak 's|^Open questions:|  Services/IShopClock.cs\\
  Services/ShopSystemClock.cs\\
Open questions:|' ../../../Logs/ai/plan.md" ""

expect "a screen opened with a string" "printf 'namespace Client.Shop\n{ class ShopModel { const string POPUP = \"ShopOffer\"; void Open(int id) { ScreenManager.Instance.GoTo(POPUP, id).Forget(\"Shop\"); } } }\n' > ShopMain/ShopModel.cs" "CHK-16"
expect "a screen opened with ScreenIds passes" "printf 'namespace Client.Shop\n{ class ShopModel { void Open(int id) { ScreenManager.Instance.GoTo(ScreenIds.ShopOffer, id).Forget(\"Shop\"); } } }\n' > ShopMain/ShopModel.cs" ""
expect "a Forget of the feature's own" "printf 'namespace Client.Shop\n{ class ShopModel { } static class ShopTaskExtensions { public static async void Forget(this System.Threading.Tasks.Task t, string c) { await t; } } }\n' > ShopMain/ShopModel.cs" "CHK-17"

LAZY="$TMP/lazy"; make_shop "$LAZY"
printf 'namespace Client.Shop\n{\n    class ShopModel { public object GetSource() { if (sections.SectionCount == 0) Build(); return sections; } }\n}\n' > "$LAZY/Assets/Client/Shop/ShopMain/ShopModel.cs"
if out="$(cd "$LAZY" && bash "$CHECK" Shop)" && grep -q '^warning CHK-12' <<< "$out"; then echo "ok    a query that builds state warns"; else echo "FAIL  lazy query warning: $out"; FAILURES=$((FAILURES + 1)); fi

# A list of literals outside the mock is only a warning.
WARN="$TMP/warn"; make_shop "$WARN"
printf 'namespace Client.Shop\n{\n    class ShopModel { System.Collections.Generic.List<string> names = new List<string> { "Sword" }; }\n}\n' > "$WARN/Assets/Client/Shop/ShopMain/ShopModel.cs"
if out="$(cd "$WARN" && bash "$CHECK" Shop)" && grep -q '^warning CHK-10' <<< "$out"; then echo "ok    a list of literals outside the mock warns without failing"; else echo "FAIL  literals warning: $out"; FAILURES=$((FAILURES + 1)); fi

# CHK-02: a change outside the features fails unless the plan's outside-feature names it.
OUTSIDE="$TMP/outside"; make_shop "$OUTSIDE"
out="$(cd "$OUTSIDE" && CHECK_OUTSIDE_CHANGED="Assets/Client/Shared/Helper.cs" bash "$CHECK" Shop)"
if grep -q '^CHK-02 PLAN-02: Assets/Client/Shared/Helper.cs changed outside' <<< "$out"; then echo "ok    a change outside the features that the plan doesn't name fails"; else echo "FAIL  CHK-02: $out"; FAILURES=$((FAILURES + 1)); fi
printf 'outside-feature: Assets/Client/Shared/Helper.cs (the shared helper)\n' >> "$OUTSIDE/Logs/ai/plan.md"
out="$(cd "$OUTSIDE" && CHECK_OUTSIDE_CHANGED="Assets/Client/Shared/Helper.cs" bash "$CHECK" Shop)"
# The fixed plan form puts outside-feature under Decisions, indented: the same declaration counts.
INDENT="$TMP/outside-indent"; make_shop "$INDENT"
printf '  outside-feature: Assets/Client/Shared/Helper.cs (the shared helper)\n' >> "$INDENT/Logs/ai/plan.md"
out="$(cd "$INDENT" && CHECK_OUTSIDE_CHANGED="Assets/Client/Shared/Helper.cs" bash "$CHECK" Shop)"
if [ -z "$(grep '^CHK-02' <<< "$out")" ]; then echo "ok    an indented outside-feature under Decisions counts"; else echo "FAIL  indented outside-feature: $out"; FAILURES=$((FAILURES + 1)); fi
if [ -z "$(grep '^CHK-02' <<< "$out")" ]; then echo "ok    a change outside the features that outside-feature names passes"; else echo "FAIL  CHK-02 declared: $out"; FAILURES=$((FAILURES + 1)); fi

# Prefabs that were there before the turn don't break a code-only scope; one made this turn does.
PREF="$TMP/prefab-turn"; make_shop "$PREF"
printf 'prefab\n' > "$PREF/Assets/Client/Shop/ShopMain/ShopOld.prefab"; touch -t 202001010000 "$PREF/Assets/Client/Shop/ShopMain/ShopOld.prefab"
touch -t 202501010000 "$PREF/turn"
out="$(cd "$PREF" && CHECK_TASK_SCOPE=code CHECK_TURN_MARKER="$PREF/turn" bash "$CHECK" Shop)"
if [ -z "$(grep 'prefabs made this turn' <<< "$out")" ]; then echo "ok    a prefab from before the turn is outside a code-only scope's check"; else echo "FAIL  old prefab: $out"; FAILURES=$((FAILURES + 1)); fi
printf 'prefab\n' > "$PREF/Assets/Client/Shop/ShopMain/ShopNew.prefab"
out="$(cd "$PREF" && CHECK_TASK_SCOPE=code CHECK_TURN_MARKER="$PREF/turn" bash "$CHECK" Shop)"
if grep -q 'prefabs made this turn' <<< "$out"; then echo "ok    a prefab made this turn fails a code-only scope"; else echo "FAIL  new prefab: $out"; FAILURES=$((FAILURES + 1)); fi

echo
# The pipeline checks only what this turn created or changed: an untouched file that breaks a rule is not this turn's.
PIPE="$TMP/pipeline"; make_shop "$PIPE"
printf 'namespace Client.Shop\n{ class OldHelper { } }\n' > "$PIPE/Assets/Client/Shop/ShopMain/OldHelper.cs"; touch -t 202001010000 "$PIPE/Assets/Client/Shop/ShopMain/OldHelper.cs"
touch -t 202501010000 "$PIPE/turn"
out="$(cd "$PIPE" && CHECK_TURN_MARKER="$PIPE/turn" bash "$CHECK" Shop)"
if [ -z "$(grep 'OldHelper' <<< "$out")" ]; then echo "ok    an untouched file that breaks a rule is not checked this turn"; else echo "FAIL  untouched file: $out"; FAILURES=$((FAILURES + 1)); fi
printf 'namespace Client.Shop\n{ class NewHelper { } }\n' > "$PIPE/Assets/Client/Shop/ShopMain/NewHelper.cs"
out="$(cd "$PIPE" && CHECK_TURN_MARKER="$PIPE/turn" bash "$CHECK" Shop)"
if grep -q 'NewHelper' <<< "$out"; then echo "ok    a file this turn created is checked"; else echo "FAIL  new file: $out"; FAILURES=$((FAILURES + 1)); fi

# CHK-18: a screen or prefab that existed when the session started and is gone fails.
EXIST="$TMP/existing"; make_shop "$EXIST"
printf '# facts\n- Existing screens and prefabs per feature (source: x):\n  - `Shop`: ShopMain/ShopPopup.prefab\n' > "$EXIST/Logs/ai/project-facts.md"
printf 'prefab\n' > "$EXIST/Assets/Client/Shop/ShopMain/ShopPopup.prefab"
out="$(cd "$EXIST" && CHECK_FACTS=Logs/ai/project-facts.md bash "$CHECK" Shop)"
if [ -z "$(grep 'CHK-18' <<< "$out")" ]; then echo "ok    an existing prefab that is still there passes"; else echo "FAIL  existing present: $out"; FAILURES=$((FAILURES + 1)); fi
rm "$EXIST/Assets/Client/Shop/ShopMain/ShopPopup.prefab"
out="$(cd "$EXIST" && CHECK_FACTS=Logs/ai/project-facts.md bash "$CHECK" Shop)"
if grep -q 'CHK-18 TASK-06: Shop/ShopMain/ShopPopup.prefab existed' <<< "$out"; then echo "ok    a deleted existing prefab fails CHK-18"; else echo "FAIL  existing deleted: $out"; FAILURES=$((FAILURES + 1)); fi

# A deletion the user asked for and confirmed is named in the plan's delete: line, and CHK-18 allows it.
printf '  delete: Assets/Client/Shop/ShopMain/ShopPopup.prefab   # the user asked and confirmed\n' >> "$EXIST/Logs/ai/plan.md"
out="$(cd "$EXIST" && CHECK_FACTS=Logs/ai/project-facts.md bash "$CHECK" Shop)"
if [ -z "$(grep 'CHK-18' <<< "$out")" ]; then echo "ok    a deletion the user asked for and confirmed passes"; else echo "FAIL  confirmed delete: $out"; FAILURES=$((FAILURES + 1)); fi

# A controller carries its action's name, not the feature's: the same request always names it the same way.
expect "a controller named with the feature's name fails" "printf 'namespace Client.Shop\n{ class ShopOpenOfferController { } }\n' > ShopMain/ShopOpenOfferController.cs; sed -i.bak 's|^Open questions:|  ShopMain/ShopOpenOfferController.cs\\
Open questions:|' ../../../Logs/ai/plan.md" "CHK-14"
expect "a controller named for its action passes" "printf 'namespace Client.Shop\n{ class OpenOfferController { } }\n' > ShopMain/OpenOfferController.cs; sed -i.bak 's|^Open questions:|  ShopMain/OpenOfferController.cs\\
Open questions:|' ../../../Logs/ai/plan.md" ""

[ "$FAILURES" -eq 0 ] && echo "All passed." || echo "$FAILURES failed."
exit $(( FAILURES > 0 ))
