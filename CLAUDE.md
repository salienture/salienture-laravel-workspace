# CLAUDE.md — Laravel Workspace

Guidance for Claude Code when working in this repository.

## What this repo is

A **generic development workspace** for Laravel applications. Infrastructure
lives here; the Laravel app lives in a subdirectory detected by `make setup`
(stored as `APP_PATH` in `.env`).

Do not confuse workspace root with the Laravel root — run PHP/Artisan/Composer
**via Make** or from `/app` inside the `frankenphp` container.

## Essential commands

```bash
make help              # All targets
make init              # First-time: auto-detect app, build, migrate
make setup             # Detect / select Laravel app only
make reconfigure       # Re-select the active app

make up                # Start Docker stack
make down

make artisan ARGS="migrate"
make composer ARGS="install"
make test
make pint
make shell             # Bash in FrankenPHP container
make vite              # Vite on host (separate terminal)
make workers-up        # Queue + scheduler containers
```

## Service URLs (defaults)

| Service     | URL                       |
|-------------|---------------------------|
| App         | http://localhost:8080     |
| Mailpit     | http://localhost:8025     |
| phpMyAdmin  | http://localhost:8081     |

## Layout

| Path           | Role                                                            |
|----------------|-----------------------------------------------------------------|
| `app/`         | Laravel app container — gitignored, never committed to workspace |
| `app/.gitkeep` | Only tracked file inside app/; apps are committed to their own repos |
| `docker/`      | Compose, FrankenPHP Dockerfile, Caddyfile                       |
| `scripts/`     | setup.sh, patch-app-env.sh                                      |
| `docs/`        | Human documentation                                             |
| `history/`     | ADRs and session notes                                          |
| `Makefile`     | Primary CLI                                                     |

## Active app

The active app is configured in workspace `.env`:

```
APP_NAME=salienture
APP_PATH=/absolute/path/to/workspace/app/salienture
COMPOSE_PROJECT_NAME=salienture
```

Read `APP_PATH` to know where the Laravel application code lives.
All apps live inside `app/` — that directory is gitignored in the workspace.

## Application stack

- Laravel 13, PHP 8.3+, Inertia 3, React 19, TypeScript, Tailwind 4
- Laravel Fortify (auth)
- Pest 4 tests
- Commands inside the app dir: `composer dev`, `composer test`, `composer lint`,
  `npm run dev`, `npm run build`

## Docker conventions

- `DB_HOST=mariadb`, `REDIS_HOST=redis`, `MAIL_HOST=mailpit` in app `.env`
  (patched automatically by `make setup` / `make env`)
- FrankenPHP serves `public/`; Vite dev server runs on host port 5173
- Queue/scheduler are optional compose profile `workers`

## When editing

1. **Workspace-only changes** — `docker/`, `Makefile`, `docs/`, `scripts/`,
   `.devcontainer/`, this file
2. **Application changes** — the app directory (respect existing Laravel/Inertia patterns)
3. **Never commit** — `.env`, app `.env`, secrets, `vendor/`, `node_modules/`

## Docs

- [docs/development.md](docs/development.md)
- [docs/docker.md](docs/docker.md)
- [docs/architecture.md](docs/architecture.md)
