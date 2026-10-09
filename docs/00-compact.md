> ⚠️ **BOT-ONLY FILE — humans, stay out.**
> This is the compact, token-cheap ingest blob for agents. **Do not hand-edit it.**
> Edit the human docs (`docs/01`–`docs/13`), then regenerate this blob
> (ask an agent: "regenerate docs/00-compact.md from the other docs/ files").
> The full sections are authoritative; this blob is derived and drifts the moment it's hand-edited.

# DART/FLUTTER BIBLE — COMPACT (bot ingest)

## IDENTITY
- Repo: taybiz/dart-flutter-bible. Authoritative. License: MIT.
- Framing: "our standard — open to change by proposal", not "the law".

## RULES (non-negotiable)
- Bulls-eye clean architecture: entities at center; dependencies point INWARD; flow one direction UI -> usecase -> repository -> datasource.
- Exceptions ONLY at the UI ring. Everywhere else, failure is a VALUE.
- fpdart ALWAYS: Either (sync), TaskEither (async), Option (absence). Pin ^1.2.0; NEVER 2.0-dev (Effect rewrite, pre-release). Public seam = `Future<Either<F,T>>`; `.run()` at the public method boundary inside the layer (TaskEither is internal composition; consumers never build/run chains).
- equatable on every entity/value object: immutable, const constructors, props list.
- Failures: sealed hierarchies PER LAYER (domain / datasource). Datasource failures mapped upward at the repository. switch over failures is exhaustive.
- tryCatch ONLY at adapter boundaries, converting third-party exceptions -> Left. Adapter boundary = a LINE not a zone: only `TaskEither.tryCatch`/`Either.tryCatch` wrapping the third-party call itself; hand-rolled try/catch inside adapters = VIOLATION. No throw/try/catch in domain or usecases.
- AT-LEAST-TWO REPOSITORY ADAPTER RULE: every repository contract gets >=2 repository adapters + a shared contract suite run against ALL of them.
- ERROR STYLE IS DECLARED, LOUDLY: every package says whether consumers get FP-style tuples (Either/TaskEither) or plain exceptions — in the barrel doc comment, the README, and (if it deviates from the Future<Either> default) its AGENTS.md. Silence is the violation, never the choice.
- WIDGETS -> USECASES ONLY: no widget imports repository, datasource, or entity factory; providers wrap use cases.
- melos.yaml = BAD SMELL (deleted in melos 7.0.0). Native pub workspaces are the base; melos is OPTIONAL (single-package script runner only).
- SDK constraint: '>=3.10.0 <4.0.0' in every pubspec.
- One class per file; ONE hand-written barrel per package (`lib/<pkg>.dart` re-exports `lib/src/`; never import `src/` across packages). dart format / dart analyze / dart test only. Dart-first editing: no Python/sed rewriting .dart files.
- TERSE DOCS: `///` on declarations and their public members (1-2 lines, what+why, never how) — **never as a file header** (file-level `///` requires a `library;` — barrels only) — dartdoc/pub.dev-ready; `public_member_api_docs` lint ON. Use cases MUST be documented.
- PARAMS: usecase/repo methods take DISCRETE business params (id, userName, ...), never cargo objects (AddUserUseCase(UserBlockOfStuff) = NO). Dart: named params except single positional `ref`/`message`/`value`; Flutter follows Flutter.
- ENFORCEMENT: lint-enforced (analyze gate) = public_member_api_docs + implementation_imports (default-on); TEST-enforced (dart test gate) = package-boundary direction + cycle-free via dart_arch_test (resolved import graph); review-enforced (§10) = cargo params, barrel freshness. Don't invent lints for taste rules. CLEAN = ZERO diagnostics of ANY severity (errors+warnings+infos); gate = dart analyze --fatal-infos --fatal-warnings; todo:error in analysis_options (roadmap doc, not code comments); ignores per-line only, never ignore_for_file/blanket.
- CODE PLACEMENT: tests FIRST for example code; `example/` (SINGULAR — pub.dev builds its Example tab from `example/`) only for packages or genuine need (e.g., core facade for GUI implementers); never READMEs/prose; doctrine docs carry tight snippets only.
- D.R.Y.: single source of truth — doctrine lives HERE; project READMEs/AGENTS.md reference rules, never restate them (a second copy is a second truth). Repo AGENTS.md = that repo's deviations + local wiring only; READMEs orient, carry no rules/architecture. BACKLOG = terse queue (one unique actionable item each, automation-pick-able), not a warstory/metanarrative diary; keen decisions live in CHANGELOG; keep-your-footing knowledge in AGENTS.md.

## STACK (pinned)
- fpdart ^1.2.0 (pinned; 2.0-dev is off-limits) · equatable latest stable major (3.x today; NOT pinned — a pin means a documented exclusion, never a snapshot) · shouldly (assertions, "should be" idiom) · mocktail (mocks, usecase seam only) · drift + drift_dev + build_runner (sqlite3 ORM; SANCTIONED codegen) · sembast (pure-Dart file store) · flutter_riverpod (plain providers) · go_router (nav). Dev/tests: dart_arch_test (architecture/boundary tests). Optional: melos ^8.8.0 (single-package scripts only).

## BANNED
- freezed, json_serializable, riverpod_generator, retrofit, get_it/injectable, raw sqlite3 without drift.
- throw/try/catch inside domain/usecases. expect() mixed with shouldly. Any builder except drift. melos.yaml files.

## WORKSPACE / BOUNDARIES
- Root pubspec: `workspace:` lists every package; each sets `resolution: workspace`; `dart pub get`. Workspaces are per-repo; they do NOT span repos.
- melos is OPTIONAL — best as a single-package script runner (root `useRootAsPackage: true`); do NOT use workspace orchestration over piles of unpublished packages (breaks hard, enforces no boundaries).
- Boundaries: `dart_arch_test` test = CI HARD gate for package-boundary direction + cycle-free (real analyzer resolution over the WHOLE workspace, package: URIs; write PLAIN package: URI assertions for direction — the glob DSL strips package names and is blind across members). Root for buildGraph = Directory.current + walk-up to `workspace:` pubspec (NEVER Platform.script — kernel dir → empty graph → vacuously green). import_rules optional/as-you-type only (reads imports only, misses workspace members). melos.yaml still banned (deleted in 7.0.0; 8.x uses root `melos:` key if opted in — `exec.command` per-package since 8.0.0; `melos analyze` floor ^8.8.0).

## TOPOLOGY
- A) One workspace repo — small / single-delivery (CLI only). B) Core repo (domain + usecases + datasource adapters + CLI, pure Dart, NO Flutter) + separate UI repo (Flutter; git dep on core + dependency_overrides for dev; platform bits like path_provider resolved in UI composition root). C) Single-package repo — STILL a melos workspace: the package is the workspace root (`melos: useRootAsPackage: true`), scripts in its own pubspec, no melos.yaml; that buys `melos run` plus the `melos version`/`melos publish` release flow.
- The application layer (use cases) IS the facade — one seam served by CLI and UI alike. Optional thin facade class = wiring convenience only, never a logic layer.

## PERSISTENCE
- sqlite3 -> drift. Tests: NativeDatabase.memory().
- File store -> sembast. Tests: databaseFactoryMemory.
- UnitOfWork: write methods take optional `IUnitOfWork? uow` (reads MIGHT take one); transactional adapters (drift/sembast/isar) wrap real transactions, others gracefully sink (NoOp/best-effort). Contract stays uniform. PITFALLS: keep native client on the txn for the WHOLE work() run (await work() inside the txn callback — resetting early deadlocks); a many-store wipe is ONE UoW or it isn't atomic; provider invalidation is NOT a wipe (persistent rows survive — regression-test with real adapter in memory mode).
- Repository + datasource CONTRACTS live in the domain package. Repos orchestrate/validate; datasources do mechanical I/O. Contract tests live in core, never the UI repo.

## TESTING
- shouldly: `x.should.be(...)`; never mix expect(). Names: Given/When/Then.
- Layer matrix: domain = unit, no mocks; usecases = mocktail on interfaces we own; adapters = real in-memory doubles; contract suite on every adapter; widget tests at UI.
- Every usecase test covers BOTH Either sides (Right happy path + each Left).
- PITFALLS: fpdart `isRight()`/`isLeft()` are METHODS (never property); no `beTrue`/`beFalse` in shouldly — use `be(true)`/`be(false)` (pin shouldly ^0.5.0+1); `getOrElse`/`fold` callbacks take the Left value (`(_) =>`, never `() =>`); no absolute paths in tests (HOME env or systemTemp + path pkg); extract Right via `getOrElse` after asserting `isRight()`; fpdart chains are LAZY — nothing runs until `.run()`, never mutate a captured list inside a lazy callback and iterate it eagerly (thread through the chain).

## FLUTTER
- Riverpod plain providers, NO generator. Manual constructor injection; composition root in the app.
- **Riverpod NEVER enters the core** — zero `flutter_riverpod` in domain/usecases/datasources; core stays pure Dart, headless-buildable. If a core package "needs" a provider, the design is wrong (use case is the seam).
- Widget job: call usecase -> render state. Exceptions caught at the boundary, converted to UI state, never swallowed.
- PITFALL: don't move a widget under a stationary cursor if you rely on MouseRegion.onExit (flutter/flutter#44957 — onExit silently dropped in ListView; keep the button stationary, render warnings below).

## BOOTSTRAP (new project)
1 read compact (or full) bible; 2 root pubspec with workspace: (no melos.yaml; melos optional); 3 packages: domain / usecases / 2 datasource adapters / app; 4 resolution: workspace + dart pub get; 5 contracts first (entities, failures, I*Repository, datasource interfaces); 6 at least two repository adapters + contract suite from day one; 7 dart_arch_test boundary test (onion + cycle-free) as part of dart test; 8 lints incl. public_member_api_docs + todo:error; dart analyze --fatal-infos --fatal-warnings clean (ZERO diagnostics of any severity); 9 first usecase (documented, business-param call, named params) + both-sides test; 10 CI runs analyze + test (boundary included) every PR.

## REVIEW (checklist)
- Inward dependencies (dart_arch_test boundary, not melos)? Throw/try/catch outside UI ring? Entities immutable + equatable? >=2 repository adapters + contract suite? Failure layers mapped, no leakage? Error style declared (tuples vs exceptions)? drift the only ORM? Unapproved builders? shouldly only, GWT names, both Either sides? No melos.yaml (melos single-package scripts only)? analyze (fatal flags) + test green (boundary included), ZERO diagnostics any severity? No TODO/FIXME (roadmap doc)? Ignores per-line only? Public API documented (<=2 lines, use cases included)? Params business-shaped, no cargo? Named params (except ref/message/value)? One barrel per package, no src/ imports? D.R.Y. (no restated rules in READMEs/AGENTS/comments; BACKLOG a terse queue, not a warstory diary)?

## CONFIG & SETTINGS (§13)
- CLI/TUI apps must support 3-layer config precedence: (1) `--config`/`-c` flag trumps all, (2) env vars, (3) default config file. The `--config` flag is the *only* hard-error path (file missing → exit non-zero).
- Default config path follows OS conventions: Linux `$XDG_CONFIG_HOME/<app>/config` or `$HOME/.config/`, macOS `~/Library/Application Support/`, Windows `%APPDATA%\<app>\config`.
- YAML default format (`package:yaml`); schema documented in README with a `config.example.yaml` in the repo.
- Read sources in reverse precedence order (default → env → explicit) and merge; absent sources skip, never crash.
- Distinguish config (startup, hand-edited, one-shot) from app settings (runtime, UI-managed, reactive). Secrets never in config files → env vars or platform secret stores.
- CI-gated: tests prove every precedence layer (env trumps default, `--config` trumps env, missing `--config` exits non-zero).

## DECISIONS (settled; §11 = human change record, doctrine wins)
- Error style: declared per package (barrel + README + AGENTS.md on deviation); FP-style tuples are the default, plain exceptions only at the UI ring.
- State: Riverpod (plain providers). DI: manual constructor injection. Nav: go_router. JSON codegen: banned for now. License: MIT. Wiki: auto-synced by wiki-sync GitHub Action on every push to main.
- Melos: OPTIONAL, single-package script runner only. Package boundaries: dart_arch_test test (resolved import graph). import_rules is not the gate.
- Docs: terse `///` on declarations and their members (1-2 lines, what+why), **never as a file header** (file-level `///` requires a `library;` — barrels only); public_member_api_docs ON; use cases documented. Params: named except single positional ref/message/value; usecase call() = discrete business params, never cargo objects. Barrels: one hand-written per package (lib/<pkg>.dart), never import src/ across packages. Flutter follows Flutter conventions.

## LINKS
- Repo: https://github.com/taybiz/dart-flutter-bible · Wiki: https://github.com/taybiz/dart-flutter-bible/wiki
- Examples: `example/` — bible_samples package, CI-tested (dart analyze --fatal-infos --fatal-warnings + dart test on every push)
- Full docs: docs/01-architecture.md .. docs/13-config-and-settings.md (this blob = docs/00-compact.md)
