# 6. Testing Doctrine

### 6.1 The idiom: shouldly, "should be"

**`shouldly`** (yes, `shouldly` — pronounced "should-lee", package on pub.dev) is the assertion library. The idiom is plain-English: `value.should.be(...)`.

```dart
final result = await useCase.call(id: 'acct1');
result.isRight().should.be(true);
final account = result.getOrElse((_) => fail('expected Right'));
account.balance.should.be(1000);
account.id.should.be('acct1');
```

Rules:
- **Never mix `expect()` with shouldly in the same assertion or test file.** Pick one voice; we pick shouldly.
- `Should.throwError(() => ...)` for the rare code path that legitimately throws (UI-boundary code, third-party conversions).
- Conjunctions read nicely: `result.should.not.beNull.and.beOfType<Account>()`.
- Test names are **Given/When/Then**:

```dart
group('Given GetAccountUseCase', () {
  group('When the account exists', () {
    test('Then it returns the account', () async { ... });
  });
});
```

### 6.2 Where tests live (layer matrix)

| Layer | Package | Technique |
|---|---|---|
| Domain | `thing_domain/test` | **Unit tests**, pure, no mocks — construct entities, exercise rules |
| Application | `thing_usecases/test` | **Mocking at the use-case seam** with `mocktail` (mock the repository/datasource *interface* only) |
| Datasource adapters | `*_datasource_*/test` | **In-memory real implementations** — drift `NativeDatabase.memory()`, sembast `databaseFactoryMemory` |
| Contract | shared test suite | Run the same assertions against **every** adapter |
| UI ring | `thing_flutter/test` | Widget tests; pump widgets, assert rendered state with shouldly |

### 6.3 Mocktail

- **`mocktail`** for mocks — and only at the application layer, mocking interfaces we own (repository/datasource contracts). Never mock a third-party class; adapters exist to isolate those.
- Prefer real in-memory doubles over mocks when one exists (the second adapter *is* the double).
- `registerFallbackValue` when a mock receives objects.

### 6.4 Coverage of failure paths

Every use case test asserts **both** sides of the Either: the `Right` happy path and each `Left` failure (missing entity, invalid input, repository error). A failure path without a test is a bug waiting for the UI to display it.

### 6.5 Pitfalls (field reports)

Things that have actually bitten people, so they bite no one twice:

- **fpdart `isRight`/`isLeft` are methods, not properties.** `result.isRight()`, never `result.isRight`. The property form compiles into a silently-wrong assertion or an analyzer complaint depending on context — either way it wastes a debugging cycle.
- **shouldly has no `beTrue`/`beFalse`.** Use `.should.be(true)` / `.should.be(false)`. (shouldly pins here: `shouldly: ^0.5.0+1`; older versions have a different API shape.) 
- **`getOrElse` / `fold` callbacks receive the Left value.** Write `getOrElse((_) => fallback)`, never `getOrElse(() => fallback)`. Same for `fold((l) => ..., (r) => ...)`.
- **Never hardcode absolute paths in tests** — no home directories, no `/tmp/foo` literals. Use `Platform.environment['HOME']` (or `Directory.systemTemp`) plus the `path` package. Hardcoded paths are the leading cause of "tests pass on my machine, fail in CI."
- **fpdart chains are lazy — nothing runs until `.run()`.** Building a `TaskEither` chain executes zero callbacks; only `.run()` (or `await`) drives it. The classic bug: mutate a captured list inside a `flatMap` callback, then iterate that list *after* building the chain but before `.run()` — the loop sees the pre-mutation list (ResolveSchema-style bugs: every call returns `[]`). If a use case must collect intermediate results, thread them through the chain (`.flatMap((acc) => ...)`), never a captured mutable list.
- **Prefer extracting the Right value via `getOrElse` after asserting `isRight()`** — keeps the test readable and the failure message useful.

### 6.6 GUI testing: the three layers

A GUI is tested at three levels, and they are **not interchangeable**. An agent driving a *running* app is never a repeatable gate — it is the accelerant, not the test.

| Layer | What runs | Deterministic in CI? | Purpose |
|---|---|---|---|
| Widget tests | `flutter test test/` — pump widgets headless | Yes, fast, hermetic | Assert rendered state per widget/provider |
| Integration tests | `flutter test integration_test/…` — drive the *real* app | **Yes — the GUI gate** | End-to-end: real widgets, real navigation, real adapter wiring |
| Agent interaction | `marionette_flutter` + `marionette_mcp` driving the running app over the VM service | **No** — agent-in-the-loop | Dev-time exploration, smoke-testing, debugging a live GUI |

Rules:
- **The gate is deterministic (§8.5).** A GUI change ships with widget and/or integration coverage that runs in CI (`flutter test integration_test/...`). Marionette decides *what* to tap; that is useful in development and useless for a green build. Never an agent-driven test as the gate.
- Contract tests never live in the UI repo (§3); the same separation holds here — integration tests exercise the use-case seam end-to-end, they do not re-test core.
|---
