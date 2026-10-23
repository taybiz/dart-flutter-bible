# 7. Builders & Codegen: avoid, except drift

We **avoid codegen builders** wherever we can. Generated code hides logic, slows builds, breaks IDE navigation, and creates a second source of truth.

| Builder | Verdict |
|---|---|
| `build_runner` + `drift_dev` | ✅ **The exception.** Drift's ORM earns it. |
| `freezed` | ❌ Prefer `sealed` classes + records + exhaustive `switch` — Dart 3 does this natively now. |
| `json_serializable` | ❌ Hand-written `toJson`/`fromJson` (or a mapping function) for the small models we own; drift has its own serialization for rows. |
| `riverpod_generator` | ❌ Hand-written providers (`Provider`, `FutureProvider`, `NotifierProvider`) suffice — as do hand-written blocs/cubits, if the app's state layer is Bloc; no annotation codegen. |
| `injectable` | ❌ DI annotation codegen. Hand-wire at the composition root: constructors, or a plain container (`get_it`) if the project already carries one (§8.2). |
| `retrofit`/`dio_gen` | ❌ Hand-written HTTP datasource with `tryCatch`. |

Dart 3 replaces the most-tempting builders natively:

```dart
// No freezed needed — sealed classes + exhaustive switch are built in:
sealed class AccountFailure {}
final class AccountNotFound extends AccountFailure {
  final String handle;
  const AccountNotFound({required this.handle});
}
```

**The test for whether a builder earns its place:** does the generated code encode a contract we'd otherwise hand-maintain and get wrong (SQL table ↔ Dart row mapping)? Drift passes. Almost everything else fails.

---
