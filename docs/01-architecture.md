# 1. The Bulls-Eye (Doctrine)

```
        ┌──────────────────────────────────────────┐
        │  UI / Presentation (Flutter)             │  outer ring
        │  exceptions ARE allowed here — ONLY here │
        │  ┌────────────────────────────────────┐  │
        │  │  Application / Use Cases           │  │  orchestration
        │  │  no I/O, no Flutter, no exceptions │  │  mock here in tests
        │  │  ┌──────────────────────────────┐  │  │
        │  │  │  Domain (entities)           │  │  │  THE CENTER
        │  │  │  pure: no I/O, no packages    │  │  │  unit-test here
        │  │  │  except equatable/fpdart*     │  │  │
        │  │  └──────────────────────────────┘  │  │
        │  └────────────────────────────────────┘  │
        │  Datasource adapters live OUTSIDE        │
        │  (drift/sqlite, sembast, http, memory)   │
        └──────────────────────────────────────────┘
```
\* `crypto` is additionally allowed in the domain **for content hashing only** — a stable, byte-identical digest that `equatable.hashCode` can't provide (see §3.5). It never grants general widening.

### 1.1 The Four Laws

1. **1.1.1** — **Dependencies point inward. Always.** Domain knows nothing about application, UI, or datasources. Application knows domain. UI knows everything *through interfaces*. Nothing outside knows anything concrete about the center.
2. **1.1.2** — **Entities are the center.** Pure Dart classes: immutable (`const` constructors), value equality (`equatable`), zero I/O, zero Flutter imports. All operations return **new instances**.
3. **1.1.3** — **Flow is one direction:** UI → use case → repository interface → datasource adapter. No sideways jumps. No UI talking to a datasource. No use case instantiating a widget.
4. **1.1.4** — **Exceptions are a UI-boundary phenomenon.** Everywhere inside the bulls-eye, failure is a *value* (fpdart `Either`/`TaskEither`). Only the outermost ring may throw or catch. We are rust-like: failures are typed tuples, not jumps.

In code, the flow looks like this:

```dart
// UI ring — the only place exceptions live:
final result = await getAccount(id: id);
result.fold((failure) => ErrorView(failure), (account) => AccountView(account));

// Application ring — a use case is a thin coordinator:
Future<Either<AccountFailure, Account>> call({required String id}) =>
    _repository.get(id: id);
```

### 1.2 The At Least Two Repository Adapter Rule (the one we never skip)

**Every repository contract gets at least two repository adapters.** One real persistence adapter is not enough — with only one adapter, the contract is whatever that adapter happens to do. Two adapters (e.g. drift/sqlite + in-memory, or drift + sembast) force the contract to be the *interface*, and a shared **contract test suite** runs against every adapter, so a deviation in any implementation fails CI.

In-memory adapters are legitimate second adapters, and they double as the test double for use-case tests — prefer them over mocking where feasible.

### 1.3 Don't Repeat Yourself (D.R.Y.)

Doctrine lives here, in exactly one place. Repo docs (README, AGENTS.md) and code comments **reference** a rule; they never restate it — a second copy is a second truth the moment the first one changes.

- The bible is the doctrine source. A repo's AGENTS.md records only that repo's deviations and local wiring; READMEs orient (what it is, how to run it) and carry no rules or architecture.
- If a rule already exists, link to it — do not copy it into another doc.
- Any fact stated twice will drift; when two copies disagree, both are suspect and the fix is deletion, not reconciliation.
- **Repo docs hold separate jobs so none of them becomes a diary.** `BACKLOG.md` is a queue, not a warstory: one terse entry per unique, actionable item, each pick-up-able whole by automation — never a narrative, rationale, or metanarrative. The keen, non-obvious decisions and the *why* belong in `CHANGELOG.md`; the "keep your footing here" operational knowledge (deviations, local wiring, pitfalls) belongs in `AGENTS.md`. A fact that lands in two of these will drift — move it to its one home, don't restate it.

### 1.4 The API surface (docs, params, style)

- **Terse docs:** declarations and their public members get a `///` comment, 1–2 lines — *what* and *why*, never *how*. Never at the top of a file (that forces a `library;` directive — for barrels only). dartdoc/pub.dev-ready; the `public_member_api_docs` lint stays on. Use cases **must** be documented.
- **Business params:** a use case's `call()` takes discrete business inputs (`id`, `userName`, …), never a cargo object (`AddUserUseCase(UserBlockOfStuff(...))`). The signature is the documentation.
- **Named parameters** in Dart — sole exceptions: a single positional `ref`, `message`, or `value`. Flutter widgets follow Flutter conventions.
- **One barrel per package:** `lib/<package>.dart` hand-exports the public API from `lib/src/`; never import `src/` across packages. What's in the barrel *is* the public API.

---
