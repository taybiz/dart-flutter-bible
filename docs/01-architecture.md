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

1. **1.1.1** — **Dependencies point inward**, without exception. Domain knows nothing about application, UI, or datasources. Application knows domain. UI knows everything *through interfaces*. Nothing outside the center knows anything concrete about it.
2. **1.1.2** — **Entities are the center.** Pure Dart classes: immutable (`const` constructors), value equality (`equatable`), no I/O, no Flutter imports. Operations return **new instances**.
3. **1.1.3** — **Flow runs one way:** UI → use case → repository interface → datasource adapter. No sideways jumps, no UI talking to a datasource, no use case instantiating a widget.
4. **1.1.4** — **Exceptions belong to the UI boundary.** Everywhere inside the bulls-eye, failure is a *value* (fpdart `Either`/`TaskEither`). Only the outermost ring may throw or catch: failures are typed values you return, not control flow you jump through.

In code, the flow looks like this:

```dart
// UI ring — the only place exceptions live:
final result = await getAccount(accountHandle: accountHandle);
result.fold((failure) => ErrorView(failure), (account) => AccountView(account));

// Application ring — a use case is a thin coordinator:
Future<Either<AccountFailure, Account>> call({required String accountHandle}) =>
    _repository.get(accountHandle: accountHandle);
```

### 1.2 The At Least Two Repository Adapter Rule

**Every repository contract gets at least two repository adapters.** One real persistence adapter is not enough — with only one adapter, the contract is whatever that adapter happens to do. Two adapters (say drift/sqlite + in-memory, or drift + sembast) force the contract back to being the *interface*, and a shared **contract test suite** runs against every adapter, so a deviation in any implementation fails CI.

In-memory adapters count as a legitimate second adapter, and they double as the test double for use-case tests — prefer them over mocking where you can.

**A package that publishes no adapter is outside this rule** — its deliverable *is* the contract, and there is no implementation of ours to vary (§3.6, *Deliverable type decides which rules bind*). Nothing else about it relaxes: the contract suite still ships, and it still takes any implementation.

### 1.3 Don't Repeat Yourself (D.R.Y.)

Doctrine lives here, in exactly one place. Repo docs (README, AGENTS.md) and code comments **reference** a rule; they never restate it — a second copy is a second truth the moment the first one changes.

- The bible is the doctrine source. A repo's AGENTS.md records only that repo's deviations and local wiring; READMEs orient (what it is, how to run it) and carry no rules or architecture — the README's own contract is §1.6.
- If a rule already exists, link to it — do not copy it into another doc.
- Any fact stated twice will drift; when two copies disagree, both are suspect and the fix is deletion, not reconciliation.
- **Repo docs hold separate jobs so none of them becomes a diary.** The repo's queue — a root `BACKLOG.md`, or a Backlog.md `backlog/` board where the repo has adopted one — is a queue, not a warstory: one terse entry per unique, actionable item, each pick-up-able whole by automation — never a narrative, rationale, or metanarrative. The keen, non-obvious decisions and the *why* belong in `CHANGELOG.md`; the "keep your footing here" operational knowledge (deviations, local wiring, pitfalls) belongs in `AGENTS.md`. A fact that lands in two of these will drift — move it to its one home, don't restate it.
- **Deviation triage — a rule–repo conflict is one of two things; decide which and act.** When this repo's code contradicts the bible: if the bible is vague or outright wrong such that the repo **must live with** the divergence, record it in `AGENTS.md` as a deliberate deviation — name the rule and the divergence so every later agent stops fighting it. If the divergence is a **fixable defect** (the code is clearly in the wrong, the fix makes sense), do *not* record it as a deviation — add one terse item to the repo's queue (`BACKLOG.md` or its board) to fix it. A deviation you can fix is a queue item, never an accepted divergence.

### 1.4 The API surface (docs, params, style)

- **Terse docs:** declarations and their public members get a `///` comment, 1–2 lines — *what* and *why*, never *how*. Never at the top of a file (that forces a `library;` directive — for barrels only). dartdoc/pub.dev-ready; the `public_member_api_docs` lint stays on. Use cases **must** be documented.
- **Business params:** a use case's `call()` takes discrete business inputs (`userHandle`, `userName`, …), never a cargo object (`AddUserUseCase(UserBlockOfStuff(...))`). An id is named after its entity, never bare (§1.5). The signature is the documentation.
- **Named parameters** in Dart — sole exceptions: a single positional `ref`, `message`, or `value`. Flutter widgets follow Flutter conventions.
- **One barrel per package:** `lib/<package>.dart` hand-exports the public API from `lib/src/`; never import `src/` across packages. What's in the barrel *is* the public API.

### 1.5 Ids and handles: each layer names the id in its own terms

An id has three owners — the business layer's handle, the wire's key, the store's column — and one value. Name it in the layer that speaks it; the adapter is where the vocabularies meet.

- **Business code says the handle, qualified by its entity.** A use case's `call()` and the facade name the id after what it identifies: `accountHandle`, `deckHandle`, `cardHandle`, `mediaHandle`, `sessionHandle`. The entity's field carries the bare name (`final String handle;`) — the class is its qualifier. Never bare `handle` in a use case or the facade: a signature should say what it takes, and two ids in one signature say which is which without a doc comment.
- **Adapters may say `id`.** DTOs, codecs, document readers and writers speak the wire's vocabulary, because that is what the wire does — a document's card is `id`, a picture is `handle`. A repository adapter's public methods are the domain contract's and keep the business names; its DTOs and mapping helpers are free to say `id`.
- **Stored keys are data and keep their names.** A column, a JSON key, a map key belongs to whoever wrote the store; renaming it in business code renames nothing on disk. Only the adapter knows both names, which is why the translation lives there.
- **The map is written down in the repo's `AGENTS.md`** — one row per id: storage key ↔ business handle. That is local wiring, not doctrine, so it lives in the repo (§1.3); the adapter reads the map, business code never guesses.

The split costs a rename at each boundary and a table to keep current, and earns it back at the seam: `Account(handle: json['id']!)` is visibly a translation, so a wrong key fails review instead of travelling as a plausible string. A single name for all three hides the seam — and the seam is the only place the store's vocabulary can leak into a signature.

### 1.6 The README: orient, never dictate — and never go stale

A README answers one question — *what is this, and how do I start it?* — and stops. It is the front door, not the rulebook. A README that tells you how the work must be done, or states a fact the code already owns, is a second copy of something: it drifts the moment that something moves, and the reader has no way to tell which of the two is the lie.

- **The closed list.** A repo README carries the name (matching `pubspec.yaml`), one paragraph of what this is and who it is for, how to get it running (the real commands, taken from the script contract — §2.1), where the docs live (the bible for doctrine, `AGENTS.md` for this repo's local wiring), and license or status when it isn't obvious. Nothing else. Anything else is doctrine (link it), local wiring (`AGENTS.md`), a decision and its *why* (`CHANGELOG.md`), or work to be done (the repo's queue: `BACKLOG.md` or its board).
- **The dictate test.** Two kinds of sentence live here. *What this is* — orientation. *How you must work* — an instruction, and instructions are doctrine: "all persistence goes through a `UnitOfWork`" belongs in §5, not on a front door. Read every imperative in a README; if it is telling a developer what the rules are, it is doctrine in the wrong file — delete it and link the rule.
- **The staleness test — the one that actually bites.** The rot that costs you is not duplication, it is age: a command whose flag was renamed, a package name that changed, a port that moved, an error style that flipped from exceptions to `Either`. Every operational claim a README makes must be true of the code **as of the commit that carries it**, and the change that makes one false is the change that fixes it — same commit. A README that has been wrong for three weeks makes every other document in the repo suspect.
- **Point, don't copy.** A copy can contradict its source; a pointer cannot. So a README names the thing instead of restating it — the script (`melos run test`), the schema file (`config.example.yaml`), the barrel. A README *may* state a declaration about this package's own public surface — the error style is the case §4.9 requires (§10.20) — and where it does, the barrel's doc comment is the authority and the README says the same words, not a paraphrase.
- **If a claim can be checked, check it — don't trust the sentence.** "The README is truthful" is a test, not a hope. The links and paths it names resolve; the melos script it tells you to run exists in the `melos:` block; the package it titles itself with is the `name:` in `pubspec.yaml`. Machine-check what a machine can check (§2.8) and keep only the register in review.

---
