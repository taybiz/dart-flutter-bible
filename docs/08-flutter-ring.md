# 8. Flutter: The Outer Ring (1/3 of the bible)

Flutter is delivery. All the doctrine above applies *behind* it; this section is about the boundary.

### 8.1 Exceptions live here

- This is the **only** place `throw` and `try/catch` appear.
- A use case returns `Either<AccountFailure, Account>`; the widget/controller layer `fold`s it into UI state (loaded / error message / empty). The error message text is derived from the failure type at the boundary — domain failures never carry display strings.
- Third-party UI/plugin exceptions (image decode, platform channel) get caught here, converted to a user-visible state, and logged. Never swallowed.

### 8.2 State management & dependency injection

**The requirement is structure, not a package.** House default: **Riverpod with plain providers** (`flutter_riverpod`), no generator (`riverpod_annotation` is banned, §7) — fpdart's own docs use it, so the integration is well-trodden. **Bloc/Cubit (`flutter_bloc`) and any comparable structured solution satisfy doctrine just as well**; the project picks, once per app. Whatever holds the state, doctrine insists on this much:

- **App state lives in an explicit state layer** — providers, blocs/cubits, notifiers — one that is testable without pumping a widget tree. Widget-local `setState` is for ephemeral UI (a toggle, an animation), never for a use-case result.
- **The state layer wraps use cases** and exposes derived state (loading / data / failure). Widgets reach use cases through it and never see repositories, datasources, or entity construction (§8.3).
- **One-direction flow, and no business logic in the state layer.** Validation, mapping, and decisions belong to use cases; a state holder translates events into use-case calls and results into state.
- **One approach per app.** Riverpod in one feature and Bloc in the next is two truths about wiring — mixing buys nothing and costs onboarding.
- **State packages live in the composition and presentation rings — never the domain ring.** Zero `flutter_riverpod`, `flutter_bloc`, or peer imports in domain, use cases, or datasource packages — the core is pure Dart (§3) and must stay buildable headless. If a core package "needs" a provider, the design is wrong: the use case is the seam, and the state layer wraps *it*. Riverpod, Bloc, and friends appear only in the UI ring: composition root, state holders, widgets.

**Dependency injection: wire it at the composition root.** Construct and hand-pass by hand in `main.dart` (the default), or use a service locator (`get_it`) when a project already carries one — either is fine as long as the composition root is the only place that resolves, core packages take their dependencies through their constructors, and no widget resolves its own. Annotation-codegen DI (`injectable`) is a builder and stays out (§7).

### 8.3 The only seam: use cases

**Widgets interact with exactly one thing: use cases** (reached through the app's state layer, §8.2). This is a rule, not a preference:

- No widget imports a repository, a datasource, or an entity-construction factory.
- No widget reads a database, HTTP client, or platform storage — directly, or through state that skips the use-case seam.
- The state layer wraps use cases and exposes derived state (loading / data / failure). A widget's job: call use case → render state.

```dart
// Riverpod (the house default): a provider wraps the use case — the only seam a widget sees:
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

```dart
// Bloc/Cubit: the same seam, same use case — the cubit just holds the state.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._getAccount) : super(const AccountLoading());

  final GetAccountUseCase _getAccount;

  Future<void> load(String id) async => emit(
        (await _getAccount(id: id)).fold(
          (f) => const AccountFailed(),
          AccountLoaded.new,
        ),
      );
}
```

### 8.4 Widget conventions

- **Dumb widgets:** widgets render state and emit events; they do not contain business rules, validation, or storage logic.
- One-direction flow: event → state layer → use case → state → widget rebuild (§8.2).
- Keep `build` methods small; extract `StatelessWidget`/`const` sub-widgets.
- No `BuildContext` passed into use cases or repositories, ever.
- **Pitfall (from practice): don't move a widget under a stationary cursor if you rely on `MouseRegion.onExit`.** Flutter deliberately does not fire `onExit` when a widget moves beneath a stationary pointer (flutter/flutter#44957) — inside a `ListView` the mouse tracker silently drops the annotation. A warning rendered ABOVE a button pushed the button down ~52px on arming, so the armed state never disarmed and the pointer was left hanging over the warning. Keep the button stationary; render warnings below it, or sync the armed state from state rather than exit events.

### 8.5 Flutter tests

- Widget tests at `apps/thing_flutter/test` — pump with the app's state layer wired to real in-memory adapters (a `ProviderScope`/`ProviderContainer` for Riverpod, a cubit over real adapters otherwise), not mocks where possible; assert with shouldly.
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
