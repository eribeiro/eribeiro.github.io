# AGENTS.md

## Repository overview

This repository contains two static websites:

- The root is Edward Ribeiro's Jekyll site, published at `https://eribeiro.github.io`.
- `reading-tracks/` is a vendored copy of the separate `eribeiro/reading-tracks` static app, published at `/reading-tracks/`.

The Jekyll site uses the Minimal Mistakes remote theme pinned in `_config.yml`. Theme layouts and Sass partials are downloaded at build time; local overrides are limited to files in this repository.

## Editing guidelines

- Author Jekyll content in `_pages/`, `_posts/`, `_drafts/`, `_projects/`, `_talks/`, `_teaching/`, and `_publications/`.
- Use `_data/navigation.yml` for navigation and `_config.yml` for site-wide metadata, collections, defaults, and permalinks.
- Put unpublished posts in `_drafts/`. Published posts must use `_posts/YYYY-MM-DD-slug.md`.
- Edit `assets/js/_main.js`, then run `npm run build:js`; do not hand-edit `assets/js/main.min.js` or its source map.
- Treat `_site/` as generated output. Never patch files there directly; regenerate them with Jekyll after changing source files.
- Preserve unrelated worktree changes. Do not commit or push unless explicitly requested.

## ReadingTracks synchronization

Do not edit `reading-tracks/` directly. Its source of truth is the separate ReadingTracks repository, usually checked out at `../reading-tracks`.

Preview and apply a sync with:

```bash
scripts/sync_reading_tracks.sh --dry-run
scripts/sync_reading_tracks.sh
```

For a checkout elsewhere:

```bash
scripts/sync_reading_tracks.sh --source /path/to/reading-tracks
```

The script intentionally mirrors only runtime files (`index.html`, `app.js`, `styles.css`, `config.yaml`, `data/`, `assets/`, and `vendor/`) and deletes stale files from the destination. Validate changes in the source ReadingTracks checkout when its validator is available:

```bash
python3 ../reading-tracks/scripts/validate.py
node --check reading-tracks/app.js
```

The cross-repository automation uses `.github/workflows/sync-reading-tracks.yml` here and `.github/workflows/sync-site.yml` in the ReadingTracks repository. The latter requires the `SITE_SYNC_TOKEN` Actions secret.

## Development and verification

Install dependencies and serve drafts locally:

```bash
bundle install
bundle exec jekyll serve --drafts --host localhost --port 4000
```

Changes to `_config.yml` require restarting the development server. Before handing off a change, run the checks relevant to the files touched:

```bash
bundle exec jekyll build
bash -n scripts/*.sh
git diff --check
```

When JavaScript dependencies or `assets/js/_main.js` change, also run:

```bash
npm install
npm run build:js
```

There is no general-purpose test suite or linter. A Jekyll build may require network access to download the pinned remote theme.

## Generated and external content

- `_site/` is committed build output and may show broad mechanical changes after a build.
- `markdown_generator/`, `talkmap.py`, and the notebooks are manually run content-generation utilities, not part of the normal Jekyll build.
- `scripts/` is excluded from the published Jekyll output.
- Do not copy `.git`, GitHub workflow configuration, development scripts, or credentials into `reading-tracks/`.
