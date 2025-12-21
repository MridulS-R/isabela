# VisionData Website (Rails)

Rails marketing site for VisionData with static pages rendered via a controller and shared layout.

## App structure

- `app/controllers/pages_controller.rb` — Actions: `home`, `solutions`, `data_coverage`, `how_it_works`, `about`, `blog`, `contact`
- `app/views/pages/*.html.erb` — Page templates
- `app/views/layouts/application.html.erb` — Global layout with header/footer partials
- `app/views/shared/_header.html.erb`, `_footer.html.erb` — Navigation + footer
- `app/assets/stylesheets/styles.css` — Site styles (required by `application.css`)
- `app/assets/javascripts/application.js` — Nav toggle + form enhancement
- `app/assets/images/favicon.svg` — Favicon
- `config/routes.rb` — Routes for pages; root → `pages#home`

## Getting started

1) Ensure Ruby and Bundler are installed. Recommended Ruby in `.ruby-version`.

2) Install dependencies:
   - `bundle install`

3) Run the server:
   - `bin/rails server` (or `bundle exec rails s`)
   - Visit http://localhost:3000

If `bin/rails` is missing after `bundle install`, run `bundle binstubs rails` or `bundle exec rails s` directly.

### Tailwind CSS
- This app uses Tailwind via CDN for quick iteration and dark mode.
- To switch to compiled Tailwind (recommended for production):
  1) Add gems: `bundle install` (Gemfile already includes `tailwindcss-rails`).
  2) Install: `bin/rails tailwindcss:install`.
  3) Remove the CDN `<script src="https://cdn.tailwindcss.com..."></script>` from `app/views/layouts/application.html.erb` and ensure the generated stylesheet is referenced (installer wires it automatically).
  4) Add purge/scan content paths to `tailwind.config.js` if needed.

### Database (dev)
- Development/test use SQLite. Create/migrate with:
  - `bundle exec rails db:setup`
  - `bundle exec rails db:migrate`

## Notes

- Accessible by default: semantic landmarks, keyboard‑friendly nav, high contrast.
- Mobile‑ready: responsive layout with flex/grid and a collapsible menu.
- The contact form is front‑end only; wire to a backend or email service for submissions.

### Design tokens (brand)
- Colors (CSS variables in `app/assets/tailwind/application.css`):
  - `--brand-1` `#402E7A` (background violet)
  - `--brand-2` `#4C3BCF` (primary)
  - `--brand-3` `#4B70F5` (accent)
  - `--brand-4` `#3DC2EC` (highlight)
- Utilities:
  - Buttons: `btn btn-brand` (primary), `btn btn-ghost` (secondary)
  - Links: brand defaults via base layer; explicit `link-brand` where needed
  - Containers: `surface`, `card` for white panels over brand background
  - Header: gradient class `header-bar`, nav items use `nav-link`/`nav-active`
  - Divider: `brand-divider` for section separators

## Deploy to Render

Option A — Blueprint (recommended)
- Ensure your repo contains `render.yaml` (included). It provisions a free Postgres database and wires `DATABASE_URL`.
- In Render, click New → Blueprint → connect repo → confirm.
- Render will:
  - Install gems, precompile assets, run migrations, and run Puma with `config/puma.rb`.
  - Set `SECRET_KEY_BASE` automatically from the blueprint and `DATABASE_URL` from the linked Postgres.
  - Serve static assets (`RAILS_SERVE_STATIC_FILES=true`).
  - Store uploaded images in Postgres via Active Storage Database service (`ACTIVE_STORAGE_SERVICE=database`).

Option B — Manual web service
- New → Web Service → Select repo
- Runtime: Ruby
- Build Command: `bundle install && bundle exec rake assets:precompile`
- Start Command: `bundle exec puma -C config/puma.rb`
- Env Vars:
  - `RAILS_ENV=production`
  - `RAILS_SERVE_STATIC_FILES=true`
  - `SECRET_KEY_BASE` → Generate (Render can auto-generate)
  - `DATABASE_URL` → Provided automatically if you link a Render Postgres instance

Notes for Render
- Active Record is enabled; Postgres is used in production via `DATABASE_URL`.
- Hosts for `*.onrender.com` and your custom domain are allowed in `production.rb`.
- Images currently save to DB (Active Storage `database` service). To move to S3 later: set up AWS creds, switch `ACTIVE_STORAGE_SERVICE=amazon`, and add the `amazon` config in `config/storage.yml`.

## Import sample data (Kaggle)

You can import Reddit posts from the Kaggle kernel output `ammar111/reddit-top-1000-posts-analysis-for-18-subreddits`.

Steps:
- Download the kernel outputs to a local folder using the Kaggle CLI:
  - `kaggle kernels output ammar111/reddit-top-1000-posts-analysis-for-18-subreddits -p /absolute/path/to/dest`
  - Identify the CSV file in that folder (open it to confirm headers like `title`, `subreddit`, `score`, etc.).
- Run the importer rake task (path must be absolute):
  - `bundle exec rails "kaggle:import_reddit[/absolute/path/to/dest/FILE.csv]"`
  - Optionally specify an owner email to own the imported posts:
    - `bundle exec rails "kaggle:import_reddit[/absolute/path/to/FILE.csv,owner@example.com]"`

What it does:
- Creates or reuses the owner user (default `reddit-import@example.com`).
- For each CSV row, creates a `Post` with:
  - `caption` from `title`
  - `likes_count` from `score` (display only; not backed by Like rows)
  - A tiny placeholder image attached (to satisfy the image validation)
  - A tag from `subreddit` (normalized to lowercase and `_`)
  - Timestamps from `created_utc` if present

After importing, visit the home page or the Hots view to see the data:
- Home shows “Hots” and “Top by category”.
- Hots: `/posts?sort=hot`.

### Import from the UI or API (production-friendly)

Admin-only import endpoint and UI:
- UI: visit `/imports/new` while signed in as the admin (email must match `ADMIN_EMAIL`) or provide `X-Admin-Token`.
- API: `POST /imports` with JSON `{ "url": "https://.../reddit.csv", "owner_email": "owner@example.com" }` and header `X-Admin-Token: $ADMIN_TOKEN`.

Env vars to set on Render (Web Service):
- `ADMIN_EMAIL` (optional, email allowed to access the form)
- `ADMIN_TOKEN` (recommended for API access)

Example curl:
```
curl -X POST "$APP_URL/imports" \
  -H 'Content-Type: application/json' \
  -H "X-Admin-Token: $ADMIN_TOKEN" \
  -d '{"url":"https://example.com/reddit.csv","owner_email":"owner@example.com"}'
```

The import runs asynchronously via `ImportRedditJob`.
