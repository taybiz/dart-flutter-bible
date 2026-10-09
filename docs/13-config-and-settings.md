# 13. Configuration & App Settings Management

Every CLI or TUI application needs a way for the user to configure it — persistent settings that survive restarts, override behavior, and compose with per-run flags.

### 13.1 The Precedence Chain

Configuration sources are **layered**. Higher-precedence sources override lower ones:

| Precedence | Source | When it applies |
|---|---|---|
| 1 (highest) | `--config` / `-c` CLI flag | The user explicitly pointed at a file |
| 2 | Environment variables | Per-session or system-level overrides |
| 3 (lowest) | Default config file | Platform-standard path, always loaded |

**Rule:** every source must be readable independently. If a source is absent (no `--config` flag, no env var, no config file at the default path), the next source down is used. If all sources are absent, the application uses its built-in defaults — never crash.

```
CLI --config path → reads that file (trumps everything)
  │
  ├─ key present?  → use that value
  └─ key absent?   → fall through to env vars
                        │
                        ├─ key set?  → use env var value
                        └─ key unset? → fall through to default config file
                                           │
                                           ├─ key in file? → use that value
                                           └─ key absent?  → use built-in default
```

### 13.2 CLI: `--config` / `-c`

Every CLI application **must** accept a `--config` / `-c` flag that accepts a path to a config file. When passed:

- That file is **the only** config file read — the default path is skipped entirely.
- It **trumps every environment variable** for keys it contains.
- A key *not* present in the specified file falls through to env vars → built-in defaults as normal.
- The file must exist and be readable; a missing or unreadable `--config` path is a hard error (print an error and exit non-zero). This is the one case where the app fails: the user told you exactly where to read.

```dart
// --config / -c — the highest-precedence source.
// Absent? Skip to env vars.
ArgParser()..addOption('config', abbr: 'c', help: 'Path to config file');
```

### 13.3 Environment Variables (env vars)

Environment variables are the **per-session override** — handy for CI, containers, shell aliases, and secrets the user doesn't want in a file.

- Env vars **always** trump values in the **default** config file.
- Env vars are **overridden** by values in a `--config`-specified file.
- Prefer a naming convention: e.g. `MYAPP_LOG_LEVEL`, `MYAPP_DB_PATH`.

```dart
final logLevel = Platform.environment['MYAPP_LOG_LEVEL'];
```

### 13.4 Platform-Appropriate Config Paths

The default config file location **must** follow OS conventions. Never hardcode `$HOME/.config/` on every platform.

| Platform | Default path | Convention |
|---|---|---|
| Linux | `$XDG_CONFIG_HOME/myapp/config` (or `$HOME/.config/myapp/config`) | XDG Base Directory |
| macOS | `$HOME/Library/Application Support/myapp/config` | Apple conventions |
| Windows | `%APPDATA%\myapp\config` (`C:\Users\<user>\AppData\Roaming\myapp\config`) | Windows known folders |

In Dart, build the path without `path_provider` (which is Flutter-only):

```dart
import 'dart:io' show Platform;

String defaultConfigPath(String appName) {
  if (Platform.isLinux) {
    return '${Platform.environment['XDG_CONFIG_HOME']
        ?? '${Platform.environment['HOME']}/.config''
      }/$appName/config';
  } else if (Platform.isMacOS) {
    return '${Platform.environment['HOME']}/Library/Application Support/$appName/config';
  } else if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData == null) throw StateError('APPDATA not set');
    return '$appData\\$appName\\config';
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}
```

Use the `path` package (`package:path/path.dart`) for robust path joining on every platform.

### 13.5 Config File Format

**YAML** is the default config format (readable, writable by hand, supports nested keys). The `yaml` package from pub.dev is the parser.

```yaml
# ~/.config/myapp/config
log:
  level: info
db:
  path: /var/lib/myapp/data
theme: dark
```

```dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

Map<String, dynamic> loadDefaultConfig(String appName) {
  final path = defaultConfigPath(appName);
  final file = File(path);
  if (!file.existsSync()) return {};
  final doc = loadYaml(file.readAsStringSync());
  // Cast to Map — loadYaml returns a dynamic YamlMap.
  return Map<String, dynamic>.from(doc as Map);
}
```

Alternatives accepted by convention:

- **JSON** — when the config is machine-generated or the project already depends on `dart:convert`.
- **TOML** — when the team standardises on it across projects.

Whatever the format, **document the config schema** in the project README and keep a default config file in the repo (`config.example.yaml`) so users can copy it.

### 13.6 Merging: Layered Config in Code

Read sources in **reverse precedence order** (lowest first) and overlay:

```dart
Config loadConfig({String? configPath}) {
  // 1. Start with empty defaults (or built-in constants).
  var config = Config();

  // 2. Load the default config file, if it exists.
  final defaultFile = File(defaultConfigPath('myapp'));
  if (defaultFile.existsSync()) {
    config = config.merge(parseFile(defaultFile));
  }

  // 3. Overlay env vars (only keys that are set).
  config = config.merge(parseEnvVars(Platform.environment));

  // 4. If --config was given, load THAT file (it trumps everything).
  if (configPath != null) {
    config = config.merge(parseFile(File(configPath)));
  }

  return config;
}
```

Because env vars trump the default config but are trumped by `--config`, the layering order naturally produces the right precedence: load defaults → overlay env → overlay explicit.

### 13.7 App Settings (persistent user preferences)

Not all settings belong in a config file. Distinguish:

| Concern | Config file | App settings |
|---|---|---|
| What it holds | Startup behaviour, connection strings, feature flags, secrets (via env) | User-facing preferences: theme, locale, window size, sort order |
| Who edits it | The user or sysadmin, with a text editor | The app itself, through a settings UI |
| When it's read | At startup (one-shot) | Any time (reactive, hot) |
| Persistence | Plain file, hand-editable | Structured store — sembast, drift, or `SharedPreferences` (Flutter) |

**Config file** is for startup parameters the user controls before the app runs. **App settings** are runtime preferences the app manages on the user's behalf.

For Flutter apps, use Riverpod providers for reactive settings with sembast or drift backing. For CLI/TUI apps, a plain JSON/YAML file at the same platform-standard path, read on startup and written on change, is sufficient.

### 13.8 Secrets

**Never put secrets in a config file checked into version control.** Secrets (API keys, tokens, passwords) belong in environment variables, a platform secret store (Windows Credential Manager, macOS Keychain, Linux secret-service), or a dedicated file sourced by the shell (`source .env`). The config file layer is for non-sensitive settings.

The `--config` flag is not a secrets workaround — a file on disk is no more secure than the user's home directory permissions.

### 13.9 Rule: Default Config + Env Override + CLI Override

Every CLI/TUI application **must** implement the three-layer precedence chain from §13.1. This is a CI-gated rule: the test suite must include at least one test per layer proving correct override behaviour (e.g. env var trumps default config, `--config` trumps env var, `--config` file missing exits non-zero).

---

**Sources of truth:**
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) (Linux)
- [File System Basics](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/MacOSXDirectories/MacOSXDirectories.html) (macOS)
- [Known Folders](https://learn.microsoft.com/en-us/windows/win32/shell/known-folders) (Windows)
- [`yaml`](https://pub.dev/packages/yaml) package on pub.dev
- [`path`](https://pub.dev/packages/path) package on pub.dev
