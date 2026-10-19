# 3. Repository Topology & Package Layout

Deliverable types: **core** (pure-Dart library), **package** (published), **CLI**, **TUI**, **GUI**. Example-code policy depends on type — see §2 "Code placement".

The bulls-eye maps to repos. Three topologies are sanctioned; pick per project:

### 3.1 Topology A — one workspace repo (small / pure-Dart projects)

Everything in one pub workspace, laid out as below. It fits a project with a single delivery mechanism (CLI only), or a team small enough that one PR per change is an advantage rather than a bottleneck.

```
my_workspace/
├── pubspec.yaml                  # workspace: (no melos.yaml!)
├── packages/
│   ├── thing_domain/             # entities, value objects, repository & datasource CONTRACTS, failures
│   ├── thing_usecases/           # application layer: use cases, orchestration
│   ├── thing_datasource_drift/   # adapter 1: sqlite3 via drift
│   ├── thing_datasource_sembast/ # adapter 2: sembast file store (or in-memory adapter)
│   └── thing_datasource_memory/  # adapter 3: in-memory (test double + contract verification)
└── apps/
    └── thing_flutter/            # UI ring — the only place exceptions live
```

### 3.2 Topology B — core repo + UI repo (default when a core serves CLI **and** Flutter)

```
core/ (thing_core — pure Dart, no Flutter)
├── pubspec.yaml                  # workspace: (no melos.yaml!)
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
- Pub workspaces stay **per-repo** — a workspace does not span repos. That is the price of the split; the git dep + override workflow is how we pay it.

### 3.3 Topology C — single-package repo (one library, one package, one delivery)

A repo that genuinely holds **one** package — a published package, or a pure-Dart library with a single delivery mechanism — is **still a melos workspace**. The package *is* the workspace root, so the config lives in its own `pubspec.yaml` and melos is a dev dependency. What that buys is the tool belt around the code: one place for the scripts CI calls, `melos run`, and the release flow (`melos version` for the changelog and tag, `melos publish`). A single-package repo keeps melos rather than dropping it to save a file.

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

- **`melos.yaml` is still a leftover** (§2 Toolchain) — the `melos:` key in the pubspec is the configuration, and this topology has no `workspace:` list and no `resolution: workspace` anywhere.
- The root package keeps its publishable metadata (`version`, `repository`, `topics`, …). Being a workspace root changes nothing about what ships to pub.dev.
- `melos bootstrap` writes `melos_<package>.iml` into the root, so `*.iml` belongs in `.gitignore` or it rides into the published archive.
- CI calls the scripts (`dart run melos run analyze`), never the raw commands, so a script that rots fails the build instead of quietly passing.
- The release is a plain `vX.Y.Z` tag — package-prefixed tags are for workspace members.

### 3.4 The application layer is the facade

The application layer (use cases) **is** the shared public face of the core — the one seam every delivery mechanism consumes:

- **CLI** (`thing_cli`): `CommandRunner` + composition root in `bin/`; commands call use cases directly. No use case is aware a CLI exists.
- **UI** (`thing_flutter`): providers wrap the same use cases. No use case is aware Flutter exists.
- A **facade** (a plain class composing use cases with chosen adapters) is optional convenience for wiring, never a new logic layer. If CLI and UI composition differ, skip the facade — the use cases are the API.

### 3.5 Package rules

- **One class per file, one file per class.** Barrel exports (`lib/thing_domain.dart`) expose the public API.
- `thing_domain` depends on `equatable` + `fpdart` + `crypto` — and nothing else. `crypto` is a deliberate carve-out for **content hashing**: an entity that needs a stable, byte-identical content digest cannot get it from `equatable.hashCode` (a VM int — 64-bit on the VM, a double under dart2js/WASM — so not run/platform-stable), and pure-Dart SHA-256 has no other spelling than `package:crypto` (pure Dart, no I/O, no platform calls, so it respects the no-I/O rule). Keep `crypto` out of usecases/datasources unless a domain contract needs a digest. Latest stable major (3.x today); not pinned — there is no off-limits line to exclude. No Flutter, no I/O, no JSON package (hand-written serialization or none).
- `thing_usecases` depends on `thing_domain` + `fpdart`. No datasource implementations, no Flutter.
- `*_datasource_*` packages depend on `thing_domain` + their storage tech (drift, sembast).
- `thing_flutter` (the app) depends on use cases + datasource packages + its state-management package (`flutter_riverpod` by default; `flutter_bloc` or a peer if the project picked one — §8.2). It wires adapters into the tree at the composition root only.

### 3.6 Deliverable type decides which rules bind

§3 opens with the deliverable types — **core** (pure-Dart library), **package** (published), **CLI**, **TUI**, **GUI** — and one of them narrows the reach of the rules written for repos that own storage. A **library package that ships no adapter** is outside the at-least-two-repository-adapter rule:

- **§1.2 / §5.2 do not bind it.** That rule exists so a contract is the *interface* rather than whatever one adapter happens to do. Where the deliverable **is** the contract — domain + use cases in one package, with the adapter left to whoever consumes it — there is no implementation of ours to vary, and a second one we wrote ourselves would prove nothing about the contract. The rule is not skipped or waived here; it is a category it was never about, which is why the package's `AGENTS.md` records that it publishes no adapter, and why.
- **The contract suite survives, and its obligation is unchanged.** Ship one suite that takes *any* implementation of a contract and asserts the whole of it — one table, a closure per call, one row per store — so a consumer's own adapter can be run against it. What this clause waives is the second adapter **we** own, never the suite, and never the suite's shape.
- **A reference implementation may still live in the repository** — and it stays out of the published archive (`.pubignore`). In-repo versus published is the distinction that matters: an adapter a consumer never receives cannot make one storage story look like the doctrine's, and keeping it in the repo is what lets the contracts be read as a running system.
- **Nothing else is narrowed here.** The unit-of-work seam (§5.5) is its own rule with its own decision, and a package that *does* ship an adapter is bound by §1.2 and §5.2 in full.

---
