# AGENTS.md — instructions for agents working in this repo

This is the **Dart/Flutter Bible**: a standards repo (doctrine docs + gate-tested examples), not an application. Doctrine wins over tutorials, package READMEs, and gut feelings; standards change by proposal, never by drift.

## Reading order

- **Read `docs/00-compact.md` first** — the token-cheap bot-ingest blob. It is **bot-only: do not hand-edit it**.
- Human docs `docs/01-architecture.md` … `docs/13-config-and-settings.md` are authoritative. Load the full section only when its detail matters.
- If you edit any human doc, **regenerate `docs/00-compact.md`** afterwards (prompt: "regenerate docs/00-compact.md from the other docs/ files").

## Code lives in tests first, `example/` only for packages

- Example code lives in **tests** first — fully exercised and documented there.
- `example/` is a package deliverable: pub.dev builds its Example tab from an `example/` directory (singular — the [package layout](https://dart.dev/tools/pub/package-layout) convention), so published packages get a real, gate-tested `example/`. Cores, CLIs, TUIs, GUIs skip it unless there's a genuine need (e.g., a core facade example so GUI implementers see the seam).
- Do **not** put code in READMEs or prose docs (bible §2 "Code placement"). Small illustrative snippets inside the doctrine docs are the only exception.

## Housekeeping

- **Open work lives on the `backlog/` board** (`backlog task list`), not in a root `BACKLOG.md`. Doctrine proposals and fixables are tasks; the decision record stays in `docs/11-decisions.md` (bible §1.3).
- The GitHub wiki is rendered from `docs/` by `scripts/sync-wiki.sh` (run by the estate runner, or locally) — no GitHub Action (§2.10). **Its page list is gated too.** `example/test/wiki_contract_test.dart` reads `scripts/sync-wiki.sh` as data: a doctrine doc must appear in all three places the sync spells its list (the README link rewrite, `copy_page`, and `_Sidebar.md`), and the two page names must agree, or the gate goes red. This exists because a page that is never listed produces no diff — `wiki-sync` reported success on every push while §13 sat absent from the wiki, so completeness is checked here rather than inferred from a green sync.
- **README claims are gated.** `example/test/readme_contract_test.dart` reads `README.md` and `example/README.md` as data and resolves what they name: the links and paths exist, every `melos run <task>` is in the `melos:` block, the package the sample names is its `name:`. Rename a doc, a script or the package and the gate goes red — fix the README in the same change (bible §1.6).
- **This file's routing is gated too.** `example/test/agents_contract_test.dart` reads `AGENTS.md` as data: the doctrine range it names must resolve — both endpoints exist, and they are the first and last files in `docs/`. Add or rename a doctrine doc and the gate goes red until the range above is corrected in the same change.
- Keep the working tree clean before committing: `dart format`; `dart analyze --fatal-infos --fatal-warnings` reporting **zero diagnostics of any severity** (errors, warnings, infos — "clean" means literally nothing); `dart test`.
