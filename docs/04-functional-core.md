# 4. The Functional Core (fpdart)

**`fpdart: ^1.2.0` — pinned, everywhere, always.** Never the `2.0.0-dev` line (the Effect-based rewrite is still pre-release and off-limits). **`equatable`: the latest stable major — `^3.x` today, not a snapshot pin.** Unlike fpdart there is no off-limits line to exclude, so pinning the major buys nothing and goes stale; a stale pin is what makes a conforming repo look deviant. A pin means a documented exclusion, never a snapshot.

### 4.1 Which type, when

| Situation | Type |
|---|---|
| Sync, can fail | `Either<Failure, T>` |
| Async, can fail | `TaskEither<Failure, T>` |
| Value may be absent | `Option<T>` |
| Sync, may be absent | `IOOption<T>` (rare) |

### 4.2 Failures are typed values, rust-style

Failure hierarchies are per-layer, defined in the domain package. **Closure belongs
to the set a layer RETURNS, never to the root.** A `sealed` class can only be
extended from its own library, so the moment a package's contracts are typed against
its failure root, sealing that root forbids a consumer's own failure family and
charges a translation at every call **into** the package instead of one at its edge.
Two roles, two types:

- the **root** — `abstract base`, open, so a consuming layer's family extends it and
  everything composes in one channel. The seam is typed against this;
- the **set** — `sealed`, holding this layer's own leaves, and the thing a `switch` is
  proven exhaustive over. Match the set first (`case AccountError() => switch (...)`)
  when the left may also carry a consumer's failure.

```dart
/// The shared root: open, so a consuming layer's own failures extend it.
abstract base class AccountFailure {
  const AccountFailure();
}

/// Every way THIS layer can fail — closed, so a `switch` over it is exhaustive.
sealed class AccountError extends AccountFailure {
  const AccountError();
}

final class AccountNotFound extends AccountError {
  final String handle;
  const AccountNotFound(this.handle);
}
final class InsufficientFunds extends AccountError {
  final String handle;
  final double balance;
  const InsufficientFunds({required this.handle, required this.balance});
}
final class RepositoryError extends AccountError {
  final String message;
  const RepositoryError(this.message);
}
```

A package that never hands its failure type across a boundary may collapse the two
roles into one `sealed` root — closure only bites where a consumer composes.

Datasources get their own low-level hierarchy (`DatasourceFailure` → `SerializationFailure`, `StorageFailure`, …) that repositories **map upward** into domain failures. Never leak `DatasourceFailure` past the repository; never leak `AccountFailure` into the datasource.

`base` rather than plain `abstract` is what stops outside code `implements`-ing the root: the hierarchy stays a family of classes rather than an interface anybody can fake. What an open root buys is a consuming layer's family **extending** it instead of wrapping it — a wrapper charges a translation at every call *into* the package and buys nothing the subtype relation did not already give. Four rules go with the shape:

- **Families are siblings under the root, never members of one another.** A consuming layer's set (`sealed class HouseholdError extends AccountFailure`) sits *beside* the package's (`AccountError`); a seam that mixes the package's calls with the consumer's own is typed at the root, and neither family is translated on the way through. The paragraph above — datasources mapping *upward* — is about the rings inside one app, never a licence to wrap a sibling package's set.
- **Carve a family per concern, and leave the unrelated ones out.** One product may hold several `sealed` sets under its own open root (an AI add-on's, a sync engine's), and a concern whose failures never travel a seam the root's failures travel stays out of the hierarchy entirely — a serial link's failures carry their own fields, not a `message`. The test is the **seam**, not the topic: does this failure travel a seam the shared root's failures travel? Yes → a set beneath the root. No → its own hierarchy.
- **One name per fact.** A consuming layer that needs nothing new adds **no** leaf: its set carries no not-found or internal-error of the package's kind, so a caller's whole vocabulary is two names (the package's set, the product's). Re-voicing a shared refusal is **message-only** — return the same type carrying the product's sentence, and equality and any `switch` on that leaf keep working.
- **Leaves are `final`; a new leaf in a published set is MAJOR.** `final` is what stops a consumer extending a leaf and still switching exhaustively, and a new leaf stops every consumer's exhaustive `switch` compiling — a breaking release, not an additive one. Equality comes from the root, so a sub-root inherits `props` and declares no `Equatable` of its own.

### 4.3 Signatures

```dart
abstract class IAccountRepository {
  /// Returns the account with [accountHandle], or [AccountNotFound].
  Future<Either<AccountFailure, Account>> get({required String accountHandle});

  /// Returns every account, oldest first.
  Future<Either<AccountFailure, List<Account>>> list();

  /// Credits [amount] to the account with [accountHandle].
  Future<Either<AccountFailure, Account>> deposit(
      {required String accountHandle, required double amount});
}
```

Use cases return the same shape — and take **discrete business params, never cargo objects**:

```dart
/// Fetches a single account.
class GetAccountUseCase {
  final IAccountRepository _repository;
  const GetAccountUseCase(this._repository);

  /// Returns the account with [accountHandle], or [AccountNotFound].
  Future<Either<AccountFailure, Account>> call({
    required String accountHandle,
  }) => _repository.get(accountHandle: accountHandle);
}
```

### 4.4 Use-case parameters: business params, not cargo

A use case's `call()` takes the **actual business inputs** as discrete named parameters — `AddUserUseCase` receives `userHandle`, `userName`, `email`, … — never a cargo/container object (`AddUserUseCase(UserBlockOfStuff(...))`). An id is named after its entity and qualified by it (`userHandle`, `accountHandle`), never bare `id` or bare `handle`: the call site must read as the operation (§1.5).

Why:
- The signature *is* the documentation; a call site reads like the business operation.
- No anonymous container types to define, serialize, or pass across layer boundaries.
- A parameter list that outgrows ~4–5 business inputs is a smell: usually a missing entity or a use case doing too much. Reach for a domain entity (or value object) then, not a bag of fields.

### 4.5 Composition

- Chain with `flatMap` / `map` / `mapLeft`.
- For readability, use the **Do notation** (`fpdart` supports it) instead of nested flatMaps:

```dart
final result = await Either.Do(
  ($) async {
    final account = await $(repository.get(accountHandle: accountHandle));
    final updated = await $(repository.deposit(
      accountHandle: account.handle,
      amount: 100,
    ));
    return updated;
  },
);
```

- Convert third-party exceptions *at the adapter boundary only*: `TaskEither.tryCatch(() => ..., (e, st) => DatasourceFailure(...))`. The instant a third-party call throws, it becomes a `Left` and never propagates as an exception.

  "Adapter boundary" is a **line, not a zone**. The only try/catch-shaped code an adapter may contain is `TaskEither.tryCatch` (or `Either.tryCatch`) wrapping the third-party call itself, in the public adapter method; an exception never crosses the adapter's public API. Hand-rolled `try/catch` for imperative control flow inside an adapter is a violation — the adapter does not get a pass on the exception rule, it *owns the conversion seam* precisely because it is the code touching the throwing library.

### 4.6 Where the chain ends: the public seam

TaskEither is the **internal** composition type. The **default** public seam is `Future<Either<Failure, T>>` — repository contract methods and use case `call()` signatures are `Future<Either<...>>`, never `TaskEither<...>`.

- **Default: `.run()` terminates the chain at the public method boundary, inside the implementation.** A use case composes with TaskEither internally (`flatMap`, Do-notation, `tryCatch` at the adapter) and the last thing its `call()` does is `.run()` (or `await ... .run()`), returning the plain `Future<Either<...>>`.
- **Declared exception (§4.9): a package may hand the consumer the unrun `TaskEither` instead.** A CLI or Flutter consumer is then free to finish the chain itself (`flatMap`, Do-notation) and `.run()` it, *provided the package declares the style at the seam* — seeing a tuple is how the consumer knows to `.run()` it. This is not laziness escaping the core; it is a deliberate, documented seam.
- **What consumers never do: compose chains *across* a seam.** No consumer `flatMap`s a repository's chain into a chain a different package owns, smuggling layered lazy logic past the boundary. Chain-building through fpdart starts fresh in the layer that presents the tuple; the consumer runs the chain it was handed (or `fold`s the `Future<Either>` default).
- **Why the default stands:** laziness leaks out of the core, it becomes a UI problem (forgetting `.run()`, mutating captured lists inside lazy callbacks, debugging chains that "did nothing"). Any departure from the default must be declared (§4.9), never silent.

### 4.7 Equality: equatable

Domain entities and value objects get value semantics for `==` and `hashCode`, which fpdart pattern matching, testing, and drift row mapping all rely on. Use `equatable` where that rule applies — first and foremost your domain entities — rather than hand-written equality. The application form is not prescribed: either `extends Equatable` or, when the class already extends a base, `with EquatableMixin`, always paired with `List<Object?> get props => [...]`. Hand-written, no codegen.

### 4.8 The exception rule, stated once

**Inside the bulls-eye: no `throw`, no `try/catch` beyond the `tryCatch` conversion at adapter boundaries, no `on Exception`.** The UI ring is the *only* place exceptions are raised or caught, and even there they should be converted into UI state as fast as possible.

The "outermost ring" is wherever a delivery mechanism meets the outside world — the Flutter widget boundary (§8.1) *or* a CLI/TUI's composition root and `bin/` entrypoint. A headless CLI has no Flutter "UI ring"; its `bin/` `main` *is* the ring. A package that legitimately presents plain exceptions (§4.9) is that ring, not an exception to this section.

### 4.9 Declare the error style, clearly

Two error styles live in our estate and a consumer should never have to discover
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
  tuple is how a consumer knows to `.run()` it. Silence is the problem, never the
  choice.
- **Exceptions are never the default in the bulls-eye.** A package that presents
  them says where they are raised and caught (see *The exception rule*, §4.8) and
  keeps them out of domain and use cases.
- The declaration describes the **seam**, not the internals: a package with pure
  `TaskEither` internals may present `Future<Either<...>>`, and a package that
  presents tuples may still throw inside a widget. Internal composition never
  changes what the caller receives.
- Omitting the declaration costs a consumer exactly two bugs: a `TaskEither` that
  never ran, and an exception thrown across a seam they believed was a value.

---
