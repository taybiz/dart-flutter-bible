# 11. Decisions — Change Record

Doctrine lives in §1–§10 — that is the single source of truth. This section only records *that* a decision was settled, *where* it is written down, and *why*. It is deliberately not a parallel doctrine index; if a section changes, the doctrine wins and this table points at the new reality.

### 11.1 Settled

| Decision | Documented in | Why |
|---|---|---|
| Riverpod, plain providers, no generator | §8 Flutter Ring | Codegen-free state; manual wiring keeps the no-builders rule intact |
| Manual constructor injection (no get_it/injectable) | §8 Flutter Ring | Codegen-free; composition root in the app |
| go_router for navigation | §8 Flutter Ring | Boring, one file, works |
| drift for sqlite3 (only sanctioned builder) | §5 Persistence, §7 Builders | Typed ORM; testable with `NativeDatabase.memory()` |
| shouldly + mocktail, Given/When/Then names | §6 Testing | "should be" idiom; mocks only at the use-case seam |
| fpdart ^1.2.0 pinned everywhere | §4 Functional Core | Failure is a value; 2.0-dev is a pre-release Effect rewrite |
| Terse `///` on declarations and members; never a file header (barrels only) | §2 Toolchain | dartdoc/pub.dev-ready; `public_member_api_docs` gates it; file-level `///` requires `library;` — that's for barrels |
| Use-case `call()` takes discrete business params | §4 Functional Core | Signature is the documentation; no cargo objects |
| Named params (sole exceptions: `ref`/`message`/`value`); Flutter follows Flutter | §2 Toolchain | Readable call sites; don't fight the framework |
| One hand-written barrel per package | §2 Toolchain | `src/` is private; what's exported *is* the public API |
| UnitOfWork | §5 Persistence | Optional `IUnitOfWork? uow` on write methods; reads may take one too; adapters wrap real transactions or gracefully sink |
| fpdart termination | §4 Functional Core | Public seam **defaults** to `Future<Either<F,T>>` (`.run()` inside the layer); a package may present the unrun `TaskEither` when it declares the style (§4.9), which the consumer then runs; consumers never compose chains across a seam |
| Error style is declared, never inferred | §4 Functional Core | Two styles are in the estate (FP-style tuples, plain exceptions); the consumer must be told which one they hold. Named in the barrel, the README, and — on any deviation — `AGENTS.md`. Silence is the violation, not the choice |
| Riverpod never in core | §8 Flutter Ring | Core = pure Dart, zero `flutter_riverpod`; providers wrap use cases in the UI ring only |
| Code placement | §2 Toolchain | Tests first; `example/` (singular — pub.dev convention) for packages or genuine need (e.g., core facade for GUI); never READMEs/prose |
| Lint-enforced vs review-enforced split | §2 Toolchain | Self-enforce what's automatable; taste rules stay in review |
| D.R.Y. — single source of truth; project docs (README/AGENTS.md) reference doctrine, never restate it; repo docs hold separate jobs (BACKLOG = terse queue, CHANGELOG = keen decisions & why, AGENTS.md = operational keep-your-footing) | §1 Architecture, §10 Review | A second copy is a second truth; READMEs drift the moment doctrine changes; a backlog that reads like a diary is unreadable by automation |
| Melos is **required** as the canonical script contract — `melos run` is the one entry point CI and agents call; it never enforces package boundaries (`dart_arch_test` does) | §2 Toolchain | One command, one behavior; per-package cwd/flags; codegen ordering; script-rot detection; release flow. Workspace orchestration over piles of unpublished packages still breaks — melos is a script runner, not an orchestrator. `melos analyze` floor is ^8.8.0 |
| melos 8 (`^8.8.0`) and the `exec.command` script schema | §2 Toolchain | 7.0.0 deleted `melos.yaml`; 8.0.0 broke the per-package script shape and shipped with no `melos analyze` command (restored 8.1.0, tightened to `--fatal-infos` in 8.2.0) |
| Single-package repos may still run melos | §3 Topology (C), §2 Toolchain | The package *is* the workspace root (`melos: useRootAsPackage: true`); keeping melos there buys `melos run` and the changelog/tag/publish flow |
| GUI testing gate: deterministic `integration_test` in CI; marionette_flutter (debug-only binding) + marionette_mcp as the dev-time agent layer, never the gate | §6 Testing, §8 Flutter Ring | An agent deciding what to tap is never a repeatable gate; `integration_test` is. Marionette stays GUI-ring-only and debug-only |

### 11.2 Proposals

_None open. Propose in a PR; when settled, add a row to the table above and update the section it documents._

### 11.3 Roadmap

- **Team promotion:** this bible is destined for a team-facing git wiki. Vault doc stays canonical; the wiki is a published rendering.
