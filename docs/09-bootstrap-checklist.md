# 9. Bootstrap Checklist (new project)

1. **9.1** — Read this bible. (No, really — read it.)
2. **9.2** — Scaffold the workspace: root `pubspec.yaml` with `workspace:` + `melos:` keys; **no `melos.yaml`**.
3. **9.3** — Create packages: `*_domain`, `*_usecases`, two `*_datasource_*` packages (one of which may be in-memory), and the app package.
4. **9.4** — Set `resolution: workspace` in every package; `melos bootstrap`.
5. **9.5** — Define the domain contracts first (entities, failures, `I*Repository`, datasource interfaces). Nothing else until these compile.
6. **9.6** — Implement **at least two repository adapters** and the shared **contract test suite** from day one.
7. **9.7** — Wire `analysis_options.yaml` (lints, strict, **`public_member_api_docs`**, `todo: error`) at root; `dart analyze --fatal-infos --fatal-warnings` clean — **zero diagnostics of any severity** (errors, warnings, infos; §2).
8. **9.8** — Write the first use case — terse `///` docs (≤2 lines), business-param `call()`, named params — plus its mocktail test (both Either sides).
9. **9.9** — Commit. CI runs `melos run analyze` + `melos run test` on every PR.
