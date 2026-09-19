# 2. Toolchain & SDK

| Thing | Doctrine |
|---|---|
| Dart SDK | `sdk: '>=3.10.0 <4.0.0'` — floor 3.10, never 4.x |
| Package manager | pub (Dart 3.5+ **pub workspaces**) |
| Monorepo | **melos 8** — configured entirely in root `pubspec.yaml` |
| Formatter | `dart format` only |
| Analyzer | `dart analyze` — **zero diagnostics of any severity** (errors, warnings, infos) before any commit; gate = `dart analyze --fatal-infos --fatal-warnings` (§2 "Analyzer: zero tolerance") |
| Docs | Terse `///` on declarations and their public members (1–2 lines, what+why) — **never as a file header** — dartdoc/pub.dev-ready |
| Tests | `dart test` |

### Melos: the modern way (and the bad smell)

**A `melos.yaml` file is a bad smell.** `melos.yaml` was deleted in **melos 7.0.0** in favor of the root `pubspec.yaml`; a repo still carrying one is on 6.x or earlier. Modern melos (7.x, and definitively 8.x) has no `melos.yaml` at all — it uses native pub workspaces and puts all config in the **root `pubspec.yaml`** under a `melos:` key. If you see a repo with a `melos.yaml`, it is running a legacy setup and should be migrated. A repo holding a single package is the same shape with the package *as* the workspace root — see §3 Topology C.

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

Notes:
- The `workspace:` list is explicit — globs are not supported yet; list every package.
- `melos bootstrap` links local packages without `pubspec_overrides.yaml` (workspaces replaced that mechanism).
- Scripts live in the `melos:` key; run with `melos run <name>`.
- **Script schema — the melos 8.0.0 break.** A script runs either *once in the workspace root* (`run: <command>`, or the bare-string shorthand) or *once per package* (`exec:`). Since 8.0.0 the per-package command must be given as **`exec.command:`**; the old split — `run:` for the command plus `exec:` for its options — is gone, and a script that sets both `run` and `exec` is a config error. Fed to a melos 7 parser, an `exec.command` script fails with `MissingScriptCommandException: … You must specify a script to run`.
- **Pin `^8.8.0`.** The floor has to clear three fixed points in the 8.x line: 8.0.0 has no `analyze` command at all — `melos analyze` exits non-zero printing the usage list (verified locally against 8.0.0), and with an `analyze` script defined it silently falls through to that script, so the command *looks* fine on a repo that spells the gate out by name and fails on one that does not; 8.1.0 restores the command; 8.2.0 is where it stops being lenient by default. Anything below the floor is a workspace whose analyze gate depends on where you typed it. Pin the current floor and let the caret carry you forward — the next break lands in a minor release (that is what 8.0.0 did), so it will be caught by anyone who re-runs the gate, not by the constraint.
- **`melos analyze` got stricter in 8.2.0.** From 8.2.0 the built-in command defaults to `--fatal-infos` for dart and flutter packages — the gate this section demands — so it finally agrees with the `analyze` script above. Calling the script (as CI does) rather than the bare command is what keeps that agreement explicit on every 8.x.

### Analyzer: zero tolerance

"Clean" means **zero diagnostics — errors, warnings, and infos alike.** A report of
"zero errors, only warnings/infos remain" is not a pass; it is a failing state with a
known cause. There is no such thing as a harmless analyzer finding, and an agent that
reports a pass while any diagnostic remains is wrong, full stop.

- **The gate is the fatal flags, not plain analyze.** Plain `dart analyze` exits 0 on
  infos alone, so it can't be trusted as a gate. Run `dart analyze --fatal-infos
  --fatal-warnings` in CI and in melos scripts — every diagnostic of any severity
  becomes a non-zero exit.
- **TODOs are diagnostics, not exceptions.** Map `todo` to `error` in
  `analysis_options.yaml` (`analyzer: errors: todo: error`), so a TODO comment is a
  compile error. Deferred work goes in the project roadmap doc — never in a code
  comment. No TODO survives into merged or released code.
- **Suppression is per-line or nothing.** A rule that genuinely doesn't apply gets
  `// ignore: <rule_code>` on the offending line (with a reason when the intent isn't
  obvious). Never `// ignore_for_file:`. Never disable a rule in `analysis_options.yaml`.
  If a lint fires everywhere, the code is wrong — not the lint.

### Dart-first editing

We are a Dart shop. Structural changes to `.dart` files are made with Dart tooling (`dart format`, targeted edits), never with Python/shell text-munging scripts. This is non-negotiable and applies to agent workflows too.

### Docs: terse, always — and never a file header

Public **declarations and their members** — classes, enums, extension types, top-level functions, and the public methods/fields on them — get a terse `///` doc comment (**at least one line, never more than two**). Say *what* it is and *why* it exists; never restate the implementation. This is a hard requirement: pub.dev scores on doc coverage (`public_member_api_docs`) and every dartdoc-style generator needs real comments to produce anything useful.

`///` is for **declarations only — never for files.** A doc comment as the first line of a file attaches to the unnamed library, which the analyzer flags as a dangling library doc unless you add a `library;` directive it can hang on. We don't write per-file `library;` directives — they exist only in barrel files (§"Barrel files"), which are deliberate *library* documentation. For ordinary files:

- Notes about the file as a whole (license, attribution, a comment explaining a non-obvious design choice) go in a normal `//` comment, not `///`.
- If the file contains exactly one public declaration, the first-line `///` belongs **on that declaration**, below the imports — not floating at the top of the file.
- Adding a `library;` directive just to satisfy a file-level `///` is a violation.

- **Use cases are the priority.** Every `*UseCase` documents what it does and what it returns.
- Enforce it: enable `public_member_api_docs` in `analysis_options.yaml`; keep `dart analyze` clean.

### Dart parameter style

**Named parameters, always** — with exactly two exceptions: a single positional parameter named `ref` or `message`. **Flutter widgets follow Flutter's own conventions** (framework-mandated named params, positional `child`/`key`-style usage, etc.), not these rules.

### Barrel files: one public door per package

Each package exposes **exactly one public entry point**: `lib/<package_name>.dart`, a hand-written barrel that re-exports the public API from `lib/src/`. Everything else under `lib/` is private.

- Consumers import the barrel only — **never** `package:thing/src/...` paths. `src/` is an implementation detail.
- Barrels are **hand-maintained** (part of the one-class-per-file discipline): one export line per public class. No codegen, no wildcard exports.
- What's exported *is* the public API: nothing gets into the barrel until it's deliberate. Private-by-default beats doc-marking later.
- Melos/publishing and the wiki rendering all assume this: the barrel is the contract a package ships. Melos manages *packages*; it does not write your barrels.

### Code placement: tests first, examples only for packages

Know what we build: **cores** (pure-Dart libraries), **packages** (published to pub.dev), **CLIs**, **TUIs**, **GUIs** (Flutter). Where example code lives depends on the deliverable:

- **Tests are the default home for all example code** — fully exercised and documented there. If it compiles and demonstrates something, it belongs in a test before anywhere else.
- **`examples/` is a package deliverable.** pub.dev expects it, so published packages get a real, CI-tested `examples/`. Non-published deliverables (cores, CLIs, TUIs, GUIs) skip it unless there's a genuine need — e.g., a core ships a small facade example so GUI implementers can see the seam wired. Otherwise: tests.
- **Never in READMEs or prose documentation**, with the very smallest exceptions (a one-line command, a filename). The doctrine docs themselves may carry small illustrative snippets — tight, not piles — but anything that must compile and stay true is a test or `examples/`.

See `examples/` (`bible_samples`) for the CI-tested reference.

### Enforcement: lint vs. review

Not every rule in this bible can be automated. Know which is which:

**Lint-enforced (self-enforcing — `dart analyze` is the gate):**
- `public_member_api_docs` — missing `///` on any public declaration or member fails the build. It does *not* require file-level docs — we're stricter than pub.dev on where docs are required (declarations), and we ban them where they don't belong (file headers).
- `implementation_imports` — cross-package `package:thing/src/...` imports fail. Already on by default via `package:lints/recommended`.

**Review-enforced (no lint exists — don't invent one):**
- Cargo/business params — that's intent, not syntax. No rule can tell a container from a cohesive value object.
- Barrel freshness — nothing catches a stale barrel or a class added to `src/` without an export. A custom analyzer plugin *could*, but that's over-engineering for something review catches in seconds.

The review checklist (§10) is the gate for the second group.

---
