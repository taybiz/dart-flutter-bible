# Bible Samples

`bible_samples` — executable Dart samples of the bible's doctrine (see [Docs](#docs)): one class per file, one barrel per package, sealed failures, discrete business params, named params, terse doc comments, and shouldly Given/When/Then tests covering both Either sides.

## Getting started

```bash
dart pub get
dart run melos run verify
```

Individual tasks: `dart run melos run analyze`, `dart run melos run test`.

## Docs

- How we build (doctrine): the [Dart/Flutter Bible](../README.md).
- What is in here: `lib/src/` is private, `lib/bible_samples.dart` is the only public door, `test/` is the contract in action.

This folder is part of the bible repo — it is deliberately not its own git repository.
