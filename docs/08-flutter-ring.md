# 8. Flutter: The Outer Ring (1/3 of the bible)

Flutter is delivery. All the doctrine above applies *behind* it; this section is about the boundary.

### 8.1 Exceptions live here

- This is the **only** place `throw` and `try/catch` appear.
- A use case returns `Either<AccountFailure, Account>`; the widget/controller layer `fold`s it into UI state (loaded / error message / empty). The error message text is derived from the failure type at the boundary — domain failures never carry display strings.
- Third-party UI/plugin exceptions (image decode, platform channel) get caught here, converted to a user-visible state, and logged. Never swallowed.

### 8.2 State management

**Riverpod with plain providers** (`flutter_riverpod`) — settled doctrine, no generator (`riverpod_annotation` is banned, §7). Use cases are exposed as providers; widgets reach use cases through providers and never see repositories, datasources, or entity construction. fpdart's own docs and examples use Riverpod, so the integration is well-trodden.

**Riverpod NEVER enters the core.** Zero `flutter_riverpod` imports in domain, use cases, or datasource packages — the core is pure Dart (§3) and must stay buildable headless. If a core package "needs" a provider, the design is wrong: the use case is the seam, and the provider wraps *it*. Riverpod lives in the UI ring only — `flutter_riverpod` may appear only in the Flutter app's composition root and widgets/providers.

### 8.3 The only seam: use cases

**Widgets interact with exactly one thing: use cases** (normally reached through providers). Hard rule, not a preference:

- No widget imports a repository, a datasource, or an entity-construction factory.
- No widget reads a database, HTTP client, or platform storage — directly, or through a provider that skips the use-case seam.
- Providers wrap use cases and expose derived state (loading / data / failure). A widget's job: call use case → render state.

```dart
// Provider wraps the use case — the only seam a widget sees:
final accountProvider = FutureProvider.autoDispose<Account>((ref) async {
  final result = await ref.watch(getAccountUseCaseProvider)(id: accountId);
  return result.fold((f) => throw const AccountLoadException(), (a) => a);
});

// Widget: call use case → render state. No repository, no datasource, no factories.
class AccountView extends ConsumerWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(accountProvider).when(
            data: (account) => Text(account.holder),
            error: (_, __) => const Text('could not load'),
            loading: () => const CircularProgressIndicator(),
          );
}
```

### 8.4 Widget conventions

- **Dumb widgets:** widgets render state and emit events; they do not contain business rules, validation, or storage logic.
- One-direction flow: event → provider → use case → state → widget rebuild.
- Keep `build` methods small; extract `StatelessWidget`/`const` sub-widgets.
- No `BuildContext` passed into use cases or repositories, ever.
- **Pitfall (field report): don't move a widget under a stationary cursor if you rely on `MouseRegion.onExit`.** Flutter deliberately does not fire `onExit` when a widget moves beneath a stationary pointer (flutter/flutter#44957) — inside a `ListView` the mouse tracker silently drops the annotation. A warning rendered ABOVE a button pushed the button down ~52px on arming, so the armed state never disarmed and the pointer was left hanging over the warning. Keep the button stationary; render warnings below it, or sync the armed state from state rather than exit events.

### 8.5 Flutter tests

- Widget tests at `apps/thing_flutter/test` — pump with a test provider container (real in-memory adapters, not mocks, where possible), assert with shouldly.
- `NativeDatabase.memory()` and `databaseFactoryMemory` work in widget tests too — no platform-channel stubbing needed for the persistence path.

- **Integration tests are the deterministic GUI gate (§6.6).** `flutter test integration_test/…` drives the real app end-to-end in CI — real widgets, real navigation, real adapter wiring — and is required on GUI-changing work. Widget tests alone are not the gate.

- **Marionette is the dev-time agent layer, debug-only.** Initialize `MarionetteBinding` **only** under `kDebugMode` — no release surface:

```dart
void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  runApp(const MyApp());
}
```

  `marionette_flutter` is a real UI-ring dependency; `marionette_mcp` (the MCP server) is a **dev tool** — `dart pub global activate marionette_mcp`, never an app dependency. It connects an agent to the running app over the VM-service URI to inspect/`tap`/`enter_text`/`take_screenshots`/`get_logs` for smoke-testing (§6.6). Custom design systems need a `MarionetteConfiguration` before the agent can see bespoke buttons/fields. It is *not* the gate.

---
