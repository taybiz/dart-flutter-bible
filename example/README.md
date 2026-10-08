# Bible Samples

Executable Dart samples of the doctrine in `docs/` — one class per file, one barrel per package, sealed failures, discrete business params, named params, terse doc comments, and shouldly Given/When/Then tests covering both Either sides.

## Layout

- `lib/src/` — entities, failures, contracts, use cases (one class per file)
- `lib/bible_samples.dart` — the single public barrel
- `test/` — the contract in action, both Either sides

## Running

The standard Dart toolchain checks this package (dart pub get, dart analyze, dart test); CI runs all three on every push and pull request.

This folder is part of the bible repo — it is deliberately not its own git repository.
