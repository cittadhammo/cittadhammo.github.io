# OPTIMISATION

This document lists practical improvements for the website codebase and UX quality, excluding content creation.

## 1. Highest Impact First

1. Measure and track Core Web Vitals consistently.
2. Consolidate header/theme/print CSS to reduce regressions.
3. Improve image loading strategy for above-the-fold vs below-the-fold.
4. Strengthen accessibility and keyboard navigation.
5. Add a repeatable QA workflow before deploy.

## 2. Performance

### 2.1 Lighthouse + Trace Workflow

1. Test `home`, one `item` page, and one `page` layout.
2. Run Lighthouse 3 times per page/device (mobile + desktop), keep median.
3. Save JSON reports and compare over time.
4. Verify CLS/LCP issues in DevTools Performance trace, not Lighthouse alone.

Targets:
- CLS < 0.10
- LCP < 2.5s
- INP < 200ms

### 2.2 Images

Current good practice:
- `aspect-ratio` is used for many content images.

Next improvements:
1. Keep hero/logo images `loading="eager"` with `fetchpriority="high"`.
2. Keep gallery/list images lazy.
3. Ensure all important images have explicit dimensions or reliable aspect-ratio reservation.
4. Consider preloading only the single most important hero image:
   - `<link rel="preload" as="image" ...>`

### 2.3 Scripts

1. Review non-critical scripts on pages that do not need them.
2. Keep initialization small on first paint.
3. Avoid duplicate DOM passes where possible.

## 3. CSS/Architecture

### 3.1 Reduce style overlap

There is meaningful overlap between `assets/scss/_layout.scss` and `assets/scss/_custom.scss`.

Action:
1. Define ownership:
   - `_layout.scss`: structural layout primitives.
   - `_custom.scss`: feature overrides only.
2. Move stable rules from `_custom.scss` into canonical sections.
3. Remove dead/commented legacy blocks after validation.

### 3.2 Tokenize recurring colors and spacing

Use CSS variables for recurring values (hero text, underline colors, print colors, header spacing) to simplify theme changes and avoid drift.

### 3.3 Header complexity

Header behavior now handles multiple states (links/no links, breakpoints, theme toggle, home vs non-home).  
Create a small "header contract" section in CSS comments describing:
- expected DOM states
- classes controlling state
- breakpoint behavior

This prevents accidental regressions.

## 4. Theme System

Current state is strong (light/dark toggle + themed assets).  
Next improvements:

1. Keep all theme-switchable assets using `data-light-src` / `data-dark-src` consistently.
2. Keep favicon theme switching in one place (`_includes/head.html`) and avoid root-level duplicates.
3. Document theme config options in `_config.yml` comments:
   - `home_hero_landing`
   - `home_hero_follow_theme`
   - `allow_user_toggle`
   - `respect_prefers_color_scheme`

## 5. Print Experience

Current print improvements are good; centralize further:

1. Keep one dedicated `@media print` block (or one print partial) as single source of truth.
2. Maintain explicit print color policy:
   - default black text
   - controlled exceptions (e.g. `h2`)
3. Keep lazy-image print workaround (`beforeprint`) and monitor for edge cases on very long pages.
4. Validate print output on:
   - home
   - one large item page
   - one standard page layout

## 6. Accessibility

1. Ensure visible `:focus-visible` states for all interactive elements.
2. Check heading hierarchy and landmarks (`header`, `main`, `nav`, `footer`).
3. Confirm color contrast in both themes and print.
4. Add `aria-current` to active nav/location states where relevant.
5. Run `axe` checks on key templates.

## 7. SEO/Metadata

1. Ensure consistent `title`, `description`, and OG image logic for all layouts.
2. Confirm canonical URL behavior in all environments (`baseurl` variations).
3. Ensure manifest/favicon references resolve correctly in deployed URLs.

## 8. Reliability + QA

### 8.1 Pre-deploy checklist

1. Build locally with production-like config.
2. Test light/dark theme toggling on:
   - home
   - item
   - page
3. Test mobile breakpoints (especially 320px, ~425px, ~749px).
4. Test print (without scrolling first).
5. Verify favicon changes after cache clear/hard refresh.

### 8.2 Browser coverage

At minimum:
1. Chromium
2. Firefox
3. Safari/WebKit (if available)

## 9. Repo Hygiene

1. Keep generated vs source assets clearly separated.
2. Avoid leaving duplicate icon packs in multiple locations.
3. Document asset naming conventions:
   - e.g. `logo_dark_*`, `logo_light_*`

## 10. Suggested Next 3 Tasks

1. CSS consolidation pass for header + hero + print rules.
2. Create a short automated QA script/checklist (build + key page smoke checks).
3. Run and store Lighthouse baselines for 3 representative pages.

