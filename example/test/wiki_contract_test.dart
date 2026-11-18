// Wiki contract gate — bible §1.3, §1.6, §10.
//
// The ARTIFACT is `scripts/sync-wiki.sh` (the generator that PUBLISHES the
// doctrine to the GitHub wiki); the AUTHORITY is the filesystem — the doctrine
// docs that actually exist in `docs/`.
//
// The script spells its page list in three separate places that must agree: the
// `sed` block that rewrites README's `docs/NN-*.md` links to wiki page names, the
// `copy_page` list that writes each page, and the `_Sidebar.md` heredoc. Nothing
// compared them, and a page that was never in the list produces no diff — so
// `wiki-sync` reported success on every push while §13 sat absent from the wiki
// for five weeks, and README linked to a page the wiki did not have.
//
// That failure mode is why this is a gate: the sync's own success is not
// evidence that the published wiki is complete, so the completeness claim is
// checked here instead of trusted. Add or rename a doctrine doc and this goes
// red until all three places carry it.
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
  final script = _syncScript(root);
  final docs = _doctrineDocs(root);
  final pages = _copiedPages(script);
  final links = _rewrittenLinks(script);
  final sidebar = _sidebarPages(script);

  test('the sync script still spells a page list this gate can read', () {
    // Population first, as its own named test: an empty selection would satisfy
    // every assertion below, and a load-time guard would fail the whole file
    // without saying which doc is missing. Docs is the authority here, so the
    // three lists must each cover it.
    docs.length.should.beGreaterOrEqualThan(1);
    pages.length.should.beGreaterOrEqualThan(docs.length);
    links.length.should.beGreaterOrEqualThan(docs.length);
    sidebar.length.should.beGreaterOrEqualThan(docs.length);
  });

  test('every doctrine doc is copied to its own wiki page', () {
    final missing = <String>[
      for (final doc in docs)
        if (!pages.containsKey(doc)) doc,
    ];
    missing.should.beEmpty();
  });

  test('every doctrine doc README links to is rewritten to its wiki page', () {
    // The rewrite exists so a wiki reader's click resolves; a doc with no rule
    // stays a repo-relative path, which a wiki page cannot follow.
    final missing = <String>[
      for (final doc in docs)
        if (!links.containsKey(doc)) doc,
    ];
    missing.should.beEmpty();
  });

  test("the rewrite and the copy name the same page for every doc", () {
    // Two spellings of one page name is how a sidebar link goes dead: the doc
    // is copied as `Config-and-Settings` while the README link points at
    // `Config-and-Setting`.
    final disagreements = <String>[
      for (final doc in docs)
        if (links.containsKey(doc) && links[doc] != pages[doc])
          '$doc: sed says "${links[doc]}", copy_page says "${pages[doc]}"',
    ];
    disagreements.should.beEmpty();
  });

  test('the sidebar lists exactly the pages the sync writes', () {
    // Set equality both ways: a page with no sidebar entry is unreachable, and
    // an entry with no page is a dead link. `Home` comes from the README, not
    // from `copy_page`, so it is outside the comparison. Compared by difference
    // rather than `Set ==` — Dart's Set equality is identity.
    final listed = sidebar.toSet()..remove('Home');
    final written = pages.values.toSet();
    final noEntry = written.difference(listed).toList()..sort();
    final deadEntry = listed.difference(written).toList()..sort();
    noEntry.should.beEmpty();
    deadEntry.should.beEmpty();
  });

  test('every page the sync writes is named by a doc that exists', () {
    // The reverse direction: a `copy_page` line left behind by a renamed or
    // deleted doc would make the sync fail on a missing file rather than here,
    // where the message says which doc moved.
    final stale = <String>[
      for (final doc in pages.keys)
        if (!docs.contains(doc)) doc,
    ];
    stale.should.beEmpty();
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

/// The wiki sync generator, read as data. Fails loudly when it is gone, so a
/// rename cannot pass as agreement.
File _syncScript(Directory root) {
  final script = File(p.join(root.path, 'scripts', 'sync-wiki.sh'));
  if (!script.existsSync()) {
    fail(
      'scripts/sync-wiki.sh is gone — the wiki generator moved or was '
      'deleted, and this gate reads it as data',
    );
  }
  return script;
}

/// Every doctrine doc in `docs/`, by basename and in sorted order. The compact
/// blob (the `00-` prefix) is not a doctrine doc — the sync links it as a repo
/// blob rather than a wiki page — so it is outside this contract.
List<String> _doctrineDocs(Directory root) =>
    Directory(p.join(root.path, 'docs'))
        .listSync()
        .whereType<File>()
        .map((file) => p.basename(file.path))
        .where((name) => name.endsWith('.md') && !name.startsWith('00-'))
        .toList()
      ..sort();

/// `copy_page 13-config-and-settings  Config-and-Settings` -> doc -> page name.
Map<String, String> _copiedPages(File script) {
  final pages = <String, String>{};
  for (final match in RegExp(
    r'^copy_page\s+(\S+)\s+(\S+)\s*$',
    multiLine: true,
  ).allMatches(script.readAsStringSync())) {
    pages['${match.group(1)}.md'] = match.group(2)!;
  }
  return pages;
}

/// The `sed` block's `s|](docs/NN-x.md)|](Page)|g` rules -> doc -> page name.
/// 00-compact.md is excluded: its rule targets a GitHub blob URL, not a page.
Map<String, String> _rewrittenLinks(File script) {
  final links = <String, String>{};
  for (final match in RegExp(
    r'\]\(docs/(\d\d-[^)]+\.md)\)\|]\(([^)]+)\)\|g',
  ).allMatches(script.readAsStringSync())) {
    final doc = match.group(1)!;
    if (!doc.startsWith('00-')) links[doc] = match.group(2)!;
  }
  return links;
}

/// `- [Label](PageName)` lines in the generated `_Sidebar.md` heredoc.
Iterable<String> _sidebarPages(File script) sync* {
  for (final match in RegExp(
    r'^- \[[^\]]+\]\(([^)]+)\)\s*$',
    multiLine: true,
  ).allMatches(script.readAsStringSync())) {
    yield match.group(1)!;
  }
}
