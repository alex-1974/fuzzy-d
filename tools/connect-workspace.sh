#!/usr/bin/env bash
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
workspace=${WORKSPACE_ROOT:-"$HOME/Programmiersprachen/dlang/d-geospatial-workspace"}

docs=(
    README.md
    ROADMAP.md
    DESIGN_PRINCIPLES.md
    DLANG_PRACTICES.md
    RESEARCH.md
    QUALITY_GATES.md
    GIT_GITHUB_WORKFLOW.md
    REPOSITORY_STANDARD.md
    TOOLCHAIN_ISSUES.md
)

test -d "$workspace" || { echo "Missing workspace: $workspace" >&2; exit 1; }
for doc in "${docs[@]}"; do
    test -f "$workspace/$doc" || { echo "Missing canonical document: $workspace/$doc" >&2; exit 1; }
done

mkdir -p -- "$here/.workspace"
for doc in "${docs[@]}"; do
    source_file="$workspace/$doc"
    target_file="$here/.workspace/$doc"
    if test -e "$target_file"; then
        if ! test "$source_file" -ef "$target_file"; then
            echo "Refusing to replace divergent context file: $target_file" >&2
            exit 1
        fi
    else
        ln -- "$source_file" "$target_file"
    fi
done

echo "PASS: ${#docs[@]} canonical workspace documents linked into $here/.workspace"
echo "These are hardlinks; no normative copies were created."
