# Dart/Flutter Bible

*How we build. Not a tutorial collection — this is our standard. If a tutorial, package README, or gut feeling conflicts with this document, the standard wins until changed. Standards change by proposal, not by drift: if the toolchain or the team shows a better way, update this document on purpose — never let the codebase quietly diverge.*

**Why this exists:** one architecture, one error-handling style, one testing idiom across every project means a developer who has seen one of our repos has seen them all — onboarding is faster, reviews are cheaper, and the bulls-eye keeps business logic testable and portable. This is the manual for how we do that on purpose.

## Contents

| Doc | Section |
|---|---|
| [00 — Compact](docs/00-compact.md) | Bot-only ingest blob — **do not hand-edit**; regenerate from the human docs |
| [01 — Architecture](docs/01-architecture.md) | The bulls-eye, the four laws, the at-least-two-repository-adapter rule |
| [02 — Toolchain & Melos](docs/02-toolchain.md) | SDK range, melos 8 + pub workspaces (`melos.yaml` is a bad smell) |
| [03 — Repository Topology](docs/03-topology.md) | One-workspace repo vs core-repo + UI-repo vs single-package repo (still melos); the application layer as facade |
| [04 — Functional Core](docs/04-functional-core.md) | fpdart, typed failures, equatable, no exceptions inside the bulls-eye |
| [05 — Persistence](docs/05-persistence.md) | Drift for sqlite3, sembast for file stores, contract suites, in-memory testing |
| [06 — Testing](docs/06-testing.md) | shouldly "should be" idiom, Given/When/Then, mocktail, layer matrix |
| [07 — Builders & Codegen](docs/07-builders.md) | Avoid, except drift — sealed classes + records over freezed |
| [08 — Flutter Ring](docs/08-flutter-ring.md) | Widgets talk only to use cases; exceptions live here and only here |
| [09 — Bootstrap Checklist](docs/09-bootstrap-checklist.md) | New project, from workspace to green CI |
| [10 — Review Checklist](docs/10-review-checklist.md) | The questions every review answers |
| [11 — Decisions & Roadmap](docs/11-decisions.md) | Settled doctrine (Riverpod, DI, navigation) + roadmap |
| [12 — Sources of Truth](docs/12-sources.md) | Canonical packages and docs |

## Wiki

A rendered copy of these docs lives in the [project wiki](https://github.com/staylorx/dart-flutter-bible/wiki).

The wiki is **auto-synced from `docs/` on every push to `main`** by the `wiki-sync` GitHub Action (`.github/workflows/wiki-sync.yml`) — no manual step needed. To sync manually anyway: `bash scripts/sync-wiki.sh`.

## License

MIT — see [LICENSE](LICENSE).
