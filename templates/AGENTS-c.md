# AGENTS.md — instructions for agents working in this repo

Dart/Flutter project, Topology C (single-package repo). Conforms to the
[Dart/Flutter Bible](https://github.com/taybiz/dart-flutter-bible) — everything
below is this repo's deviations + local wiring only; the doctrine is linked, not
restated (bible §1.3 D.R.Y.).

## Reading order

- Read the bible compact blob first: `docs/00-compact.md` (link or vendored copy).
- Topology C specifics: bible §3.3 (a single package is still a melos workspace root).
- If this file contradicts the bible, the bible wins until changed by proposal.

## Layout (Topology C)

`<thing_package>/` — a single package that **is** the workspace root. No
`workspace:` list, no `melos.yaml`; the `melos:` key lives in this `pubspec.yaml`.
That buys the tool belt: `melos run <task>` (one CI entry point) plus the release
flow (`melos version` → the changelog + tag, `melos publish`).

```yaml
name: <thing_package>
version: 0.1.0
environment:
  sdk: '>=3.10.0 <4.0.0'
dev_dependencies:
  melos: ^8.8.0
melos:
  useRootAsPackage: true
  scripts:
    analyze: dart analyze --fatal-infos --fatal-warnings
    test: dart test
```

Notes: keep publishable metadata (`version`, `repository`, `topics`) on the root
package — being a workspace root changes nothing that ships to pub.dev. `melos bootstrap`
writes `melos_<thing_package>.iml` into the root, so add `*.iml` to `.gitignore`.
Release tag is a plain `vX.Y.Z`, not package-prefixed.

## Deviations from the bible (rare — keep this list empty unless deliberate)

- _None yet._

## Housekeeping

- CI entry point: `dart run melos run <task>` (CI calls the script contract, never raw commands).
- Clean before committing: `dart analyze --fatal-infos --fatal-warnings` (**zero
  diagnostics of any severity**), `dart test`.
- Error style is the bible default: `Future<Either<F, T>>`. If this repo deviates, **say so here**.
