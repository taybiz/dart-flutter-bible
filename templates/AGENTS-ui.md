# AGENTS.md — instructions for agents working in this repo

Topology B **UI repo** (`<thing>_flutter`). Conforms to the
[Dart/Flutter Bible](https://github.com/taybiz/dart-flutter-bible) — this file is
this repo's deviations + local wiring only, never a restatement of doctrine (§1.3).

## Reading order

- Read the bible compact blob first: `docs/00-compact.md` (link or vendored copy).
- Read the core repo's `AGENTS.md` — it owns the domain/usecases/datasources the UI depends on.
- Topology B: bible §3.2 (core + UI split), §3.4 (the application layer is the facade).
- If this file contradicts the bible, the bible wins until changed by proposal.

## What this repo is

Widgets **only**. It depends on `<thing_core>` via git dependency (`dependency_overrides`
→ local core checkout during cross-repo dev). No domain, no use cases, no datasource
implementations, no contract tests live here — those are core's job; this repo tests
its own boundary (providers, widgets).

## Composition root (the one place everything gets wired)

`lib/main.dart` resolves platform bits (`path_provider`, `sqlite3_flutter_libs`) and
injects adapters into providers here — **never** below the widget layer.

- Widgets call use cases; they never import repository, datasource, or entity factories.
- Exceptions are caught **at this boundary** and converted to UI state — never swallowed.
- Core stays headless-buildable: zero `flutter_riverpod` in core (bible §8).

## Housekeeping

- GUI gate is the integration test in CI, not just widget tests: `flutter test integration_test/...`.
- `MarionetteBinding` init is `kDebugMode` **only**; `marionette_mcp` is a dev tool,
  never a release app dependency.
- Contract suites never live here — they are core's (bible §1.2).
