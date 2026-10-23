# 5. Persistence Doctrine

### 5.1 Contracts live in the domain

`thing_domain` defines `IAccountRepository` and `IAccountDatasource` (if the repository needs a datasource seam). The domain package owns the *contract*; it owns no implementation.

### 5.2 The At Least Two Repository Adapter Rule in practice

For every repository:

1. **Primary adapter** — drift/sqlite (or the platform-appropriate store).
2. **Second adapter** — in-memory (fast, hermetic tests) or a different store (sembast) when the deployment needs a portable file store.
3. **Contract test suite** — one `test/` file that takes any adapter implementation and asserts the full contract, run against **every** adapter in CI. A contract is only real when two implementations agree on it.

**A package that publishes no adapter is outside this rule** (§3.6): it ships the contracts and the implementation is the consumer's, so there is nothing of ours to vary. The suite obligation is unchanged — one suite that takes *any* implementation, so a consumer's adapter can be run against it. A reference implementation may still live in the repository, but it does not ship in the published archive.

### 5.3 sqlite3: drift is the ORM, always

- **`drift`** (+ `drift_dev`, `build_runner`) for any sqlite3 persistence. This is the **sanctioned exception to the no-builders rule** (§7) — the ORM layer earns codegen.
- Tables are `@DataClassName`-annotated Dart classes; DAOs and queries are generated.
- **Tests use `NativeDatabase.memory()`** — no files, no platform channels, fast:

```dart
final db = ThingDatabase(NativeDatabase.memory());
```

- If a second file-based adapter is needed and it can share the drift data layer (a custom `QueryExecutor`), use it — but don't force it. A plain sembast adapter behind the same datasource contract is fine and often simpler.

### 5.4 File-based stores: sembast

- **sembast** is the default pure-Dart embedded file store (1 file = 1 database, works on every platform, no plugin).
- **Tests use `databaseFactoryMemory`** from `package:sembast/sembast_memory.dart`:

```dart
final db = await databaseFactoryMemory.openDatabase(inMemoryDatabasePath);
```

- Use sembast when a NoSQL document store is the right shape, or when "one file, zero plugins" matters. SQL-shaped data goes to drift.

### 5.5 UnitOfWork: the transaction seam sits at the operation

Atomicity belongs to a business **operation**, not to a single write — "delete this article and the model it orphaned", "update this SKU and its parts". Some stores are transactional (drift, sembast, isar), some are not (plain JSON files). So the seam sits on the operation, and the repository contract stays plain:

```dart
abstract interface class IAccountRepository {
  /// Returns the account with [accountHandle].
  Future<Either<AccountFailure, Account>> get({
    required String accountHandle,
  });

  /// Creates an account.
  Future<Either<AccountFailure, Account>> create({
    required String accountHandle,
    required String holder,
  });
}
```

```dart
class CreateAccountUseCase {
  final IAccountRepository _repository;
  final UnitOfWork _unitOfWork;

  /// Wraps the [repository] the use case delegates to, inside the required
  /// unit of work.
  const CreateAccountUseCase(this._repository, {required UnitOfWork unitOfWork})
      : _unitOfWork = unitOfWork;

  /// Creates the account, or [AccountAlreadyExists].
  Future<Either<AccountFailure, Account>> call({
    required String accountHandle,
    required String holder,
  }) => _unitOfWork<AccountFailure, Account>(
    body: () => _repository.create(accountHandle: accountHandle, holder: holder),
  );
}
```

- **`UnitOfWork` is a function type, not a class** — take a body, run it, answer with the body's own `Either`:

```dart
typedef UnitOfWork = Future<Either<F, T>> Function<F, T>({
  required Future<Either<F, T>> Function() body,
});
```

  It is `Either`-aware because **rollback is a value, not an exception**: a body that fails answers `Left`, the adapter undoes the writes, and `F` stays the *caller's* failure type. Assigning a closure to this type is checked at the exact signature, so a transactional adapter writes a closure over its own client and keeps its state for free.
- **An operation that must be atomic takes one as a required constructor dependency.** Required rather than optional, because an optional `uow` lets `DeleteInstance(instanceHandle: x)` compile and quietly mean *no transaction* — the same thing a store that cannot roll back means, with nothing at the call site to tell them apart. The criterion that picks the set: the operation **steps more than once**, or it **decides a rule by reading and then writes**. A single read steps once and takes nothing. The seam is infrastructure, so it goes on the constructor — the business signature stays `call({required String accountHandle})`.
- **"This store cannot roll back" is stated once, at the composition root**, by wiring `noOpUnitOfWork`. *Required* means the dependency is *stated*, not that a transaction is *implemented*: a memory or JSON store passes the no-op and writes no adapter.
- **An operation that composes others owns the only unit** and builds the pieces it composes itself, wired with the no-op — so a unit never nests. Stores are not obliged to support nested transactions (SQLite has none).
- **Enrollment is per operation, not per write.** A consumer hands their own `UnitOfWork` to the operation they construct. They cannot take a single write of one into their own transaction, because a write is not the unit of atomicity.

### 5.6 UnitOfWork pitfalls (what we have hit in practice)

- **Transactional adapters: keep the native client on the txn for the whole body run.** The unit of work must `await body()` *inside* the native transaction callback (e.g. sembast's `db.transaction((txn) async { await body(); })`) — the adapter's `client` stays the transaction client for the entire run. Resetting to the root client early deadlocks: DB-client operations wait on the still-open transaction (sembast deletes hang).
- **Take the write lock when the unit opens, not at its first write.** On SQLite that is `BEGIN IMMEDIATE` rather than the deferred default: a deferred unit reads an unprotected snapshot, so a rule's check can be beaten by a concurrent writer and the loss surfaces as a store error (`database is locked`) instead of a domain failure. Holding the lock from the start is what makes a check and the write that follows it one step — which is why a rule-carrying operation takes the seam at all.
- **Route every repository call through the open transaction, reads included.** The repositories are never handed the unit of work, so the adapter publishes it for the duration and clears it in a `finally`. A read on another connection does not hang; it answers from the *pre-transaction* snapshot. For a check that is worse than a failure, because nothing reports it.
- **Treat a busy store as "this unit did not happen" and retry the whole unit.** SQLite rolls the transaction back on a failed lock upgrade in journal mode and leaves it open in WAL, so an adapter may assume neither state: set a busy timeout or retry with a bound. Rollback is a *value* here; retry is the adapter's business.
- **Re-entrance means joining the open unit, not opening a second one.** A consumer may run a catalog write inside their own unit of work — that is what the seam is for. If one is already open on this client, run the body inside it rather than starting another: SQLite answers a nested `BEGIN` with "cannot start a transaction within a transaction". Reach for a `SAVEPOINT` only when the inner unit must roll back on its own. (drift's `transaction()` nests via savepoints and absorbs this; raw `package:sqlite3` leaves the branch to you.)
- **A wipe across many stores is one unit of work, so it rolls back whole.** The operation that wipes owns the unit; nothing on the contracts is needed for it. A mid-clear failure rolls the whole wipe back rather than leaving half a database. Non-transactional stores emulate (JSON: buffer the single doc, write once on success, discard the buffer on failure) or sink (memory: synchronous, nothing can fail; `noOpUnitOfWork`).
- **State-layer invalidation is not a wipe.** In the UI ring, invalidating the adapters (a provider rebuild, a bloc re-creation) only re-wires them — rows in a persistent store survive (sembast/IndexedDB/sqlite). Tests that omit real overrides use in-memory adapters and never see this; regression-test the clear/wipe path with the real persistent adapter in memory mode (e.g. `databaseFactoryMemory`).

### 5.7 General rules

- Repositories orchestrate and validate; datasources do mechanical I/O. No business logic in a datasource, no I/O in a repository.
- All datasource methods return `Either`/`TaskEither` with the datasource failure hierarchy. `tryCatch` lives here.
- **The adapter owns the naming map (§1.5).** Repository methods keep the business names (`accountHandle`); DTOs, codecs, document readers and writers may say `id`, because that is the wire's word. Stored keys keep their names, and the key↔handle map lives in the repo's `AGENTS.md` — the adapter translates, business code never guesses.

---
