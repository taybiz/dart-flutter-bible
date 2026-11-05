# <Project Name>

`<package_name>` — <one paragraph: what this is, who it is for, and what it is not. Orientation only — no rules, no architecture, no example code (bible §1.6).>

## Getting started

```bash
dart pub get
dart run melos run verify
```

Individual tasks: `dart run melos run analyze`, `dart run melos run test`.

## Docs

- How we build — architecture, testing, toolchain (doctrine): the [Dart/Flutter Bible](https://github.com/taybiz/dart-flutter-bible).
- This repo's local wiring and any deviations from the bible: [`AGENTS.md`](AGENTS.md).

## Error style

Consumers get `<Future<Either<Failure, T>> via fpdart | plain exceptions at the CLI/UI edge>` — the barrel's doc comment is the authority (bible §4.9). Delete this section if the repo publishes no package.

## License

MIT — see [LICENSE](LICENSE).
