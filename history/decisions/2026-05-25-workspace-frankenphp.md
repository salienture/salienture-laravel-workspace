# Workspace with FrankenPHP stack

**Date:** 2026-05-25

**Context:** Need a dedicated dev workspace around the Salienture Laravel repo with production-like PHP runtime and supporting services.

**Decision:**

- Monorepo-style workspace; `app/` symlinks to existing `../salienture` git repo.
- FrankenPHP + Caddy for HTTP; MariaDB, Redis, Mailpit, phpMyAdmin in Compose.
- Vite remains on host; Caddy proxies `/build` and `/resources` to port 5173.
- Queue and scheduler behind Compose profile `workers`.

**Consequences:**

- Default app URL: `http://localhost:8080`
- `make app-env-docker` sets `DB_HOST=mariadb`, `REDIS_HOST=redis`, `MAIL_HOST=mailpit`
- Application git history unchanged in salienture repo
