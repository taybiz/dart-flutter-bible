# 14. Licensing & Dependency Provenance

We ship two kinds of software, and a dependency has to be safe under both — but what we ship is **not licensed uniformly**, and nobody should read "ours" as "MIT".

| Model | What we ship | What every dependency must be compatible with |
|---|---|---|
| **Public** | repos on public GitHub — but *public* is not the same as *licensed*: some declare MIT (`sku_catalog`), one is Apache-2.0 (`resumesux_application`), and others carry **no `LICENSE` at all** (all rights reserved: readable, not reusable) | the license that repo **actually declares** — or, where it declares none, an all-rights-reserved distribution. Permissive-only either way: a copyleft obligation would attach to code we never offered anyone a licence to |
| **Private / closed** | proprietary code on private GitHub and Gitea | a proprietary binary we distribute (and, for a service, run): no dependency may impose a copyleft obligation on our code |

**There is no house-wide license.** This bible is MIT — that is *this repo's* licence, not a default we hand every project, and a public repo is not thereby open source. Read each repo's `LICENSE` (or its absence) before assuming anything. A first-party package used as a dependency is labelled by the licence its own repo declares, or `Proprietary` when it declares none.

A third-party license is therefore a fact about *our* product, not a detail of the dependency's own business — so it belongs at the point of use, where the person adding the dependency is looking.

## 14.1 The rule — every dependency names its license, inline (no exceptions)

Every dependency declared in a `pubspec.yaml` carries an **inline SPDX license comment** on its declaration line:

```yaml
dependencies:
  fpdart: ^1.2.0          # MIT
  drift: ^2.20.0          # MIT
  crypto: ^3.0.0          # BSD-3-Clause

dev_dependencies:
  shouldly: ^0.5.0+1      # MIT
  mocktail: ^1.0.4        # MIT
  dart_arch_test: ^0.3.1  # MIT
  melos: ^8.8.0           # Apache-2.0
```

- **No exceptions.** `dependencies`, `dev_dependencies`, `dependency_overrides`; a workspace root, a member package, a throwaway `example/` — every pubspec, every declared entry. A dev-only dependency is still a dependency: it is code we fetch, run, and pin in a lockfile.
- **What we label is what we declare.** A transitive dependency we never name is out of scope for the comment — we cannot honestly label a version we do not pin. The rule is about the entries in our own manifests.
- **An SPDX identifier, bare, first token.** One canonical token (`# MIT`, not `# MIT license — see their repo`): greppable, machine-checkable, and unambiguous. The identifier comes from the dependency's own `LICENSE`; when a `pubspec.yaml` declares several, name the one that applies to the shipped code.
- A map-form entry carries the comment on its key line:

  ```yaml
  dependencies:
    thing_contract:  # MIT
      path: ../thing_contract
  ```

## 14.2 What may be a dependency (compatibility)

Verify first, label second: read the dependency's `LICENSE` (or pub.dev's license field). Never infer a license from the repository name, the author, or a sentence in a README.

**Permissive — adopt freely, under both models:**

| SPDX id | Note |
|---|---|
| `MIT` · `BSD-2-Clause` · `BSD-3-Clause` · `ISC` · `Zlib` · `0BSD` · `Unlicense` · `CC0-1.0` | No obligation on our code |
| `Apache-2.0` | Permissive, but not obligation-free: keep the dependency's `NOTICE`/attribution obligations |

**Weak copyleft — copyleft, so never quiet (§14.2.1) — and allowed only with a recorded decision (§14.3):**

- `MPL-2.0` — file-level copyleft: the obligation attaches to the MPL files, not to our code. Usable in a proprietary product when the MPL sources stay available; still never a default.

**Strong copyleft — always avoid. Barred from everything we ship:**

| License | Why |
|---|---|
| `GPL-2.0-*`, `GPL-3.0-*` | A binary that links GPL becomes GPL — a closed-source product cannot ship it. A permissively-licensed product cannot relicense the combined work under its own licence either. Barred from **both** models, for two different reasons |
| `LGPL-2.1-*`, `LGPL-3.0-*` | Copyleft with a relinkability obligation our pure-Dart AOT build does not satisfy |
| `AGPL-3.0-*` | Barred **everywhere, including a network-only service**: the obligation triggers on use over a network, not on distribution |

Always avoid a strong-copyleft dependency — reach for a permissive alternative first, and treat "there is no alternative" as a claim that needs evidence. If one is genuinely unavoidable, it is a recorded decision (§14.3) whose pubspec comment is **LOUD** (§14.2.1): an exception nobody can miss, in a place a review will notice.

**Source-available and no license — barred:**

| License | Why |
|---|---|
| `SSPL-1.0` · `BUSL-1.1` · `Elastic-2.0` · `Commons-Clause` · any `LicenseRef-*` | Source-available, not open source: they restrict use and are barred |
| **No license stated / `NOASSERTION`** | Absence of a license is "all rights reserved", not permission. A path or git dependency with no `LICENSE`, or a package whose license you cannot find, is not adoptable — a stop-and-decide, never a guess |

### 14.2.1 Copyleft comments are LOUD — scaled to the risk

A copyleft dependency never gets a quiet comment — a plain `# GPL-3.0-only` reads as handled when it is not. Its inline comment names the SPDX id, carries the uppercase word `COPYLEFT`, and warns with an exclamation count that matches the licence's reach:

```yaml
mpl_thing: ^1.0.0   # MPL-2.0  ! WEAK COPYLEFT — AGENTS.md: <why>
gpl_thing: ^1.0.0   # GPL-3.0-only  !!! STRONG COPYLEFT — AGENTS.md: <why>
```

One bang for weak copyleft (file-level: `MPL-2.0`), three for strong (`GPL-*`, `LGPL-*`, `AGPL-*`). The word greps, the bangs survive a skim at a glance, and the dependency-license gate (§14.4) enforces both — a quiet copyleft comment, or the wrong number of bangs, is a red gate, not a judgement call.

## 14.3 Recording an exception

A barred (or weak-copyleft) dependency is never a quiet addition. It is a **documented decision**, recorded the way every other deviation is (§1.3, §10.15a): a named entry under "Deviations" in the consuming repo's `AGENTS.md`, stating the dependency, its license, and why. Where the exception changes the gate (§14.4), the same change widens that repo's allow-set in its gate test — so the exception is visible in a diff, reviewed like any other code, and never smuggled in through a license the gate did not know to look for.

## 14.4 Enforcement — the dependency-license gate

The rule is enforced, not trusted. Every repo that ships a `pubspec.yaml` ships a **dependency-license test** in its suite: it walks the repo's pubspecs, asserts each declared dependency line carries an inline SPDX comment, asserts the identifier is in the repo's allow-set (the permissive list above, plus any recorded and reviewed exception), and requires a copyleft dependency's comment to warn loudly — `COPYLEFT` with one `!` for weak copyleft, three (`!!!`) for strong (§14.2.1). The reference implementation is `example/test/dependency_license_test.dart` in this repo — a repo adopts it by copying the test and labelling its own pubspec. `melos run verify` runs it with everything else.

## 14.5 Stating a licence — a closed-source repo says so

All rights reserved is the default, but "by default" is an inference a reader should not have to draw. A repo that is **not** offered under an open-source licence states it, in a `LICENSE` file at the root, taken from `templates/LICENSE-proprietary.md`:

> **Proprietary — All Rights Reserved**, plus an explicit *no reverse engineering, decompiling, or disassembling* clause — carrying the usual "except to the extent that such activity is expressly permitted by applicable law" carve-out, which is what keeps the clause a contract term rather than an overbroad one.

Why state it instead of leaving the default implicit:

- **The dependency label has an anchor.** A first-party package from such a repo is labelled `Proprietary` (§14.1) — and that is now a licence the repo *declares*, not a guess from an absent file.
- **A contract hook exists.** Copyright alone does not cleanly bar reverse engineering: in the US, decompiling for interoperability is generally fair use, and in the EU the Software Directive grants a non-waivable interoperability decompilation right. An explicit term is what you rely on where it *is* enforceable — and stating it plainly costs nothing.
- **Public is not open source.** Where a repo is publicly readable but proprietary, the file says so, and a reader gets the truth from the repo rather than a licence they assumed.

Open-source repos do **not** carry this file — they ship their own real licence (MIT, Apache-2.0, …).

## 14.6 Scope

This is engineering policy, not legal advice. It applies to every repo in the estate, open or closed; the comment states the license and never replaces reading it, and a genuinely ambiguous, bespoke, or dual license goes to a human decision (§14.3) rather than a default.
