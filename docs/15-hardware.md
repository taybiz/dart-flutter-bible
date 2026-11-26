# 15. Hardware and the Platform

Flutter is the outermost ring (§8) — but it is not the edge. *Outside* it sits the platform: the OS, the sandbox, and the hardware a feature actually talks to. The doctrine does not stop at the widget boundary, and this is where that earns its keep: the same feature looks different on iOS, Android, Windows, and the browser, and a codebase that pretends otherwise grows a `Platform.isIOS` in its domain and a serial port it cannot open on half its targets.

This section is the platform ring — what the OS gives you, what it refuses, and how to keep all of it at the edge, behind an interface, so the center stays pure and portable.

### 15.1 The platform is an input, not a fork

**Apple platforms get the Cupertino look; every other platform gets Material.** iOS and macOS read as native when the widgets are Cupertino; Android, Windows, Linux, and the web read as native when they are Material. Default: one adaptive layer that picks by platform, not two hand-written apps.

- **Detect once, at the root.** Read the platform via `defaultTargetPlatform` — it is defined on web, desktop, and in tests, and can be stubbed — and set the theme's `platform` (or the app's design-system switch) in one place. **Never scatter `Platform.isIOS`** through widget code: `dart:io` is unavailable on the web, and a bare OS check puts an untestable branch in the tree.
- **Structure, not a package (§8.2).** Packages that render Cupertino-on-Apple and Material-elsewhere exist; the requirement is the *behavior* — one adaptive surface — not the library. The app picks; the doctrine states the rule.
- **The Apple-path trap.** A Cupertino page that hosts shared Material widgets (a `Switch`, `Checkbox`, `ListTile`, `Tooltip`) still needs a `Material` ancestor, or the build throws — and only on the Apple path, so a widget test that forces Cupertino is what catches it. Wrap the page body; the navigation bar sits *outside* that wrapper, so an adaptive control placed in it needs its own branch.

### 15.2 Hardware is an adapter, never the center

A serial port, a scale, a scanner, a printer, a radio, a camera — **all hardware I/O is a datasource**. Define the *port* in the domain (open/close, write bytes, a byte stream out) and implement it in adapters outside the center. `dart:io`, FFI, and plugin imports stay out of domain, use cases, and the pure-Dart core (§1.1.1): the core stays headless-buildable, and the hardware stays a detail you can swap.

**The at-least-two-adapter rule already expects this (§1.2).** A hardware seam that ships a native transport and a BLE transport is two adapters by construction — so it also owes the shared contract suite, run against a fake and against each real transport (§6). The use case cannot tell them apart: the same `write(bytes)` and `Stream<Uint8List> reads` whether the bytes went down a cable or a radio. That is the whole point of putting the port in the center.

### 15.3 Serial is native on desktop and impossible on iOS — so ship a BLE path

The platform reality, by target:

| Target | Serial access | The path |
|---|---|---|
| Linux | native | `/dev/tty*` · `/dev/serial/by-id/*` |
| macOS | native | `/dev/cu.*` (never `/dev/tty.*` — it blocks on open, waiting for DCD) |
| Windows | native via FFI | `COM<n>`; no `dart:io` serial, so a serial package or Win32 FFI (`CreateFile`/`SetupDi*`) |
| Android | possible | USB host (OTG) + a runtime permission, **or** BLE |
| **iOS** | **none** | no `/dev` node, and USB is gated behind Apple's MFi program (a licensed chip per accessory) — a USB-serial adapter that works on a laptop is invisible to an iPhone |
| Web / wasm | Chromium desktop only | Web Serial API; secure context; a user gesture; no `dart:io` |

**The rule that falls out: any product that talks serial must also ship a Bluetooth (BLE) path.** Native serial is a desktop nicety; on iOS it does not exist, and on Android it is a permission dance. A device with a UART gets a **BLE UART bridge** — a small BLE-to-serial dongle sitting between the app and the device — and the app talks to *that*. Ship both transports behind the one port from §15.2: the native path where the OS allows it, the BLE path everywhere.

### 15.4 BLE UART — the boring, standard transport

The conventional BLE serial bridge is the **Nordic UART Service (NUS)**: service `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`; the central **writes to the RX characteristic** (`6E400002-B5A3-F393-E0A9-E50E24DCCA9E`) and **receives on the TX characteristic** (`6E400003-B5A3-F393-E0A9-E50E24DCCA9E`) via notifications. The HM-10 and its clones, and most "BLE serial" modules, present the same shape or a vendor variant — so the adapter is small: scan for the service, subscribe to TX, stream bytes both ways.

Doctrine states the **requirement and the behavior, never the package** (the same stance as §8.2). A conforming BLE transport must:

- scan for and connect to the bridge;
- expose a byte stream in and out through the *same* interface as the native transport;
- **chunk writes to the negotiated MTU** — a payload longer than the MTU is the classic silent truncation, and the fix belongs to the transport, not to the caller;
- reconnect after a drop, surfacing a typed failure rather than throwing.

Which BLE package does it is the app's call.

### 15.5 Permissions are declared per platform, and asked at the moment of use

A hardware feature's platform wiring is mostly manifest and plist, and it is per-target:

- **iOS** — `NSBluetoothAlwaysUsageDescription` (the string the OS shows on the prompt), plus a background-mode justification if the link must survive backgrounding.
- **macOS** — the Bluetooth entitlement (`com.apple.security.device.bluetooth`) and the hardened-runtime entitlements; a sandboxed app without them sees no devices.
- **Android** — `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` for API 31+, the legacy `BLUETOOTH` + location permissions for older targets (with `neverForLocation` where you derive no location), and the runtime nearby-devices grant on 12+.
- **Web** — a user gesture is required; there is no background scan.

Never request at launch: ask at the moment the feature is used, and treat a denial as a **typed failure** — `Left(PermissionDenied)`, a value the use case returns (§1.1.4) — not an exception thrown into the core. The prompt itself is a UI-ring concern.

### 15.6 The filesystem is per-OS too

- Never assume a cwd, a home directory, or a path separator. Data and config live in the OS-convention location (§13 names the config path on each platform); **ask the platform for the path** (`path_provider`, or the config resolver) rather than composing it — Windows `%APPDATA%`, macOS `~/Library/Application Support`, Linux `$XDG_CONFIG_HOME` or `~/.config`.
- Prefer a pure-Dart path that already works everywhere to a platform channel you have to maintain; reach for FFI or a plugin only for what genuinely needs the OS (a Win32 console, a COM port, a device node).
- `dart:io` never enters the core — it is unavailable on the web and it drags the file system into the center (§1.1.1). File I/O is an adapter.

### 15.7 The platform is a test seam, not a CI machine

- **Hardware cannot be in the gate.** Test the *port*, not the device: the transport interface is exercised by an in-memory fake (a byte stream you drive), and the real adapter is a thin boundary exercised by a manual or opt-in test — nothing the gate needs plugged in. This is where the at-least-two-adapter rule earns its keep: the fake *is* the second adapter.
- Anything that cannot compile on the web (a native package) sits behind a conditional import, so the core and the web build still build.
- A feature whose behavior is proven against the fake needs no hardware in the gate; the real adapter is wiring to review, not a CI machine to provide.

---

The through-line is the same as everywhere: keep the OS and the device at the edge, behind an interface; the center stays pure, portable, and testable. A hardware feature is not an exception to the architecture — it is what the architecture was for.
