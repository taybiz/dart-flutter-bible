// Wiki freshness gate -- bible §1.3, §2.10.
//
// The ARTIFACT is the committed `wiki/` tree (the wiki shipped as code); the
// AUTHORITY is the renderer `scripts/sync-wiki.sh` run over `docs/`. Because the
// pages are generated, editing a doctrine doc and forgetting to re-render is the
// rot that bites: the committed wiki silently disagrees with the docs. So the
// gate re-renders into a temp dir and asserts the committed tree matches, byte
// for byte -- regenerate with `scripts/sync-wiki.sh --render wiki` in the same
// change that edits a doc.
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

  test('the committed wiki matches a fresh render of docs/', () {
    final fresh = Directory.systemTemp.createTempSync('dfb-wiki-render');
    addTearDown(() => fresh.deleteSync(recursive: true));

    final script = p.join(root.path, 'scripts', 'sync-wiki.sh');
    final run = Process.runSync('bash', [script, '--render', fresh.path]);
    run.exitCode.should.be(0);

    final rendered = _pages(fresh);
    final committed = _pages(Directory(p.join(root.path, 'wiki')));

    final missing =
        rendered.keys.toSet().difference(committed.keys.toSet()).toList()
          ..sort();
    final extra =
        committed.keys.toSet().difference(rendered.keys.toSet()).toList()
          ..sort();
    missing.should.beEmpty();
    extra.should.beEmpty();

    final drift = <String>[
      for (final name in rendered.keys)
        if (committed[name] != rendered[name]) name,
    ];
    drift.should.beEmpty();
  });
}

/// The bible root, found by walking up from the test's CWD -- `dart test` runs
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

/// Page name -> file contents, for every `.md` file directly in [dir].
Map<String, String> _pages(Directory dir) {
  if (!dir.existsSync()) return <String, String>{};
  return <String, String>{
    for (final file in dir.listSync().whereType<File>())
      if (file.path.endsWith('.md'))
        p.basename(file.path): file.readAsStringSync(),
  };
}
