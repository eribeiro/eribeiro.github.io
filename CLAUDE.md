# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Edward Ribeiro's personal academic website: a Jekyll site on the [Minimal Mistakes](https://github.com/mmistakes/minimal-mistakes) theme, pulled in via `remote_theme` (see `_config.yml`) so upstream layouts/includes/Sass stay unmodified locally. Only `_config.yml`, `_data`, content collections (`_pages`, `_posts`, `_talks`, `_teaching`, `_projects`, `_publications`), `assets/css/main.scss`, and `assets/js` are customized here.

Nested inside the same repo is `reading-tracks/`, an unrelated, fully static, dependency-free single-page app (a catalog of distributed-systems/databases papers) served at `/reading-tracks/` and linked from the nav as "Paper Club @ UnB".

## Commands

### Jekyll site (local, native)
```bash
gem install bundler
bundle install                                   # or: bundle config set --local path 'vendor/bundle' && bundle install
bundle exec jekyll serve -l -H localhost         # live reload; http://localhost:4000
```
Editing Markdown/HTML/data live-reloads; editing `_config.yml` requires restarting the server.

### Jekyll site (Docker)
```bash
chmod -R 777 .
docker compose up          # site at localhost:4000, config merges _config.yml + _config_docker.yml
```

### JS bundle (`assets/js/main.min.js`)
```bash
npm install
npm run build:js           # uglifies jquery/fitvids/smooth-scroll/plotly + plugins + _main.js into main.min.js
npm run watch:js            # rebuild on change to assets/js/**/*.js
```
`assets/js/_main.js` is the only hand-edited JS source; `main.min.js`/`main.min.js.map` are the committed build output — regenerate with `npm run build:js` rather than editing them by hand.

### reading-tracks (standalone, no build step)
```bash
cd reading-tracks
python3 -m http.server 8000
```
Then open `http://localhost:8000/`. Do **not** open `index.html` via `file://` — the browser blocks `fetch()` of the YAML data files, so nothing renders.

### CV JSON regeneration
```bash
scripts/update_cv_json.sh   # rebuilds _data/cv.json from _pages/cv.md + _config.yml via scripts/cv_markdown_to_json.py
```

There is no test suite or linter configured in this repo.

## Architecture

### Jekyll site
- Content is authored in collections under `_pages`, `_posts`, `_talks`, `_teaching`, `_projects`, `_publications`; `_data/navigation.yml` controls the header menu order (most entries are commented out — only "Blog Posts" and "Paper Club @ UnB" are currently live).
- `_config.yml` is the single source of truth for site metadata, author/social profile fields, collection permalinks, and per-collection layout defaults (`defaults:` block) — check it before assuming a page's layout or front matter behavior.
- `_config_docker.yml` is merged on top of `_config.yml` only in the Docker path (`--config _config.yml,_config_docker.yml`); native `bundle exec jekyll serve` does not use it.
- Theme layouts/includes/Sass partials are **not** in this repo — they're pulled from `mmistakes/minimal-mistakes@4.28.1` at build time. Local overrides live only in `_includes/head/custom.html`, `assets/css/main.scss`, and `assets/js`.
- `_site/` (the built output) is committed to git in this repo, unusually for a Jekyll project — treat it as generated output, not something to hand-edit; regenerate it by running Jekyll rather than patching files under `_site/` directly.
- `markdown_generator/` and `talkmap.py`/`talkmap.ipynb` are offline content-generation utilities (CSV/TSV/BibTeX → collection Markdown, talk locations → Leaflet cluster map); they're run manually, not part of the Jekyll build.

### reading-tracks
- Pure client-side app: `index.html` + `app.js` + `styles.css`, with `js-yaml` vendored locally (`vendor/js-yaml.min.js`, no CDN, no npm deps).
- All content lives in `databases/{papers,researchers,venues}.yaml`, currently schema `v4` (see `metadata.schema_version` in `papers.yaml`). `lineages` in `papers.yaml` is a many-to-many map of lineage-id → paper-ids; `predecessors`/`successors` on a paper are conceptual reading-order relations, not a citation graph.
- `app.js` fetches the three YAML files at load, keeps everything in one `state` object (view, filters, search, grouping), and re-renders synchronously on every filter/search change — there's no framework, router, or build step.
- Deploying is just publishing these static files to GitHub Pages; there's no backend and no build.
- Runtime files in `reading-tracks/` are synchronized from the sibling ReadingTracks repository with `scripts/sync_reading_tracks.sh`.
