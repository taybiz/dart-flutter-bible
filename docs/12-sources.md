# 12. Sources of Truth

- **This document.** The bible. Canonical.
- Skill: `dart-clean-architecture` (procedures, pitfalls, reference files) — loads this doc on bootstrap/review.
- `examples/` — `bible_samples`: CI-tested executable samples of the doctrine (dart analyze --fatal-infos --fatal-warnings + dart test on every push).
- [Melos migration guide](https://melos.invertase.dev/~melos-latest/guides/migrations) — melos.yaml → pubspec workspace migration.
- [Melos changelog](https://github.com/invertase/melos/blob/main/packages/melos/CHANGELOG.md) — where script-schema breaks and `analyze` fixes land first; check it before pinning (§2).
- [Drift docs](https://drift.simonbinder.eu/) — ORM, DAOs, custom executors.
- [fpdart](https://pub.dev/packages/fpdart) — ^1.2.0 stable; v2-dev off-limits.
- [shouldly](https://pub.dev/packages/shouldly) — the "should be" idiom.
- [mocktail](https://pub.dev/packages/mocktail), [equatable](https://pub.dev/packages/equatable), [sembast](https://pub.dev/packages/sembast).
