# BACKLOG — dart-flutter-bible

Proposed doctrine changes from consumer repos. This is a queue for proposals that
would amend the bible — the doctrine repo, so changes land by agreement (a PR) and
are *mirrored*, never edited in a consumer's BACKLOG and copied. Read before making
a doctrine change. Terse: one unique, actionable item each.

---

## Open

### 1. `thing_domain` may depend on `crypto` for content hash identity (doctrine conflict)
A consumer (learn_me_core) hit a hard conflict: bible §3 says `thing_domain` depends on
`equatable` + `fpdart` only — "Nothing else. No Flutter, no I/O, no JSON package." But
§11/§6 mandate content-derived identity, which in learn_me_core means SHA-256 via
`package:crypto` in the domain layer (a pure pure-Dart hash; no I/O, no platform calls).

The two rules cannot both hold as written: content identity needs a hash, and a pure
domain has no other spelling for it in Dart than `crypto` (or a vendored SHA-256, which
re-introduces exactly the dependency it avoids).

**Proposal:** amend §3 to allow `crypto` in `thing_domain` for content-hash identity
only, listing `equatable` + `fpdart` + `crypto`. Decide whether that is a narrow carve-out
(worded as "content hash only") or a general widening, and whether the pinned crypto major
matters.

Origin: `learn_me_core` `BACKLOG.md` "Deviations" entry on `packages/domain` depending on
`crypto: ^3.0.6`.
