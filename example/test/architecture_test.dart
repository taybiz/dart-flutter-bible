// Architecture & boundary rules for bible_samples, via dart_arch_test.
// Doctrine: docs/02-toolchain.md "Package-boundary rules".
//  - lib/src/ is PRIVATE: nothing outside it may import it (the barrel is the
//    only public door). Use dart_arch_test's RESOLVED graph, not its glob DSL —
//    the glob matcher strips the `package:<name>/` prefix and is blind across
//    workspace members (§2).
//  - No import cycles, workspace-wide.
//
// This is a rule test, not a behavior test: GWT naming and shouldly apply to
// behavior suites, not to architecture assertions (docs/06-testing.md).
library;

import 'dart:io';

import 'package:dart_arch_test/dart_arch_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Fails if any library imports a URI under [privatePrefix] from outside that
/// private subtree (except the barrel, [sanctuary], which may export it).
///
/// Encodes "never import src/ across packages" — the barrel is the single
/// public door and nothing may reach directly into `lib/src/`.
void checkPrivateImportsInto(
  DependencyGraph graph,
  String privatePrefix, {
  required Set<String> sanctuary,
}) {
  final violations = <String>[];
  for (final caller in Collector.allLibraries(graph)) {
    for (final dep in Collector.dependenciesOf(graph, caller)) {
      if (!dep.startsWith(privatePrefix)) {
        continue; // not into the private subtree
      }
      final callerIsPrivate = caller.startsWith(privatePrefix);
      final callerIsSanctuary = sanctuary.any(caller.startsWith);
      if (!callerIsPrivate && !callerIsSanctuary) {
        violations.add('$caller -> $dep');
      }
    }
  }
  if (violations.isNotEmpty) {
    fail('PRIVATE-IMPORT VIOLATIONS:\n${violations.join('\n')}');
  }
}

void main() {
  late DependencyGraph graph;

  setUpAll(() async {
    // The package root is CWD under `dart test`. Absolute it for safety.
    // Do NOT derive it from Platform.script — under some runners it points at
    // the kernel snapshot in a scratch dir, which yields an empty graph and
    // every rule passes vacuously (§2 pitfall).
    final root = p.normalize(p.absolute(Directory.current.path));
    graph = await Collector.buildGraph(root);
  });

  test('lib/src/ is private: only lib/src (and the barrel) may touch it', () {
    checkPrivateImportsInto(
      graph,
      'package:bible_samples/src/',
      sanctuary: {'package:bible_samples/bible_samples.dart'},
    );
  });

  test('no import cycles anywhere', () {
    shouldBeFreeOfCycles(allFiles(), graph);
  });
}
