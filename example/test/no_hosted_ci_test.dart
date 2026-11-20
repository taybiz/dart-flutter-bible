// No-hosted-CI gate — bible §2.10 (CI/CD is the melos script contract, never
// GitHub Actions).
//
// The ARTIFACT is the repo's `.github/workflows/` directory; the AUTHORITY is
// doctrine §2.10: GitHub is source hosting and pull-request review only, and the
// build / gate / release is the `melos:` script contract, run by us — a human,
// an agent, or the estate runner (a Dagger pipeline at most). A hosted workflow
// is a second definition of "the build" that we neither control nor can run
// locally, so its mere presence is the defect this gate catches — before it
// drifts from the scripts that are the real pipeline.
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

  test('the repo ships no GitHub Actions workflow', () {
    final workflows = _workflowFiles(root);
    workflows.should.beEmpty();
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

/// Every workflow file (`.yml`/`.yaml`) under `.github/workflows/`, relative to
/// the bible root, sorted. An absent directory means no workflows.
List<String> _workflowFiles(Directory root) {
  final dir = Directory(p.join(root.path, '.github', 'workflows'));
  if (!dir.existsSync()) return const <String>[];
  return dir
      .listSync()
      .whereType<File>()
      .map((file) => p.relative(file.path, from: root.path))
      .where((name) => name.endsWith('.yml') || name.endsWith('.yaml'))
      .toList()
    ..sort();
}
