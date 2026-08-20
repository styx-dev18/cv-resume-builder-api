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

`GET /api/v1/health` and the built-in `GET /up` are available as boot/liveness checks.

## Status

**M1 complete**: Rails skeleton (full Rails, not `--api`, to keep ActionView/ERB available for PDF templates later), PostgreSQL configured, RSpec + FactoryBot + Shoulda Matchers + WebMock/VCR wired, CORS (`rack-cors`) and baseline rate limiting (`rack-attack`) configured, health check endpoint live.

**M2 complete**: Email/password JWT auth. `users` + `refresh_tokens` tables; Devise (`database_authenticatable`, `registerable`, `validatable`) + devise-jwt (JTI-based revocation) for short-lived (15 min) access tokens; a separate opaque, SHA-256-digested `RefreshToken` (30-day TTL) delivered as an httpOnly/Secure/SameSite=Strict cookie scoped to `/api/v1/auth`, rotated on every refresh. Endpoints: `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `POST /api/v1/auth/refresh`, `DELETE /api/v1/auth/logout`. `Api::V1::BaseController` exposes `current_user`/`authenticate_user!` via the `Authenticatable` concern for protected endpoints going forward.

Not yet implemented (see plan for milestones M3–M6): CV CRUD, OAuth (Google/GitHub), PDF generation pipeline, template system/admin.
