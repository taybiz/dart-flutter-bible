# AGENTS.md — instructions for agents working in this repo

Dart/Flutter project, Topology A (one workspace repo). Conforms to the
[Dart/Flutter Bible](https://github.com/taybiz/dart-flutter-bible) — everything
below is this repo's deviations + local wiring only; the doctrine is linked, not
restated (bible §1.3 D.R.Y.).

## Reading order

- Read the bible compact blob first: `docs/00-compact.md` (link or vendored copy).
  It is the token-cheap bot ingest for all doctrine rules.
- If this file contradicts the bible, the bible wins until changed by proposal.

## Layout (Topology A)

- `<project>` /: workspace root `pubspec.yaml` (`workspace:` + `melos:` scripts; **no melos.yaml**)
  - `packages/`
    - `<thing>_domain/` — entities, value objects, repository & datasource **contracts**, failures
    - `<thing>_usecases/` — application layer (use cases = the facade)
    - `<thing>_datasource_drift/` — adapter 1 (sqlite via drift)
    - `<thing>_datasource_sembast/` — adapter 2 (file store) *(or in-memory adapter)*
    - `<thing>_datasource_memory/` — adapter 3 (test double + contract verification)
  - `apps/<thing>_flutter/` — UI ring; **the only place exceptions live**

## Deviations from the bible (rare — keep this list empty unless deliberate)

- _None yet._

## Housekeeping

- CI entry point: `melos run <task>` (`analyze`, `test`, …) from the workspace root.
- Clean before committing: `dart analyze --fatal-infos --fatal-warnings` (**zero
  diagnostics of any severity**), `dart test` (includes the `dart_arch_test` boundary test).
- Error style is the bible default: `Future<Either<F, T>>`. If this repo deviates, **say so here**.
