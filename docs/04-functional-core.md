# 4. The Functional Core (fpdart)

**`fpdart: ^1.2.0` — pinned, everywhere, always.** Never the `2.0.0-dev` line (the Effect-based rewrite is still pre-release and off-limits).

### Which type, when

| Situation | Type |
|---|---|
| Sync, can fail | `Either<Failure, T>` |
| Async, can fail | `TaskEither<Failure, T>` |
| Value may be absent | `Option<T>` |
| Sync, may be absent | `IOOption<T>` (rare) |

### Failures are typed values, rust-style

Failure hierarchies are per-layer, defined in the domain package, and **closed** (abstract base + final/`sealed` leaves where the language allows — a `switch` over them must be exhaustive, which is the point):

```dart
sealed class AccountFailure {
  const AccountFailure();
}
final class AccountNotFound extends AccountFailure {
  final String id;
  const AccountNotFound(this.id);
}
final class InsufficientFunds extends AccountFailure {
  final String id;
  final double balance;
  const InsufficientFunds({required this.id, required this.balance});
}
final class RepositoryError extends AccountFailure {
  final String message;
  const RepositoryError(this.message);
}
```

Datasources get their own low-level hierarchy (`DatasourceFailure` → `SerializationFailure`, `StorageFailure`, …) that repositories **map upward** into domain failures. Never leak `DatasourceFailure` past the repository; never leak `AccountFailure` into the datasource.

### Signatures

```dart
abstract class IAccountRepository {
  /// Returns the account with [id], or [AccountNotFound].
  Future<Either<AccountFailure, Account>> get({required String id});

  /// Returns every account, oldest first.
  Future<Either<AccountFailure, List<Account>>> list();

  /// Credits [amount] to the account with [id].
  Future<Either<AccountFailure, Account>> deposit(
      {required String id, required double amount});
}
```

Use cases return the same shape — and take **discrete business params, never cargo objects**:

```dart
/// Fetches a single account.
class GetAccountUseCase {
  final IAccountRepository _repository;
  const GetAccountUseCase(this._repository);

  /// Returns the account with [id], or [AccountNotFound].
  Future<Either<AccountFailure, Account>> call({required String id}) =>
      _repository.get(id: id);
}
```

### Use-case parameters: business params, not cargo

A use case's `call()` takes the **actual business inputs** as discrete named parameters — `AddUserUseCase` receives `id`, `userName`, `email`, … — never a cargo/container object (`AddUserUseCase(UserBlockOfStuff(...))`).

Why:
- The signature *is* the documentation; a call site reads like the business operation.
- No anonymous container types to define, serialize, or pass across layer boundaries.
- A parameter list that outgrows ~4–5 business inputs is a smell: usually a missing entity or a use case doing too much. Reach for a domain entity (or value object) then, not a bag of fields.

### Composition

- Chain with `flatMap` / `map` / `mapLeft`.
- For readability, use the **Do notation** (`fpdart` supports it) instead of nested flatMaps:

```dart
final result = await Either.Do(
  ($) async {
    final account = await $(repository.get(id: id));
    final updated = await $(repository.deposit(id: account.id, amount: 100));
    return updated;
  },
);
```

- Convert third-party exceptions *at the adapter boundary only*: `TaskEither.tryCatch(() => ..., (e, st) => DatasourceFailure(...))`. The instant a third-party call throws, it becomes a `Left` and never propagates as an exception.

  "Adapter boundary" is a **line, not a zone**. The only try/catch-shaped code an adapter may contain is `TaskEither.tryCatch` (or `Either.tryCatch`) wrapping the third-party call itself, in the public adapter method; an exception never crosses the adapter's public API. Hand-rolled `try/catch` for imperative control flow inside an adapter is a violation — the adapter does not get a pass on the exception rule, it *owns the conversion seam* precisely because it is the code touching the throwing library.

### Where the chain ends: `.run()` at the public seam

TaskEither is the **internal** composition type. The **public seam is `Future<Either<Failure, T>>`** — repository contract methods and use case `call()` signatures are `Future<Either<...>>`, never `TaskEither<...>`.

- **`.run()` terminates the chain at the public method boundary, inside the implementation.** A use case composes with TaskEither internally (`flatMap`, Do-notation, `tryCatch` at the adapter) and the last thing its `call()` does is `.run()` (or `await ... .run()`), returning the plain `Future<Either<...>>`.
- **Consumers (UI, CLI, other use cases) never build or run TaskEither chains.** They await a `Future<Either<...>>` and `fold` it. This is the termination the user wants: fpdart's laziness dies in the core, not in the widget tree. (Consumers will still import fpdart to `fold`/`getOrElse` an `Either` — that is expected and fine; what they never touch is chain-building, laziness, and `.run()`.)
- **Why:** laziness leaks out of the core, it becomes a UI problem (forgetting `.run()`, mutating captured lists inside lazy callbacks, debugging chains that "did nothing"). Keep `.run()` inside the layer that built the chain; the boundary is the type change `TaskEither → Future<Either>`.

### Declare the error style, loudly

Two error styles live in our estate and a consumer must never have to discover
which one they are holding: **FP-style tuples** (`Either` / `TaskEither` — failure
is a value) or **plain exceptions** (failure is thrown). Every package declares
which one it presents, in the same words, in all of these:

1. **the package barrel's doc comment** (`lib/<pkg>.dart`) — the IDE tooltip and
   the pub.dev API page;
2. **the package README**, near the top, so it is read before the first call is
   written;
3. **the repo's `AGENTS.md`**, whenever the package deviates from the default
   below.

The declaration names the style and the failure type in consumer terms:

> This package presents **FP-style tuples**: every call returns
> `TaskEither<Failure, T>`; `.run()` it for `Future<Either<Failure, T>>`.

> This package presents **plain exceptions**: it throws `FooException`; catch at
> your boundary.

- **Default:** core packages present `Future<Either<Failure, T>>` and terminate
  their own chains (above). A package that hands the consumer the unrun
  `TaskEither` instead is **not** a violation *provided it declares it* — seeing a
  tuple is how a consumer knows to `.run()` it. The violation is silence, never
  the choice.
- **Exceptions are never the default in the bulls-eye.** A package that presents
  them says where they are raised and caught (see *The exception rule* below) and
  keeps them out of domain and use cases.
- The declaration describes the **seam**, not the internals: a package with pure
  `TaskEither` internals may present `Future<Either<...>>`, and a package that
  presents tuples may still throw inside a widget. Internal composition never
  changes what the caller receives.
- Omitting the declaration costs a consumer exactly two bugs: a `TaskEither` that
  never ran, and an exception thrown across a seam they believed was a value.

### Equality: equatable

Every entity and value object `extends Equatable` with `List<Object?> get props => [...]`. This gives value semantics for `==` and `hashCode`, which fpdart pattern matching, testing, and drift row mapping all rely on. Hand-written, no codegen.

### The exception rule, stated once, loudly

**Inside the bulls-eye: no `throw`, no `try/catch` (except `tryCatch` conversion at adapter boundaries), no `on Exception`.** The UI ring is the *only* place exceptions are raised or caught, and even there they should be converted into UI state as fast as possible.

---
