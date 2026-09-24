# BUFF-CHECK — Site Review Findings

Checklist from the project review. Work through items one by one.

## 9. Link check with lychee — RESOLVED

Full-site broken-link validation was added as a follow-up to the download-variant fixes (item 3).

**Tool:** [lychee](https://lychee.cli.rs) (installed via `pacman`, Arch package `lychee 0.24.2`).

**How to run:**

```bash
make build                                   # needs ruby/bundler + generated assets
lychee --offline --no-progress --root-dir _site _site   # internal links only
# full variant incl. external links (rate-limited):
lychee --no-progress --root-dir _site _site --exclude 'localhost' --max-concurrency 4
```

**IMPORTANT:** `--root-dir _site` is required. The site uses root-relative URLs
(`/assets/...`), and without a root dir lychee cannot resolve them, producing
~880 false "Cannot resolve root-relative link" errors per run.

Useful flags: `--no-progress` (CI-friendly), `-o report.md` (markdown report),
`--exclude-path _site/vendor` if noise appears.

**What it validates:** internal hrefs/src (pages, images incl. `medium.webp`/`*-dark.webp` variants, PDF/SVG downloads, map viewers in `maps/`), anchors, and optionally all external links (Discord, Observable, Access to Insight, ...).

**Why:** catches exactly the class of bug found in item 3 — dead download links (missing `.svg` in frontmatter, misnamed PDFs) that only produced build-time warnings and on-page 404s.

**Status:** RESOLVED (2026-09-24). Assets were already current (generated before the
last `make build`), so no `make assets` was needed. lychee 0.24.2 was already
installed — nothing new to install.

**Result:** first run: 887 errors — nearly all false positives from the missing
`--root-dir`; with it, 2 real issues found, both fixed:
1. `assets/scss/_fonts.scss` — dead `.hero` CSS rule (Pineapple template leftover,
   class unused anywhere) referencing `/images/foo.png`, which doesn't exist.
   Removed the rule.
2. `t2.html` (repo root) — flagged by lychee because its redirect target
   `/digital-garden/t2.html` doesn't exist in this build. **Kept intentionally**
   (user-confirmed): it is a share link that redirects to another website/deployment.
   Exclude it from lychee runs: `--exclude 'digital-garden'`.

**Final run:** 1211 URLs checked, 392 unique, 893 OK, **0 errors** (with `t2.html`
temporarily removed). With `t2.html` restored, expect exactly 1 known-benign error
(its intentional redirect) — use `--exclude 'digital-garden'` for a clean run:

```bash
lychee --offline --no-progress --root-dir _site --exclude 'digital-garden' _site
```

**Not run:** the external-link variant (Discord, Observable, Access to Insight, …)
— optional, rate-limited, and prone to network flakiness; run manually if wanted.

---

## 1. Leftover `food` collection in `_config.yml` — RESOLVED
`food` was a leftover from the early template: declared as a collection with no folder, no area entry, and (originally) no layout default.

**Resolution:** Removed the `food` collection declaration and its layout default from `_config.yml` (per user decision — nothing else referenced it).

## 2. `tech` vs `techs` frontmatter mismatch — RESOLVED
Some content files used `tech:` but the template (`vault/templates/Template Item.md`) and `site.theme.item_meta_order` expect `techs:`.

**Resolution:** Renamed `tech:` → `techs:` in all 20 affected files across `_projects`, `_writtings`, and `_3d-printing` (no conflicts with existing `techs:` keys). Verified no occurrences remain.

## 3. `pdf: true` boolean instead of string filename — RESOLVED
`vault/content/_charts/digital/31-planes-of-existence.md` (and ~11 other chart files) use `pdf: true`, while docs described `pdf` as a string filename.

**Investigation:** Both consumers support the boolean deliberately — `scripts/generate_assets.sh` (`copy_download_variant`) derives `<image-basename>.pdf` when the value is `true`, and `_includes/item-meta-block.html` does the same for the Downloads row. Also requires `file: true` on the same image. Not a bug — a documentation gap.

**Resolution:** Updated the `pdf`/`svg` rows in `README.md` and `vault/templates/Template Item.md` to "bool or string", and added a "Download variants" section to each explaining the boolean/string behavior, the `file: true` requirement, and source/dest paths. Content and code left unchanged.

**Follow-up fixes (verification pass over every `pdf:`/`svg:` value):**
- String values are used **verbatim** (no extension appended) — 8 `svg:` values lacked `.svg`: fixed in `31-planes-of-existence.md`, `37-wings-to-awakenings.md`, `sutta-parallels.md`, `sutta-pitaka.md`.
- Typo fixes: `svg: 31-wings`/`31-wings-2` → `37-wings.svg`/`37-wings-2.svg` (files were named `37-*`); `manual-buddhist-termsforce.svg` → `manual-buddhist-terms-force.svg`.
- `pdf: dependant-origination-3.pdf` pointed nowhere; the file was a stray in `vault/assets/images/` + `other-charts/` (identical copies). Moved one copy to `vault/assets/pdfs/`, deleted the duplicate from `images/`.
- Verified: all `pdf:`/`svg:` values now resolve (`true` derived, or existing file); `vault/assets/images/` contains only raster images again.

## 4. Duplicate `class` attribute in `_layouts/item.html`
The back-arrow link has `class="black-under"` and a second `class="bigger"`; browsers drop the second one.

**Fix:** Merge into a single `class="black-under bigger"` (verify `bigger` style exists / is wanted).

## 5. Root directory clutter
Debug/report docs and stray files in repo root (excluded from build but untidy):
- `t2.html` (stray test file?)
- `CHROMIUM_BORDER_REPORT.md`, `LIGHTONLY_DARKONLY_DEBUG.md`, `OPTIMISATION.md`, `OPTIMISATION2.md`, `CHECK.md`, `PLAN-icon-overlay.md`, `QUOTE.md`

**Fix:** Move debug docs into `docs/`. ~~delete `t2.html` if unused~~ — `t2.html`
is intentional (user's share-link redirect to another site), keep it. Update `exclude` list in `_config.yml` and any references (Makefile, AGENTS.md, README).

## 6. Empty untracked `vault/Page.md`
`vault/Page.md` is empty and untracked — likely an accidental leftover (Obsidian auto-created?).

**Fix:** Delete it (or give it real content if it was intentional).

## 7. AGENTS.md path inaccuracy
AGENTS.md says areas config lives at `content/_data/areas.yml`, but it is actually `vault/data/areas.yml`.

**Fix:** Correct the doc. (`writtings` typo is known-but-intentional to avoid breaking URLs — leave alone.)

## 8. Declared collections with no content
`references` and `food` collections are declared in `_config.yml` but have no folders under `vault/content` and no entries in `vault/data/areas.yml`.

**Update:** `food` removed as part of item 1. `references` still declared with no content — confirm intent.
