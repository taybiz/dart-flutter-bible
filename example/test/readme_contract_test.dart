// README contract gate — bible §1.6, §2.8, §9.12.
// The ARTIFACT is a README (read by people); the AUTHORITIES are the filesystem
// (links and named paths), the `melos:` block (script names) and `pubspec.yaml`
// (`name:`). A README whose claims resolve cannot rot quietly — renaming a doc,
// a script or the package turns this red instead of leaving a plausible lie on
// the front door. Claims this gate cannot resolve (register, tone, "is the
// dictate in the right file") stay review items; they are NOT approximated here.
//
// This is a rule test, not a behavior test: GWT naming and shouldly idioms for
// behavior suites apply (docs/06-testing.md).
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

void main() {
  final root = _bibleRoot();
  final packageDir = p.join(root.path, 'example');
  final pubspec = File(p.join(packageDir, 'pubspec.yaml')).readAsStringSync();

  // The READMEs this repo ships: the bible's own, and the sample package's.
  // The publishable package is where the claim set is richest (melos scripts,
  // a declared name), so it is the one whose pubspec is the authority.
  final readmes = <File>[
    File(p.join(root.path, 'README.md')),
    File(p.join(packageDir, 'README.md')),
  ];

  test('every link and relative path a README names exists', () {
    final unresolved = <String>[];
    for (final readme in readmes) {
      final dir = readme.parent;
      final text = readme.readAsStringSync();
      final claims = <String>[..._linkTargets(text), ..._pathClaims(text)];
      for (final claim in claims) {
        final target = p.normalize(p.join(dir.path, claim));
        final exists =
            FileSystemEntity.isFileSync(target) ||
            Directory(target).existsSync();
        if (!exists) {
          unresolved.add('${p.relative(readme.path, from: root.path)}: $claim');
        }
      }
    }
    unresolved.should.beEmpty();
  });

  test('every script a README tells you to run is in the melos: block', () {
    final scripts = _melosScripts(pubspec);
    scripts.length.should.beGreaterOrEqualThan(1);
    final unknown = <String>[];
    for (final readme in readmes) {
      for (final name in _melosRunNames(readme.readAsStringSync())) {
        if (!scripts.contains(name)) {
          unknown.add('${p.basename(readme.path)}: melos run $name');
        }
      }
    }
    unknown.should.beEmpty();
  });

  test('the package a README names is the name: its pubspec declares', () {
    final name = _packageName(pubspec);
    final sample = File(p.join(packageDir, 'README.md')).readAsStringSync();
    sample.contains(name).should.be(true);
  });
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

/// Targets of inline markdown links — `[text](target)` — that point inside the
/// repo: absolute URLs, mail links and same-page anchors are not claims.
Iterable<String> _linkTargets(String markdown) sync* {
  for (final match in RegExp(r'\[[^\]]*\]\(([^)\s]+)\)').allMatches(markdown)) {
    final target = match.group(1)!.split('#').first;
    if (target.isEmpty || target.startsWith('http') || target.contains(':')) {
      continue;
    }
    yield target;
  }
}

/// Code spans and fenced lines shaped like a repo path — a filename, or
/// anything with a `/` in it. Prose and whole commands (`dart pub get`) do not
/// name a file and are not claims this gate can resolve.
Iterable<String> _pathClaims(String markdown) sync* {
  final tokens = <String>[
    for (final match in RegExp(r'`([^`\n]+)`').allMatches(markdown))
      match.group(1)!,
    ...RegExp(
      r'^```[^\n]*$([\s\S]*?)^```$',
      multiLine: true,
    ).allMatches(markdown).expand((m) => m.group(1)!.split('\n')),
  ];
  for (final token in tokens) {
    final candidate = token.trim();
    if (!candidate.contains(RegExp(r'[/.]')) || candidate.contains(' ')) {
      continue;
    }
    if (RegExp(
      r'^[\w.][\w./~-]*\.(md|yaml|yml|dart|sh|json|txt)$',
    ).hasMatch(candidate)) {
      yield candidate;
    } else if (RegExp(r'^[\w.][\w./~-]*/$').hasMatch(candidate)) {
      yield candidate; // a directory claim: `lib/src/`
    }
  }
}

/// Script names under the root `pubspec.yaml`'s `melos:` → `scripts:` block.
Set<String> _melosScripts(String pubspec) {
  final names = <String>{};
  var inMelos = false;
  var inScripts = false;
  for (final line in pubspec.split('\n')) {
    if (line.startsWith('melos:')) {
      inMelos = true;
      continue;
    }
    if (!inMelos) {
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ')) {
      break; // left the melos block
    }
    if (RegExp(r'^ {2}scripts:\s*$').hasMatch(line)) {
      inScripts = true;
      continue;
    }
    if (inScripts) {
      final key = RegExp(r'^ {4}([A-Za-z0-9:_-]+):').firstMatch(line);
      if (key != null) {
        names.add(key.group(1)!);
      }
    }
  }
  return names;
}

/// Every `<name>` named by a `melos run <name>` mention in [markdown].
Iterable<String> _melosRunNames(String markdown) sync* {
  for (final match in RegExp(
    r'melos run ([A-Za-z0-9:_-]+)',
  ).allMatches(markdown)) {
    yield match.group(1)!;
  }
}

/// The package name declared at the top of [pubspec].
String _packageName(String pubspec) {
  final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(pubspec);
  if (match == null) {
    fail('No name: in pubspec.yaml');
  }
  return match.group(1)!;
}
