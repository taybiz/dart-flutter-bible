# AGENTS.md — instructions for agents working in this repo

Dart/Flutter project, Topology B (core repo + UI repo). Conforms to the
[Dart/Flutter Bible](https://github.com/taybiz/dart-flutter-bible) — everything
below is this repo's deviations + local wiring only; the doctrine is linked, not
restated (bible §1.3 D.R.Y.).

This file sits in the **core** repo. The UI repo gets its own AGENTS.md
(`templates/AGENTS-ui.md`) that mirrors the local-wiring rule below.

## Reading order

- Read the bible compact blob first: `docs/00-compact.md` (link or vendored copy).
- Topology B specifics: bible §3.2 (core + UI split), §3.4 (the application layer is the facade).
- If this file contradicts the bible, the bible wins until changed by proposal.

## Layout (Topology B)

`<thing_core>` — **pure Dart, no Flutter anywhere.** Headless-buildable; drift
(NativeDatabase) and sembast run on the Dart VM, so adapters + the contract
suite live and run in core CI with no device.
- `<thing_core>/` root `pubspec.yaml` (`workspace:` + `melos:`; **no melos.yaml**)
  - `packages/`
    - `<thing>_domain/` — entities, value objects, repository & datasource **contracts**, failures
    - `<thing>_usecases/` — application layer = the shared facade (CLI + UI consume this one seam)
    - `<thing>_datasource_drift/` — adapter 1 (sqlite via drift, headless NativeDatabase)
    - `<thing>_datasource_sembast/` — adapter 2 (file store) *(or in-memory)*
    - `<thing>_datasource_memory/` — adapter 3 (test double + contract verification)
    - `<thing>_cli/` — CLI delivery mechanism; sibling of the UI, not its parent

The UI repo (`<thing>_flutter`, separate) consumes this core via **git dependency**
(dependency_overrides → local core checkout during cross-repo dev). Contract tests
live in core, **never** in the UI repo. Platform bits (`path_provider`, `sqlite3_flutter_libs`)
resolve in the UI's composition root, never in core packages.

## Deviations from the bible (rare — keep this list empty unless deliberate)

- _None yet._

## Housekeeping

- CI entry point: `melos run <task>` from the core workspace root.
- Clean before committing: `dart analyze --fatal-infos --fatal-warnings` (**zero
  diagnostics of any severity**), `dart test` (includes the `dart_arch_test` boundary test).
- Error style is the bible default: `Future<Either<F, T>>`. If this repo deviates, **say so here**.
