# Repository Engineering Context

This repository is an independent fuzzy-logic library coordinated by the d-geospatial-workspace.

Before changing architecture, public API, numerical behavior, tests, CI, release configuration, repository structure or toolchain work, consult the relevant canonical workspace documents under .workspace/:

- .workspace/README.md
- .workspace/ROADMAP.md
- .workspace/DESIGN_PRINCIPLES.md
- .workspace/DLANG_PRACTICES.md
- .workspace/RESEARCH.md
- .workspace/QUALITY_GATES.md
- .workspace/GIT_GITHUB_WORKFLOW.md
- .workspace/REPOSITORY_STANDARD.md
- .workspace/TOOLCHAIN_ISSUES.md

The workspace root is authoritative. Do not duplicate normative workspace rules within this repository. Repository-specific design decisions belong in docs/ and must not silently contradict the shared contract.

If .workspace/ is unavailable (for example a standalone clone), do not invent workspace policy. Use tracked repository documentation and note that workspace context was unavailable.

For a local sibling checkout, run bash tools/connect-workspace.sh to expose the canonical documents as hardlinks; the .workspace directory is ignored by Git.

Do not reset, rename or reorganize active branches/worktrees merely to enforce a preferred standard. Initial bootstrap states and future transitions must be handled explicitly.

fuzzyD (historical) is a reference for ideas, not a source or package dependency.
