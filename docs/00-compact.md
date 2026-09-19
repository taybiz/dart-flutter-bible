> ⚠️ **BOT-ONLY FILE — humans, stay out.**
> This is the compact, token-cheap ingest blob for agents. **Do not hand-edit it.**
> Edit the human docs (`docs/01`–`docs/12`), then regenerate this blob
> (ask an agent: "regenerate docs/00-compact.md from the other docs/ files").
> The full sections are authoritative; this blob is derived and drifts the moment it's hand-edited.

# DART/FLUTTER BIBLE — COMPACT (bot ingest)

## IDENTITY
- Repo: staylorx/dart-flutter-bible (fork of taybiz/dart-flutter-bible). Authoritative. License: MIT.
- Framing: "our standard — open to change by proposal", not "the law".

## RULES (non-negotiable)
- Bulls-eye clean architecture: entities at center; dependencies point INWARD; flow one direction UI -> usecase -> repository -> datasource.
- Exceptions ONLY at the UI ring. Everywhere else, failure is a VALUE.
- fpdart ALWAYS: Either (sync), TaskEither (async), Option (absence). Pin ^1.2.0; NEVER 2.0-dev (Effect rewrite, pre-release). Public seam = `Future<Either<F,T>>`; `.run()` at the public method boundary inside the layer (TaskEither is internal composition; consumers never build/run chains).
- equatable on every entity/value object: immutable, const constructors, props list.
- Failures: sealed hierarchies PER LAYER (domain / datasource). Datasource failures mapped upward at the repository. switch over failures is exhaustive.
- tryCatch ONLY at adapter boundaries, converting third-party exceptions -> Left. Adapter boundary = a LINE not a zone: only `TaskEither.tryCatch`/`Either.tryCatch` wrapping the third-party call itself; hand-rolled try/catch inside adapters = VIOLATION. No throw/try/catch in domain or usecases.
- AT-LEAST-TWO REPOSITORY ADAPTER RULE: every repository contract gets >=2 repository adapters + a shared contract suite run against ALL of them.
- WIDGETS -> USECASES ONLY: no widget imports repository, datasource, or entity factory; providers wrap use cases.
- melos.yaml = BAD SMELL (deleted in melos 7.0.0). Modern melos 8 + native pub workspaces.
- SDK constraint: '>=3.10.0 <4.0.0' in every pubspec.
- One class per file; ONE hand-written barrel per package (`lib/<pkg>.dart` re-exports `lib/src/`; never import `src/` across packages). dart format / dart analyze / dart test only. Dart-first editing: no Python/sed rewriting .dart files.
- TERSE DOCS: `///` on declarations and their public members (1-2 lines, what+why, never how) — **never as a file header** (file-level `///` requires a `library;` — barrels only) — dartdoc/pub.dev-ready; `public_member_api_docs` lint ON. Use cases MUST be documented.
- PARAMS: usecase/repo methods take DISCRETE business params (id, userName, ...), never cargo objects (AddUserUseCase(UserBlockOfStuff) = NO). Dart: named params except single positional `ref`/`message`; Flutter follows Flutter.
- ENFORCEMENT: lint-enforced (analyze gate) = public_member_api_docs + implementation_imports (default-on); review-enforced (§10) = cargo params, barrel freshness. Don't invent lints for taste rules. CLEAN = ZERO diagnostics of ANY severity (errors+warnings+infos); gate = dart analyze --fatal-infos --fatal-warnings; todo:error in analysis_options (roadmap doc, not code comments); ignores per-line only, never ignore_for_file/blanket.
- CODE PLACEMENT: tests FIRST for example code; `examples/` only for packages (pub.dev) or genuine need (e.g., core facade for GUI implementers); never READMEs/prose; doctrine docs carry tight snippets only.
- D.R.Y.: single source of truth — doctrine lives HERE; project READMEs/AGENTS.md reference rules, never restate them (a second copy is a second truth). Repo AGENTS.md = that repo's deviations + local wiring only; READMEs orient, carry no rules/architecture.

## STACK (pinned)
- fpdart ^1.2.0 · equatable ^2.x · shouldly (assertions, "should be" idiom) · mocktail (mocks, usecase seam only) · drift + drift_dev + build_runner (sqlite3 ORM; SANCTIONED codegen) · sembast (pure-Dart file store) · melos ^8.8.0 · flutter_riverpod (plain providers) · go_router (nav).

## BANNED
- freezed, json_serializable, riverpod_generator, retrofit, get_it/injectable, raw sqlite3 without drift.
- throw/try/catch inside domain/usecases. expect() mixed with shouldly. Any builder except drift. melos.yaml files.

## WORKSPACE / MELOS
- Root pubspec: `workspace:` lists packages; `melos:` key holds scripts. Every package sets `resolution: workspace`.
- Scripts: bare string / `run:` = the command once in the workspace root; `exec:` = once per package, and since melos 8 the command MUST be `exec.command:` (`run` + `exec` together = config error; melos 7 rejects the `exec.command` shape with `MissingScriptCommandException`). Pin melos ^8.8.0 — 8.0.0 has NO `analyze` command (falls through to a same-named script if you have one), restored in 8.1.0; 8.2.0+ defaults `melos analyze` to --fatal-infos.
- `melos bootstrap`, then `melos run <script>`. Workspaces are per-repo; melos does NOT span repos.
- A single-package repo is a workspace of one: package = workspace root, `melos: useRootAsPackage: true`, no `workspace:`/`resolution:` anywhere (§3 Topology C). `melos bootstrap` writes `melos_<package>.iml` into the root — keep `*.iml` gitignored or it ships in the published archive. CI calls `dart run melos run <script>`, never the raw command.

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
1 read compact (or full) bible; 2 root pubspec with workspace + melos keys (no melos.yaml); 3 packages: domain / usecases / 2 datasource adapters / app; 4 resolution: workspace + melos bootstrap; 5 contracts first (entities, failures, I*Repository, datasource interfaces); 6 at least two repository adapters + contract suite from day one; 7 lints incl. public_member_api_docs + todo:error; dart analyze --fatal-infos --fatal-warnings clean (ZERO diagnostics of any severity); 8 first usecase (documented, business-param call, named params) + both-sides test; 9 CI runs analyze + test.

## REVIEW (checklist)
- Inward dependencies? Throw/try/catch outside UI ring? Entities immutable + equatable? >=2 repository adapters + contract suite? Failure layers mapped, no leakage? drift the only ORM? Unapproved builders? shouldly only, GWT names, both Either sides? No melos.yaml? analyze (fatal flags) + test green, ZERO diagnostics any severity? No TODO/FIXME (roadmap doc)? Ignores per-line only? Public API documented (<=2 lines, use cases included)? Params business-shaped, no cargo? Named params (except ref/message)? One barrel per package, no src/ imports? D.R.Y. (no restated rules in READMEs/AGENTS/comments)?

## DECISIONS (settled; §11 = human change record, doctrine wins)
- State: Riverpod (plain providers). DI: manual constructor injection. Nav: go_router. JSON codegen: banned for now. License: MIT. Wiki: auto-synced by wiki-sync GitHub Action on every push to main.
- Docs: terse `///` on declarations and their members (1-2 lines, what+why), **never as a file header** (file-level `///` requires a `library;` — barrels only); public_member_api_docs ON; use cases documented. Params: named except single positional ref/message; usecase call() = discrete business params, never cargo objects. Barrels: one hand-written per package (lib/<pkg>.dart), never import src/ across packages. Flutter follows Flutter conventions.

## LINKS
- Repo: https://github.com/staylorx/dart-flutter-bible · Wiki: https://github.com/staylorx/dart-flutter-bible/wiki
- Examples: `examples/` — bible_samples package, CI-tested (dart analyze --fatal-infos --fatal-warnings + dart test on every push)
- Full docs: docs/01-architecture.md .. docs/12-sources.md (this blob = docs/00-compact.md)
