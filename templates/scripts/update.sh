#!/usr/bin/env bash
# Updates the rules in one command: gets the latest .ai from GitHub, then refreshes the files install.sh copied
# to the project root. With the enforcement package (.ai-enforcement), it runs its install too, which regenerates
# the AI context for the new rules. PROJECT_RULES.md is never touched.
#
# Usage, from the project root (the folder that holds Assets and .ai):
#   bash .ai/templates/scripts/update.sh
set -u

# Everything runs from this function, which bash reads in full before running it,
# so the script keeps working while the update replaces this file.
main() {
    local ai_dir root before after
    ai_dir="$(cd "$(dirname "$0")/../.." && pwd)"
    root="$(cd "$ai_dir/.." && pwd)"

    if ! git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
        echo "$root isn't a Git repository, so .ai can't be updated as a submodule."
        exit 2
    fi

    before="$(git -C "$ai_dir" rev-parse --short HEAD 2>/dev/null)"
    echo "Getting the latest rules..."
    if ! git -C "$root" submodule update --init --remote .ai; then
        echo "Couldn't update .ai. Check your connection, and that .ai has no local changes (git -C .ai status)."
        exit 1
    fi
    after="$(git -C "$ai_dir" rev-parse --short HEAD)"

    if [ "$before" = "$after" ]; then
        echo "The rules are already up to date ($after)."
    else
        echo "Rules updated: $before -> $after. What changed: .ai/CHANGELOG.md"
    fi
    echo

    # Runs the install script of the new version. With the enforcement package, its install runs too: it refreshes
    # the AI wiring and copies, and regenerates the AI context (Logs/ai/) for the new rules.
    # (The enforcement's install runs this package's install first, so it isn't run twice.)
    local status
    if [ -f "$root/.ai-enforcement/templates/scripts/install.sh" ]; then
        bash "$root/.ai-enforcement/templates/scripts/install.sh" --update
    else
        bash "$ai_dir/templates/scripts/install.sh" --update
    fi
    status=$?

    if [ "$before" != "$after" ]; then
        echo
        echo "Commit the update: git add . && git commit -m \"Update Unity Architecture to $after\""
    fi
    exit $status
}

main "$@"
