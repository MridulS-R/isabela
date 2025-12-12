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

### Database (dev)
- Development/test use SQLite. Create/migrate with:
  - `bundle exec rails db:setup`
  - `bundle exec rails db:migrate`

## Notes

- Accessible by default: semantic landmarks, keyboard‑friendly nav, high contrast.
- Mobile‑ready: responsive layout with flex/grid and a collapsible menu.
- The contact form is front‑end only; wire to a backend or email service for submissions.

## Deploy to Render

Option A — Blueprint (recommended)
- Ensure your repo contains `render.yaml` (included). It provisions a free Postgres database and wires `DATABASE_URL`.
- In Render, click New → Blueprint → connect repo → confirm.
- Render will:
  - Install gems, precompile assets, run migrations, and run Puma with `config/puma.rb`.
  - Set `SECRET_KEY_BASE` automatically from the blueprint and `DATABASE_URL` from the linked Postgres.
  - Serve static assets (`RAILS_SERVE_STATIC_FILES=true`).

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
