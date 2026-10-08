# 2. Toolchain & SDK

| Thing | Doctrine |
|---|---|
| Dart SDK | `sdk: '>=3.10.0 <4.0.0'` — floor 3.10, never 4.x |
| Package manager | pub (Dart 3.5+ **pub workspaces**) |
| Monorepo | Native **pub workspaces** (`workspace:` + `resolution: workspace`); **melos optional** (script runner only) |
| Formatter | `dart format` only |
| Analyzer | `dart analyze` — **zero diagnostics of any severity** (errors, warnings, infos) before any commit; gate = `dart analyze --fatal-infos --fatal-warnings` (§2 "Analyzer: zero tolerance") |
| Docs | Terse `///` on declarations and their public members (1–2 lines, what+why) — **never as a file header** — dartdoc/pub.dev-ready |
| Tests | `dart test` |

### 2.1 Melos: optional — a script runner, not the orchestrator

Melos is **optional**, not doctrine. Its best modern use is **single-package script management**: one `melos:` scripts block in a root that *is* the package (`useRootAsPackage: true`). For a **pile of packages never meant to be published individually to pub.dev, stop leaning on melos workspace orchestration** — the more you lean on package filters and cross-package `exec`, the harder it breaks, and it enforces nothing about boundary direction anyway. Native pub workspaces carry the multi-package structure; melos does not need to. A repo holding a single package is the same shape with the package *as* the workspace root — see §3 Topology C.

A `melos.yaml` file remains a bad smell: it was deleted in **melos 7.0.0** in favor of the root `pubspec.yaml`; a repo still carrying one is on 6.x or earlier and should be migrated. If you opt into melos, config lives in the **root `pubspec.yaml`** under a `melos:` key.

Root `pubspec.yaml`:

```yaml
name: my_workspace
publish_to: none
environment:
  sdk: '>=3.10.0 <4.0.0'
workspace:
  - packages/thing_domain
  - packages/thing_usecases
  - packages/thing_datasource_drift
  - packages/thing_datasource_sembast
  - apps/thing_flutter
dev_dependencies:
  melos: ^8.8.0

melos:
  scripts:
    # Bare string = one command, once, in the workspace root.
    analyze: dart analyze --fatal-infos --fatal-warnings
    # `exec` = one run per package. Since melos 8 the command is `exec.command`.
    test:
      exec:
        command: dart test
        concurrency: 1
      packageFilters:
        dirExists: test
```

Each package `pubspec.yaml`:

```yaml
name: thing_domain
environment:
  sdk: '>=3.10.0 <4.0.0'
resolution: workspace
```

Notes — only if you opted into melos:
- The `workspace:` list is explicit — globs are not supported yet; list every package.
- `melos bootstrap` links local packages without `pubspec_overrides.yaml` (workspaces replaced that mechanism).
- Scripts live in the `melos:` key; run with `melos run <name>`. Since melos 8 the per-package form is **`exec.command:`** (the old `run:` + `exec:` split is a config error).
- Pin `^8.8.0`: 8.0.0 shipped with no `melos analyze` command (restored 8.1.0, tightened to `--fatal-infos` in 8.2.0). The analyze gate is spelled out as a script rather than trusting the bare command for exactly this reason.
- **Melos enforces no boundary rules.** Dependency direction is the responsibility of a `dart_arch_test` architecture test (below) — never a melos script.

### 2.2 Analyzer: zero tolerance

"Clean" means **zero diagnostics — errors, warnings, and infos alike.** A report of
"zero errors, only warnings/infos remain" is not a pass; it is a failing state with a
known cause. There is no such thing as a harmless analyzer finding, and an agent that
reports a pass while any diagnostic remains is wrong, full stop.

- **The gate is the fatal flags, not plain analyze.** Plain `dart analyze` exits 0 on
  infos alone, so it can't be trusted as a gate. Run `dart analyze --fatal-infos
  --fatal-warnings` in CI and in any melos script you run — every diagnostic of any severity
  becomes a non-zero exit.
- **TODOs are diagnostics, not exceptions.** Map `todo` to `error` in
  `analysis_options.yaml` (`analyzer: errors: todo: error`), so a TODO comment is a
  compile error. Deferred work goes in the project roadmap doc — never in a code
  comment. No TODO survives into merged or released code.
- **Suppression is per-line or nothing.** A rule that genuinely doesn't apply gets
  `// ignore: <rule_code>` on the offending line (with a reason when the intent isn't
  obvious). Never `// ignore_for_file:`. Never disable a rule in `analysis_options.yaml`.
  If a lint fires everywhere, the code is wrong — not the lint.

### 2.3 Dart-first editing

We are a Dart shop. Structural changes to `.dart` files are made with Dart tooling (`dart format`, targeted edits), never with Python/shell text-munging scripts. This is non-negotiable and applies to agent workflows too.

### 2.4 Docs: terse, always — and never a file header

Public **declarations and their members** — classes, enums, extension types, top-level functions, and the public methods/fields on them — get a terse `///` doc comment (**at least one line, never more than two**). Say *what* it is and *why* it exists; never restate the implementation. This is a hard requirement: pub.dev scores on doc coverage (`public_member_api_docs`) and every dartdoc-style generator needs real comments to produce anything useful.

`///` is for **declarations only — never for files.** A doc comment as the first line of a file attaches to the unnamed library, which the analyzer flags as a dangling library doc unless you add a `library;` directive it can hang on. We don't write per-file `library;` directives — they exist only in barrel files (§"Barrel files"), which are deliberate *library* documentation. For ordinary files:

- Notes about the file as a whole (license, attribution, a comment explaining a non-obvious design choice) go in a normal `//` comment, not `///`.
- If the file contains exactly one public declaration, the first-line `///` belongs **on that declaration**, below the imports — not floating at the top of the file.
- Adding a `library;` directive just to satisfy a file-level `///` is a violation.

- **Use cases are the priority.** Every `*UseCase` documents what it does and what it returns.
- Enforce it: enable `public_member_api_docs` in `analysis_options.yaml`; keep `dart analyze` clean.

### 2.5 Dart parameter style

**Named parameters, always** — with exactly two exceptions: a single positional parameter named `ref` or `message`. **Flutter widgets follow Flutter's own conventions** (framework-mandated named params, positional `child`/`key`-style usage, etc.), not these rules.

### 2.6 Barrel files: one public door per package

Each package exposes **exactly one public entry point**: `lib/<package_name>.dart`, a hand-written barrel that re-exports the public API from `lib/src/`. Everything else under `lib/` is private.

- Consumers import the barrel only — **never** `package:thing/src/...` paths. `src/` is an implementation detail.
- Barrels are **hand-maintained** (part of the one-class-per-file discipline): one export line per public class. No codegen, no wildcard exports.
- What's exported *is* the public API: nothing gets into the barrel until it's deliberate. Private-by-default beats doc-marking later.
- Publishing and the wiki rendering both assume this: the barrel is the contract a package ships. It is hand-written doctrine; nothing generates it.

### 2.7 Code placement: tests first, `example/` only for packages

Know what we build: **cores** (pure-Dart libraries), **packages** (published to pub.dev), **CLIs**, **TUIs**, **GUIs** (Flutter). Where example code lives depends on the deliverable:

- **Tests are the default home for all example code** — fully exercised and documented there. If it compiles and demonstrates something, it belongs in a test before anywhere else.
- **`example/` is a package deliverable.** pub.dev builds its Example tab from an `example/` directory — singular, per the [package layout](https://dart.dev/tools/pub/package-layout) convention (`example/README.md`, `example/example.dart` or `example/lib/main.dart`). So published packages get a real, CI-tested `example/`; `examples/` (plural) is not the pub.dev convention. Non-published deliverables (cores, CLIs, TUIs, GUIs) skip it unless there's a genuine need — e.g., a core ships a small facade example so GUI implementers can see the seam wired. Otherwise: tests.
- **Never in READMEs or prose documentation**, with the very smallest exceptions (a one-line command, a filename). The doctrine docs themselves may carry small illustrative snippets — tight, not piles — but anything that must compile and stay true is a test or `example/`.

See `example/` (`bible_samples`) for the CI-tested reference.

### 2.8 Enforcement: lint vs. review

Not every rule in this bible can be automated. Know which is which:

**Lint-enforced (self-enforcing — `dart analyze` is the gate):**
- `public_member_api_docs` — missing `///` on any public declaration or member fails the build. It does *not* require file-level docs — we're stricter than pub.dev on where docs are required (declarations), and we ban them where they don't belong (file headers).
- `implementation_imports` — cross-package `package:thing/src/...` imports fail. Already on by default via `package:lints/recommended`.

**Test-enforced (self-enforcing — `dart test` is the gate):**
- Package-boundary direction + cycle-freedom — a `dart_arch_test` `test()` (§2.9) asserts inward direction over the **resolved import graph** (package-aware; the glob DSL is package-name-blind) and workspace-wide cycle-freedom. Expressed as a test so CI already runs it; no separate gate to remember.

**Review-enforced (no automated check exists — don't invent one):**
- Cargo/business params — that's intent, not syntax. No rule can tell a container from a cohesive value object.
- Barrel freshness — nothing catches a stale barrel or a class added to `src/` without an export (analyzer plugin rules read `import` only, never the hand-written `export` list). Review or a barrel-freshness check in the arch test catches it.

The review checklist (§10) is the gate for the second group.

### 2.9 Package-boundary rules: `dart_arch_test`, not melos (and not `import_rules`)

Dependencies point inward (§1, the four laws) — that is a *package-boundary* rule, and it is enforced as an **architecture test with `dart_arch_test`**: a plain `test()` that runs in CI with everything else. Melos enforces no boundaries, and the **`import_rules`** analyzer plugin falls down on pub workspaces (it reads `import` directives only, does not reliably visit workspace-member packages, and ships defaulting to `info` severity) — it is at most an optional as-you-type nicety, never the gate.

Build the **resolved import graph** once per suite, then assert boundary direction on `package:` URIs:

```dart
// test/architecture_test.dart
import 'dart:io';

import 'package:dart_arch_test/dart_arch_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Package-aware boundary check. Every dependency of a library whose URI starts
/// with [innerPrefix] must start with one of [allowed] (else fail).
void checkBoundary(DependencyGraph g, String innerPrefix, Set<String> allowed) {
  final violations = <String>[];
  for (final caller in Collector.allLibraries(g)) {
    if (!caller.startsWith(innerPrefix)) continue;
    for (final dep in Collector.dependenciesOf(g, caller)) {
      if (dep.startsWith('dart:')) continue;
      if (!allowed.any(dep.startsWith)) violations.add('$caller -> $dep');
    }
  }
  if (violations.isNotEmpty) fail(violations.join('\n'));
}

/// The workspace root — the nearest ancestor of CWD whose pubspec.yaml declares
/// `workspace:`; for a standalone package (bible_samples) it is that package.
/// Reliable under `dart test` (CWD = package dir). Do not use Platform.script.
String workspaceRoot() {
  var dir = Directory.current;
  while (true) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final text = pubspec.readAsStringSync();
      if (RegExp(r'^workspace:', multiLine: true).hasMatch(text)) {
        return dir.path; // found the workspace root
      }
      if (!RegExp(r'^resolution:\s*workspace', multiLine: true).hasMatch(text)) {
        return dir.path; // standalone package — no workspace
      }
      // else: a workspace member (resolution: workspace) — keep walking up.
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return dir.path;
    dir = parent;
  }
}

void main() {
  late DependencyGraph graph;

  setUpAll(() async {
    // Point at the workspace root (the nearest ancestor whose pubspec.yaml has
    // `workspace:`). Never derive the root from Platform.script — under some
    // runners (`dart test`) it points at the runner's kernel snapshot in a
    // scratch dir, so the graph comes back empty and every rule passes
    // vacuously. Directory.current + walk-up is reliable.
    graph = await Collector.buildGraph(workspaceRoot());
  });

  test('domain reaches only itself + its sanctioned deps', () {
    checkBoundary(graph, 'package:thing_domain/',
        {'package:thing_domain/', 'package:fpdart/', 'package:equatable/'});
  });

  test('usecases never see a datasource', () {
    checkBoundary(graph, 'package:thing_usecases/',
        {'package:thing_usecases/', 'package:thing_domain/', 'package:fpdart/'});
  });

  test('no import cycles anywhere', () {
    shouldBeFreeOfCycles(allFiles(), graph);
  });
}
```

Notes (verified against a two-package pub workspace):
- **`Collector.buildGraph` resolves the full import graph across the whole workspace** — real analyzer resolution keyed by canonical `package:` URIs. Point it at the workspace root and it sees every member package. This is what substring/folder heuristics (and `import_rules` in practice) cannot do.
- **The glob DSL is package-name-blind — do not use it for package boundaries.** `dart_arch_test` strips the `package:<name>/` prefix before matching, so whole-package patterns (`filesMatching('thing_domain/**')`, `defineOnion`/`defineLayers` keyed on package names) match **nothing** in a multi-package workspace, and a planted cross-package violation sails through silently. Write **plain assertions over `package:` URIs** (the `checkBoundary` helper above) for direction. `filesMatching('**')` / `allFiles()` still match everything, so workspace-wide cycle checks work.
- **Root resolution: use `Directory.current` + walk-up, never `Platform.script`.** Under some runners (`dart test`) `Platform.script` points at the runner's kernel snapshot in a scratch dir, so a graph built from it is empty and every rule passes vacuously (verified). The `workspaceRoot()` helper walks up from CWD to the `workspace:` pubspec. See the live, CI-run test in `example/test/architecture_test.dart` for the working pattern.
- `shouldBeFreeOfCycles(allFiles(), graph)` is the cycle gate; it is workspace-wide and reliable.
- It is **self-enforcing by construction**: a real test, no config files, no codegen — CI already runs it with `dart test`.
- Keep fine-grained structural conventions (naming, `///` docs, sealed/base, param shape) in the **analyze lint gate** — do **not** re-encode them as a second arch-test layer (D.R.Y., §1). The arch test owns *direction*; lints own *shape*.

---
