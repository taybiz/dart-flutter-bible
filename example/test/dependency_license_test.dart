// Dependency-license gate — bible §14.
//
// The ARTIFACT is every `pubspec.yaml` in the repo; the AUTHORITY is doctrine
// §14: a dependency's license is a fact about the product we ship, so it is
// labelled inline on the line that declares it, only a permissive license may
// ride without a recorded decision, and any copyleft dependency must be LOUD
// (§14.2.1). A dependency added with no comment — or a copyleft one wearing a
// quiet `# GPL-3.0-only` that reads as handled — is exactly the claim that rots
// quietly, so it is gated here instead of trusted.
//
// This is a rule test, not a behavior test: GWT naming and shouldly idioms for
// behavior suites apply (docs/06-testing.md).
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// Licenses a dependency may carry without a recorded decision (bible §14.2).
/// Compared case-insensitively; the doctrine asks for the canonical SPDX form.
const _permissive = <String>{
  'mit',
  'bsd-2-clause',
  'bsd-3-clause',
  'apache-2.0',
  'isc',
  'zlib',
  '0bsd',
  'unlicense',
  'cc0-1.0',
};

/// Weak copyleft — always avoid, and warned with ONE bang (§14.2.1): a
/// dependency carrying one passes only when its comment shouts `! WEAK COPYLEFT`.
const _weakCopyleft = <String>{'mpl-2.0'};

/// Strong copyleft — always avoid, and warned with THREE bangs (§14.2.1): a
/// dependency carrying one passes only when its comment shouts `!!! STRONG COPYLEFT`.
const _strongCopyleft = <String>{
  'gpl-2.0-only',
  'gpl-2.0-or-later',
  'gpl-3.0-only',
  'gpl-3.0-or-later',
  'lgpl-2.1-only',
  'lgpl-2.1-or-later',
  'lgpl-3.0-only',
  'lgpl-3.0-or-later',
  'agpl-3.0-only',
  'agpl-3.0-or-later',
};

/// The word every copyleft comment must carry, alongside its bang count (§14.2.1).
const _loud = 'COPYLEFT';

/// The dependency-declaring keys of a pubspec (bible §14.1).
const _depSections = <String>{
  'dependencies',
  'dev_dependencies',
  'dependency_overrides',
};

void main() {
  final root = _bibleRoot();
  final pubspecs = _pubspecs(root);
  final deps = <_Dep>[
    for (final file in pubspecs)
      ..._declaredDeps(
        p.relative(file.path, from: root.path),
        file.readAsStringSync(),
      ),
  ];

  test('the repo declares dependencies to label', () {
    // Population first: an empty selection would satisfy every rule below.
    pubspecs.length.should.beGreaterOrEqualThan(1);
    deps.length.should.beGreaterOrEqualThan(1);
  });

  test('every declared dependency carries an inline SPDX license comment', () {
    final unlabelled = <String>[
      for (final dep in deps)
        if (dep.license == null) dep.describe(),
    ];
    unlabelled.should.beEmpty();
  });

  test('every dependency license is permissive or a recognised copyleft', () {
    final barred = <String>[
      for (final dep in deps)
        if (dep.license != null && !_known(dep.license!)) dep.describe(),
    ];
    barred.should.beEmpty();
  });

  test('every copyleft dependency is labelled LOUDLY, scaled to the risk', () {
    final quiet = <String>[
      for (final dep in deps)
        if (dep.license != null &&
            _isCopyleft(dep.license!) &&
            !_loudEnough(dep.comment ?? '', dep.license!))
          dep.describe(),
    ];
    quiet.should.beEmpty();
  });
}

/// Whether [license] is a license this gate recognises — permissive, or a
/// copyleft it will pass only when loudly marked. Anything else (a
/// source-available id, a typo, an unstated license) is barred until a
/// deliberate decision widens the sets here.
bool _known(String license) {
  final id = license.toLowerCase();
  return _permissive.contains(id) ||
      _weakCopyleft.contains(id) ||
      _strongCopyleft.contains(id);
}

/// Whether [license] is copyleft — i.e. must be warned about (§14.2.1).
bool _isCopyleft(String license) {
  final id = license.toLowerCase();
  return _weakCopyleft.contains(id) || _strongCopyleft.contains(id);
}

/// Whether a copyleft [comment] warns at the right volume (§14.2.1): the word
/// `COPYLEFT`, plus one `!` for weak copyleft or three (`!!!`) for strong.
bool _loudEnough(String comment, String license) {
  if (!comment.contains(_loud)) return false;
  final bangs = RegExp(r'!').allMatches(comment).length;
  return _weakCopyleft.contains(license.toLowerCase())
      ? bangs >= 1
      : bangs >= 3;
}

/// A declared dependency and the inline comment the line carries.
class _Dep {
  _Dep(this.location, this.name, this.comment);

  /// `pubspec.yaml:line` — enough to act on without re-opening the file.
  final String location;
  final String name;

  /// The full inline comment, or null when the line carries none.
  final String? comment;

  /// The SPDX identifier — the comment's first token — or null with no comment.
  String? get license {
    final text = comment?.trim();
    if (text == null || text.isEmpty) return null;
    return text.split(RegExp(r'\s+')).first;
  }

  String describe() => '$location ($name: ${comment ?? 'no license comment'})';
}

/// The bible root, found by walking up from the test's CWD — `dart test` runs
/// with the package root as CWD, and this package sits one level below the root.
Directory _bibleRoot() {
  var dir = Directory.current.absolute;
  while (!File(p.join(dir.path, 'docs', '00-compact.md')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail(
        'No bible root (docs/00-compact.md) above ${Directory.current.path}',
      );
    }
    dir = parent;
  }
  return dir;
}

/// Every `pubspec.yaml` under [root], skipping VCS metadata, build output and
/// symlinked plugin trees, sorted. Symlinks are not followed, so a Flutter
/// member's ephemeral `.plugin_symlinks/` cannot drag in dependency pubspecs.
List<File> _pubspecs(Directory root) {
  final skip = RegExp(r'(^|/)(\.git|\.dart_tool|build|\.plugin_symlinks)(/|$)');
  final files = <File>[
    for (final entity in root.listSync(recursive: true, followLinks: false))
      if (entity is File &&
          p.basename(entity.path) == 'pubspec.yaml' &&
          !skip.hasMatch(p.relative(entity.path, from: root.path)))
        entity,
  ];
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

/// The dependency lines a pubspec declares, in file order. Only the dependency
/// sections count, and only their two-space keys — a nested key of a map-form
/// dependency (four spaces) is a field of the dependency, not a dependency.
List<_Dep> _declaredDeps(String pubspecPath, String text) {
  final deps = <_Dep>[];
  String? section;
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    final header = RegExp(r'^([A-Za-z_][\w-]*):\s*(#.*)?$').firstMatch(line);
    if (header != null) {
      final key = header.group(1)!;
      section = _depSections.contains(key) ? key : null;
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ')) {
      section = null; // any other top-level key leaves the dependency block
      continue;
    }
    if (section == null) {
      continue;
    }

    final entry = RegExp(r'^ {2}([A-Za-z0-9_-]+):').firstMatch(line);
    if (entry == null) {
      continue;
    }
    final hash = line.indexOf('#');
    final comment = hash == -1 ? null : line.substring(hash + 1).trim();
    deps.add(
      _Dep(
        '$pubspecPath:${i + 1}',
        entry.group(1)!,
        (comment == null || comment.isEmpty) ? null : comment,
      ),
    );
  }
  return deps;
}
