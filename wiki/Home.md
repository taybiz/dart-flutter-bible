# Dart/Flutter Bible

*How we build. Not a tutorial collection — this is our standard. If a tutorial, package README, or gut feeling conflicts with this document, the standard wins until it is changed. Standards change by proposal, not by drift: if the toolchain or the team shows a better way, update this document on purpose, and don't let the codebase quietly diverge.*

**Why this exists:** one architecture, one error-handling style, one testing idiom across every project means a developer who has seen one of our repos has seen them all — onboarding is faster, reviews are cheaper, and the bulls-eye keeps business logic testable and portable. This is the manual for how we do that on purpose.

## Contents

| Doc | Section |
|---|---|
| [00 — Compact](https://github.com/taybiz/dart-flutter-bible/blob/main/docs/00-compact.md) | Bot-only ingest blob — **do not hand-edit**; regenerate from the human docs |
| [01 — Architecture](Architecture) | The bulls-eye, the four laws, the at-least-two-repository-adapter rule |
| [02 — Toolchain](Toolchain-and-Melos) | SDK range, pub workspaces, melos as the script contract, `dart_arch_test` for boundaries |
| [03 — Repository Topology](Repository-Topology) | One-workspace repo vs core-repo + UI-repo vs single-package repo; the application layer as facade |
| [04 — Functional Core](Functional-Core) | fpdart, typed failures, equatable, no exceptions inside the bulls-eye |
| [05 — Persistence](Persistence) | Drift for sqlite3, sembast for file stores, contract suites, in-memory testing |
| [06 — Testing](Testing) | shouldly "should be" idiom, Given/When/Then, mocktail, layer matrix |
| [07 — Builders & Codegen](Builders-and-Codegen) | Avoid, except drift — sealed classes + records over freezed |
| [08 — Flutter Ring](Flutter-Ring) | Widgets talk only to use cases; exceptions live here and only here |
| [09 — Bootstrap Checklist](Bootstrap-Checklist) | New project, from workspace to green CI |
| [10 — Review Checklist](Review-Checklist) | The questions every review answers |
| [11 — Decisions & Roadmap](Decisions-and-Roadmap) | Settled doctrine (state management, DI, navigation) + roadmap |
| [12 — Sources of Truth](Sources-of-Truth) | Canonical packages and docs |
| [13 — Config & Settings](Config-and-Settings) | CLI/TUI config precedence, env, defaults |
| [Repo-doc templates](templates/README.md) | Copyable AGENTS/queue/CHANGELOG/README scaffolds per topology |

## Wiki

A rendered copy of these docs lives in the [project wiki](https://github.com/taybiz/dart-flutter-bible/wiki).

The wiki is generated from `docs/` and **shipped as code**: `scripts/sync-wiki.sh --render wiki` writes the pages into `wiki/`, which is committed and gate-checked for freshness. Publishing copies that tree into the GitHub wiki (`scripts/sync-wiki.sh`) — there is no hosted GitHub Action; the pipeline is ours (bible §2.10).

## License

MIT — see [LICENSE](https://github.com/taybiz/dart-flutter-bible/blob/main/LICENSE).

---
[Back to the repo](https://github.com/taybiz/dart-flutter-bible)
