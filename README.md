# cv-resume-builder-api

Ruby on Rails backend for the CV/Resume Builder: authentication, per-account CV storage, and PDF generation orchestration (delegating actual HTML→PDF rendering to a separate Node/Playwright microservice, `cv-pdf-renderer`, planned).

Full architecture — data model, API surface, auth flow, PDF pipeline, milestones — lives in the project plan; see the root [`../README.md`](../README.md) for the overall workspace layout.

## Requirements

- Ruby 3.2+ (this app was set up against 3.2.9 via rbenv)
- PostgreSQL 16 running locally (`brew services start postgresql@16`)

## Setup

```bash
bundle install
bin/rails db:create db:migrate
bundle exec rspec        # run the test suite
bin/rails server -p 8080 # http://localhost:8080, matches the FE's VITE_API_BASE_URL
```