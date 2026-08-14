# edwardoliveira.github.io

Personal site for Edward Ribeiro, built with [Jekyll](https://jekyllrb.com/) on the [Minimal Mistakes](https://mmistakes.github.io/minimal-mistakes/) theme, loaded via [`remote_theme`](https://github.blog/2017-11-29-use-any-theme-with-github-pages/) so it stays in sync with upstream. Content lives in `_pages`, `_posts`, `_projects`, `_talks`, `_teaching`, and `_data/navigation.yml` controls the header menu.

## Running locally

1. Install Ruby, Bundler, and Node (only Ruby/Bundler are required to serve the site):

   ```bash
   brew install ruby
   gem install bundler
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

   If you hit a permissions error, install gems locally instead:

   ```bash
   bundle config set --local path 'vendor/bundle'
   bundle install
   ```

3. Serve the site:

   ```bash
   bundle exec jekyll serve -l -H localhost
   ```

   Changes to Markdown/HTML content live-reload automatically. Changes to `_config.yml` require restarting the server.

## Using Docker

```bash
chmod -R 777 .
docker compose up
```

The site will be available at `localhost:4000`.

## Theme

This site uses the official [Minimal Mistakes](https://github.com/mmistakes/minimal-mistakes) theme (© Michael Rose, MIT License) via `remote_theme` in `_config.yml`. Only `_config.yml`, `_data`, content collections, and `assets/css/main.scss`/`assets/js` are customized locally — layouts, includes, and Sass partials come from the upstream theme. See `LICENSE` for license details.
