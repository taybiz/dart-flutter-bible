#!/usr/bin/env bash
# Render the GitHub wiki from docs/, and optionally publish it.
#
#   scripts/sync-wiki.sh --render [dir]   render docs/ -> dir (default: wiki/), no network
#   scripts/sync-wiki.sh [clone-dir]      render into a wiki clone and push (publish)
#
# No GitHub Actions (bible §2.10). `--render wiki` produces the committed,
# gate-checked pages under wiki/ — the wiki is shipped as code. Publishing copies
# that same output into the wiki git repo and pushes it; a human, an agent, or
# the estate runner does it.
#
# The doctrine docs are the authority; the page list below is derived from them
# and gated by example/test/wiki_contract_test.dart (the three lists — README
# link rewrite, copy_page, _Sidebar.md — must agree and cover every doc).
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-taybiz/dart-flutter-bible}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# docs file -> wiki page. Uses the global OUT_DIR set by render().
copy_page() {
  cp "$ROOT_DIR/docs/$1.md" "$OUT_DIR/$2.md"
  printf '\n---\n[Home](Home) \u00b7 [README](https://github.com/%s)\n' "$REPO" >> "$OUT_DIR/$2.md"
}

# Deterministic docs/ -> wiki-page render. No network, no git.
render() {
  OUT_DIR="$1"
  mkdir -p "$OUT_DIR"

# Home comes from the repo README (intro + why + contents)
cp "$ROOT_DIR/README.md" "$OUT_DIR/Home.md"
printf '\n---\n[Back to the repo](https://github.com/%s)\n' "$REPO" >> "$OUT_DIR/Home.md"

# Rewrite repo-relative links to wiki links (GitHub wikis don't resolve docs/*.md paths)
sed -i \
  -e 's|](docs/01-architecture.md)|](Architecture)|g' \
  -e 's|](docs/02-toolchain.md)|](Toolchain-and-Melos)|g' \
  -e 's|](docs/03-topology.md)|](Repository-Topology)|g' \
  -e 's|](docs/04-functional-core.md)|](Functional-Core)|g' \
  -e 's|](docs/05-persistence.md)|](Persistence)|g' \
  -e 's|](docs/06-testing.md)|](Testing)|g' \
  -e 's|](docs/07-builders.md)|](Builders-and-Codegen)|g' \
  -e 's|](docs/08-flutter-ring.md)|](Flutter-Ring)|g' \
  -e 's|](docs/09-bootstrap-checklist.md)|](Bootstrap-Checklist)|g' \
  -e 's|](docs/10-review-checklist.md)|](Review-Checklist)|g' \
  -e 's|](docs/11-decisions.md)|](Decisions-and-Roadmap)|g' \
  -e 's|](docs/12-sources.md)|](Sources-of-Truth)|g' \
  -e 's|](docs/13-config-and-settings.md)|](Config-and-Settings)|g' \
  -e 's|](docs/14-licensing.md)|](Licensing-and-Dependencies)|g' \
  -e 's|](docs/15-hardware.md)|](Hardware-and-Platform)|g' \
  -e "s|](docs/00-compact.md)|](https://github.com/${REPO}/blob/main/docs/00-compact.md)|g" \
  -e "s|](LICENSE)|](https://github.com/${REPO}/blob/main/LICENSE)|g" \
  "$OUT_DIR/Home.md"

copy_page 01-architecture         Architecture
copy_page 02-toolchain            Toolchain-and-Melos
copy_page 03-topology             Repository-Topology
copy_page 04-functional-core      Functional-Core
copy_page 05-persistence          Persistence
copy_page 06-testing              Testing
copy_page 07-builders             Builders-and-Codegen
copy_page 08-flutter-ring         Flutter-Ring
copy_page 09-bootstrap-checklist  Bootstrap-Checklist
copy_page 10-review-checklist     Review-Checklist
copy_page 11-decisions            Decisions-and-Roadmap
copy_page 12-sources              Sources-of-Truth
copy_page 13-config-and-settings  Config-and-Settings
copy_page 14-licensing            Licensing-and-Dependencies
copy_page 15-hardware             Hardware-and-Platform

cat > "$OUT_DIR/_Sidebar.md" <<'SIDEBAR'
**Dart/Flutter Bible**
- [Home](Home)
- [Architecture](Architecture)
- [Toolchain & Melos](Toolchain-and-Melos)
- [Repository Topology](Repository-Topology)
- [Functional Core](Functional-Core)
- [Persistence](Persistence)
- [Testing](Testing)
- [Builders & Codegen](Builders-and-Codegen)
- [Flutter Ring](Flutter-Ring)
- [Bootstrap Checklist](Bootstrap-Checklist)
- [Review Checklist](Review-Checklist)
- [Decisions & Roadmap](Decisions-and-Roadmap)
- [Sources of Truth](Sources-of-Truth)
- [Config & Settings](Config-and-Settings)
- [Licensing & Dependencies](Licensing-and-Dependencies)
- [Hardware & Platform](Hardware-and-Platform)
SIDEBAR
}

if [ "${1:-}" = "--render" ]; then
  render "${2:-$ROOT_DIR/wiki}"
  echo "wiki: rendered to ${2:-$ROOT_DIR/wiki}"
  exit 0
fi

# ---- publish: copy the rendered pages into the wiki git repo and push ----
WIKI_DIR="${1:-/tmp/dart-flutter-bible.wiki}"

if [ -n "${GITHUB_TOKEN:-}" ]; then
  WIKI_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO}.wiki.git"
else
  WIKI_URL="git@github.com:${REPO}.wiki.git"
fi

# GitHub only materializes a wiki's git repo after the first page is saved
# (open the repo's Wiki tab and save a placeholder page once).
if ! git ls-remote "$WIKI_URL" >/dev/null 2>&1; then
  echo "wiki not initialized yet \u2014 open the repo's Wiki tab and save a first page, then re-run."
  exit 0
fi

if [ ! -d "$WIKI_DIR/.git" ]; then
  git clone "$WIKI_URL" "$WIKI_DIR"
fi
cd "$WIKI_DIR"
git checkout master 2>/dev/null || git checkout -b master
git pull --ff-only origin master 2>/dev/null || true

# git identity \u2014 automated runners have none; local uses the user's configured identity
if ! git config user.name >/dev/null 2>&1; then
  git config user.name "wiki-sync"
  git config user.email "wiki-sync@localhost"
fi

render "$WIKI_DIR"

git add -A
if git diff --cached --quiet; then
  echo "wiki: no changes"
  exit 0
fi
git commit -m "docs: sync wiki from docs/"
git push origin master
echo "wiki: pushed"
