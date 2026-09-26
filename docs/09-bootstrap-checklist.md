# 9. Bootstrap Checklist (new project)

1. **9.1** — Read this bible. (No, really — read it.)
2. **9.2** — Scaffold the workspace: root `pubspec.yaml` with a `workspace:` list; **no `melos.yaml`** (melos is optional — §2).
3. **9.3** — Create packages: `*_domain`, `*_usecases`, two `*_datasource_*` packages (one of which may be in-memory), and the app package.
4. **9.4** — Set `resolution: workspace` in every package; `dart pub get`.
5. **9.5** — Define the domain contracts first (entities, failures, `I*Repository`, datasource interfaces). Nothing else until these compile.
6. **9.6** — Implement **at least two repository adapters** and the shared **contract test suite** from day one.
7. **9.7** — Add the **`dart_arch_test` boundary test** (§2) — package-aware assertions over the resolved import graph (direction) + cycle-freedom across the workspace. It runs as part of `dart test`, so the boundary is machine-checked before a cross-layer import can exist.
8. **9.8** — Wire `analysis_options.yaml` (lints, strict, **`public_member_api_docs`**, `todo: error`) at root; `dart analyze --fatal-infos --fatal-warnings` clean — **zero diagnostics of any severity** (errors, warnings, infos; §2).
9. **9.9** — Write the first use case — terse `///` docs (≤2 lines), business-param `call()`, named params — plus its mocktail test (both Either sides).
10. **9.10** — Commit. CI runs `dart analyze --fatal-infos --fatal-warnings` + `dart test` across every package (boundary test included) on every PR.
