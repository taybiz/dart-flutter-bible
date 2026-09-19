# 3. Repository Topology & Package Layout

Deliverable types: **core** (pure-Dart library), **package** (published), **CLI**, **TUI**, **GUI**. Example-code policy depends on type — see §2 "Code placement".

The bulls-eye maps to repos. Three topologies are sanctioned; pick per project:

### Topology A — one workspace repo (small / pure-Dart projects)

Everything in one melos workspace, exactly as laid out below. Best when there is a single delivery mechanism (CLI only) or the team is small enough that one PR per change is a feature, not a bottleneck.

```
my_workspace/
├── pubspec.yaml                  # workspace + melos config (no melos.yaml!)
├── packages/
│   ├── thing_domain/             # entities, value objects, repository & datasource CONTRACTS, failures
│   ├── thing_usecases/           # application layer: use cases, orchestration
│   ├── thing_datasource_drift/   # adapter 1: sqlite3 via drift
│   ├── thing_datasource_sembast/ # adapter 2: sembast file store (or in-memory adapter)
│   └── thing_datasource_memory/  # adapter 3: in-memory (test double + contract verification)
└── apps/
    └── thing_flutter/            # UI ring — the only place exceptions live
```

### Topology B — core repo + UI repo (default when a core serves CLI **and** Flutter)

```
core/ (thing_core — pure Dart, no Flutter)
├── pubspec.yaml                  # workspace + melos config (no melos.yaml!)
└── packages/
    ├── thing_domain/             # entities, contracts, failures
    ├── thing_usecases/           # application layer = the shared facade
    ├── thing_datasource_drift/   # adapter 1 (runs headless on Dart VM)
    ├── thing_datasource_sembast/ # adapter 2 (pure Dart)
    ├── thing_datasource_memory/  # adapter 3 (test double + contract verification)
    └── thing_cli/                # CLI delivery mechanism — sibling of the UI

ui/ (thing_flutter — separate repo)
├── pubspec.yaml                  # depends on thing_core (git dep; path override in dev)
└── lib/
    ├── main.dart                 # composition root: wires adapters + providers
    └── ...                       # widgets only
```

Rules for Topology B:

- The core repo is **pure Dart**: no Flutter imports anywhere. Drift (`NativeDatabase`) and sembast run headless on the Dart VM, so both adapters **and the contract test suite** live and run in core CI without a device.
- The UI repo depends on the core via a **git dependency** (branch/tag); during cross-repo dev, `dependency_overrides` point at a local core checkout. Publishing the core to pub.dev is optional, only when outside teams consume it.
- Platform-specific concerns (`path_provider` paths, `sqlite3_flutter_libs`) are resolved in the UI repo's composition root and injected into adapters — never imported by core packages.
- Contract tests never live in the UI repo; they are core's job. The UI repo only tests its boundary (providers, widgets).
- Melos workspaces stay **per-repo** — melos does not span repos. That is the price of the split; the git dep + override workflow is how we pay it.

### Topology C — single-package repo (one library, one package, one delivery)

A repo that genuinely holds **one** package — a published package, or a pure-Dart library with a single delivery mechanism — is **still a melos workspace**. The package *is* the workspace root, so the config lives in its own `pubspec.yaml` and melos is a dev dependency. What that buys is the tool belt around the code: one place for the scripts CI calls, `melos run`, and the release flow (`melos version` for the changelog and tag, `melos publish`). A single-package repo does not drop melos to save a file.

```yaml
name: thing_package              # the package IS the workspace root
environment:
  sdk: '>=3.10.0 <4.0.0'
dev_dependencies:
  melos: ^8.8.0
melos:
  useRootAsPackage: true         # required: without it melos sees no packages
  scripts:
    analyze: dart analyze --fatal-infos --fatal-warnings
    test: dart test
```

Rules for Topology C:

- **`melos.yaml` is still a bad smell** (§2 Toolchain) — the `melos:` key in the pubspec is the configuration, and this topology has no `workspace:` list and no `resolution: workspace` anywhere.
- The root package keeps its publishable metadata (`version`, `repository`, `topics`, …). Being a workspace root changes nothing about what ships to pub.dev.
- `melos bootstrap` writes `melos_<package>.iml` into the root, so `*.iml` belongs in `.gitignore` or it rides into the published archive.
- CI calls the scripts (`dart run melos run analyze`), never the raw commands, so a script that rots fails the build instead of quietly passing.
- The release is a plain `vX.Y.Z` tag — package-prefixed tags are for workspace members.

### The application layer is the facade

The application layer (use cases) **is** the shared public face of the core — the one seam every delivery mechanism consumes:

- **CLI** (`thing_cli`): `CommandRunner` + composition root in `bin/`; commands call use cases directly. No use case is aware a CLI exists.
- **UI** (`thing_flutter`): providers wrap the same use cases. No use case is aware Flutter exists.
- A **facade** (a plain class composing use cases with chosen adapters) is optional convenience for wiring, never a new logic layer. If CLI and UI composition differ, skip the facade — the use cases are the API.

### Package rules

- **One class per file, one file per class.** Barrel exports (`lib/thing_domain.dart`) expose the public API.
- `thing_domain` depends on `equatable` + `fpdart` only. Nothing else. No Flutter, no I/O, no JSON package (hand-written serialization or none).
- `thing_usecases` depends on `thing_domain` + `fpdart`. No datasource implementations, no Flutter.
- `*_datasource_*` packages depend on `thing_domain` + their storage tech (drift, sembast).
- `thing_flutter` (the app) depends on use cases + datasource packages + `flutter_riverpod` (or chosen state mgmt — see Open Decisions). It wires adapters into the tree at composition root only.

---
