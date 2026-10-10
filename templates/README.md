# Repo docs templates (type A/B/C)

Copyable scaffolds for the operating docs of a new project, one per topology
(bible §3). Each encodes the **minimal-get-started skeleton only** — it says what
topology you are, points at the doctrine, and leaves the doctrine itself linked, not
restated (§1.3 D.R.Y.). Deviations and local wiring are the only things you fill in.

| File | For | Key contents |
|---|---|---|
| `AGENTS-a.md` | Topology A — one workspace repo | Layout, "no Flutter in core"-free, dev-tools etiquette, housekeeping gate |
| `AGENTS-b.md` | Topology B — core repo (the domain/usecases/datasources/CLI side) | Core is pure Dart, headless; the facade seam; git-dep + override workflow |
| `AGENTS-ui.md` | Topology B — UI repo (the Flutter side) | Widgets-only boundary, composition root, integration-test gate |
| `AGENTS-c.md` | Topology C — single-package repo | Package-as-workspace-root, `melos:` key in pubspec, release flow |
| `BACKLOG.md` | any | Queue, not a diary: terse actionable entries, Open / Done |
| `CHANGELOG.md` | any | Keen decisions and the *why*, grouped by release |

## How to use

1. Copy the template(s) for your topology into the new repo as `AGENTS.md`,
   `BACKLOG.md`, `CHANGELOG.md`.
2. Replace the `<placeholders>` (`<project>`, `<thing>_domain`, `<thing_core>`, …).
3. Delete the explanatory "Deviations" stub only if it stays empty — or keep it as
   a deliberate null. The D.R.Y. rule stands: never copy doctrine rules into these files.

See `docs/09-bootstrap-checklist.md` §9.11 for where these land in the new-project flow.
