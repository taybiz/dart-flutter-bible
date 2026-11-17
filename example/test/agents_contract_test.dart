// AGENTS contract gate — bible §1.3, §1.6, §10.
// The ARTIFACT is `AGENTS.md` (read by people, and loaded as instructions by
// every agent that touches this repo); the AUTHORITY is the filesystem — the
// doctrine docs that actually exist in `docs/`. A routing line that sends a
// reader to a doc which is no longer first or last is exactly the kind of claim
// that survives by being plausible, so it is gated rather than trusted: add or
// rename a doctrine doc and this goes red instead of leaving a stale range.
//
// Deliberately NOT gated: the blob's size, and nothing else about 00-compact.md
// beyond the fact that it exists. A number no one acts on is not worth a CI
// obligation, and the size that used to sit in the reading order was wrong by
// 5x for months precisely because no reader needed it to be right.
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
  final docsDir = Directory(p.join(root.path, 'docs'));
  final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();

  test('the doctrine range AGENTS.md names runs first to last in docs/', () {
    final range = _doctrineRange(agents);
    final doctrine = _doctrineDocs(docsDir);

    // Population first: an empty selection would satisfy every line below.
    doctrine.length.should.beGreaterOrEqualThan(1);

    // Both endpoints resolve...
    for (final endpoint in range) {
      File(p.join(root.path, endpoint)).existsSync().should.be(true);
    }

    // ...and they are the real first and last doc, so a doc added above or
    // below the range is a red test, not a silent routing error.
    p.basename(range.first).should.be(doctrine.first);
    p.basename(range.last).should.be(doctrine.last);
  });

  test('every doctrine doc AGENTS.md names in a code span exists', () {
    final named = _namedDocs(agents);
    named.length.should.beGreaterOrEqualThan(1);

    final missing = <String>[
      for (final claim in named)
        if (!File(p.join(root.path, claim)).existsSync()) claim,
    ];
    missing.should.beEmpty();
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

/// The range the reading order states — the two `docs/…md` paths either side of
/// an ellipsis, as `[first, last]`. Fails loudly when the sentence is gone, so a
/// rewrite that drops the range cannot pass as agreement.
List<String> _doctrineRange(String markdown) {
  final match = RegExp(
    r'`(docs/[^`]+\.md)`\s*…\s*`(docs/[^`]+\.md)`',
  ).firstMatch(markdown);
  if (match == null) {
    fail(
      'AGENTS.md no longer states a doctrine range '
      '(`docs/…md` … `docs/…md`) for this gate to resolve',
    );
  }
  return [match.group(1)!, match.group(2)!];
}

/// Every doctrine doc in [docsDir], by basename and in sorted order. The compact
/// blob (the `00-` prefix) is the derived summary, not a doctrine doc, so it is
/// outside the range the reading order names.
List<String> _doctrineDocs(Directory docsDir) =>
    docsDir
        .listSync()
        .whereType<File>()
        .map((file) => p.basename(file.path))
        .where((name) => name.endsWith('.md') && !name.startsWith('00-'))
        .toList()
      ..sort();

/// Every `docs/…md` path AGENTS.md names inside a code span — a doc it tells a
/// reader to open, so a rename has to fail here rather than at the reader.
Iterable<String> _namedDocs(String markdown) sync* {
  for (final match in RegExp(r'`(docs/[\w.-]+\.md)`').allMatches(markdown)) {
    yield match.group(1)!;
  }
}
