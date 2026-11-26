# 12. Sources of Truth

- **This document.** The bible. Canonical.
- Skill: `dart-clean-architecture` (procedures, pitfalls, reference files) — loads this doc on bootstrap/review.
- `example/` — `bible_samples`: gate-tested executable samples of the doctrine (`dart analyze --fatal-infos --fatal-warnings` + `dart test`, via `melos run verify`).
- [Dagger](https://dagger.io) — the recommended container engine for running the melos gate (§2.10); recommended, not required.
- [Melos migration guide](https://melos.invertase.dev/~melos-latest/guides/migrations) — melos.yaml → pubspec workspace migration.
- [Melos changelog](https://github.com/invertase/melos/blob/main/packages/melos/CHANGELOG.md) — where script-schema breaks and `analyze` fixes land first; check it before pinning (§2).
- [dart_arch_test](https://pub.dev/packages/dart_arch_test) — ArchUnit-style architecture tests over the resolved import graph (`package:` URIs); the CI gate for package-boundary direction.
- [Drift docs](https://drift.simonbinder.eu/) — ORM, DAOs, custom executors.
- [fpdart](https://pub.dev/packages/fpdart) — ^1.2.0 stable; v2-dev off-limits.
- [shouldly](https://pub.dev/packages/shouldly) — the "should be" idiom.
- [mocktail](https://pub.dev/packages/mocktail), [equatable](https://pub.dev/packages/equatable) (latest stable major — `3.x` today; not pinned), [sembast](https://pub.dev/packages/sembast).
- [defaultTargetPlatform](https://api.flutter.dev/flutter/foundation/defaultTargetPlatform.html) — the platform input an adaptive UI reads (§15.1); defined on web, desktop, and in tests.
- [Nordic UART Service (NUS)](https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/libraries/bluetooth/services/nus.html) — the standard BLE serial bridge (write to RX `…0002…`, receive on TX `…0003…`); what a BLE UART adapter speaks (§15.4).
- [Web Serial API](https://developer.chrome.com/docs/capabilities/serial) — Chromium-desktop serial access for the web target (§15.3).

---
[Home](Home) · [README](https://github.com/taybiz/dart-flutter-bible)
