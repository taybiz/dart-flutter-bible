#!/usr/bin/env bash
# Regenerate the GitHub wiki from docs/ and push.
#
# Local:  scripts/sync-wiki.sh [wiki-clone-dir]   (default: /tmp/dart-flutter-bible.wiki)
# Runner: GITHUB_TOKEN + GITHUB_REPOSITORY env vars are picked up automatically
#         (run by the estate runner — no GitHub Actions; bible §2.10).
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-staylorx/dart-flutter-bible}"
WIKI_DIR="${1:-/tmp/dart-flutter-bible.wiki}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -n "${GITHUB_TOKEN:-}" ]; then
  WIKI_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO}.wiki.git"
else
  WIKI_URL="git@github.com:${REPO}.wiki.git"
fi

# GitHub only materializes a wiki's git repo after the first page is saved
# (open the repo's Wiki tab and save a placeholder page once).
if ! git ls-remote "$WIKI_URL" >/dev/null 2>&1; then
  echo "wiki not initialized yet — open the repo's Wiki tab and save a first page, then re-run."
  exit 0
fi

if [ ! -d "$WIKI_DIR/.git" ]; then
  git clone "$WIKI_URL" "$WIKI_DIR"
fi
cd "$WIKI_DIR"
git checkout master 2>/dev/null || git checkout -b master
git pull --ff-only origin master 2>/dev/null || true

# git identity — automated runners have none; local uses the user's configured identity
if ! git config user.name >/dev/null 2>&1; then
  git config user.name "wiki-sync"
  git config user.email "wiki-sync@localhost"
fi

# docs file -> wiki page name
copy_page() {
  cp "$ROOT_DIR/docs/$1.md" "$2.md"
  printf '\n---\n[Home](Home) · [README](https://github.com/%s)\n' "$REPO" >> "$2.md"
}

# Home comes from the repo README (intro + why + contents)
cp "$ROOT_DIR/README.md" Home.md
printf '\n---\n[Back to the repo](https://github.com/%s)\n' "$REPO" >> Home.md

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
  -e "s|](docs/00-compact.md)|](https://github.com/${REPO}/blob/main/docs/00-compact.md)|g" \
  -e "s|](LICENSE)|](https://github.com/${REPO}/blob/main/LICENSE)|g" \
  Home.md

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

cat > _Sidebar.md <<'SIDEBAR'
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
SIDEBAR

git add -A
if git diff --cached --quiet; then
  echo "wiki: no changes"
  exit 0
fi
git commit -m "docs: sync wiki from docs/"
git push origin master
echo "wiki: pushed"
