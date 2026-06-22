# Laravel Workspace

> Built by [Salienture](https://salienture.com) — Startup speed, enterprise delivery.

A reusable local development workspace for any Laravel application.
Ships with Docker (FrankenPHP, MariaDB, Redis, Mailpit, phpMyAdmin),
a smart app-detection setup script, Makefile workflows, and AI assistant config.

---

## Quick start

```bash
# 1. Clone the workspace
git clone <workspace-repo> my-project-workspace
cd my-project-workspace

# 2. Clone your Laravel app into app/
git clone <your-laravel-repo> app/my-app

# 3. Run init — auto-detects the app, configures .env, builds, migrates
cp .env.example .env
make init
```

Second terminal (frontend HMR):

```bash
make vite
```

| Service      | Default URL                   |
|--------------|-------------------------------|
| Application  | http://localhost:8080         |
| Mailpit      | http://localhost:8025         |
| phpMyAdmin   | http://localhost:8081         |

```bash
make help    # all available commands
```

---

## How app detection works

`make init` calls `scripts/setup.sh` which scans the `app/` directory for
Laravel apps (any subdirectory containing `artisan` + `composer.json`):

| Scenario                   | Behaviour                               |
|----------------------------|-----------------------------------------|
| One app found              | Auto-selected, confirmed in output      |
| Multiple apps found        | Interactive numbered menu               |
| No apps found              | Prompts for a path                      |
| Already configured         | Skips setup (shows current app)         |

The chosen app name drives `COMPOSE_PROJECT_NAME`, `DB_DATABASE`, and `DB_USERNAME`
so multiple workspaces running different apps don't collide.

To switch to a different app:

```bash
make reconfigure
make init
```

---

## Daily workflow

```bash
make up          # Start FrankenPHP, MariaDB, Redis, Mailpit, phpMyAdmin
make workers-up  # Optional: queue + scheduler containers
make vite        # Frontend HMR on host (separate terminal)
make down        # Stop everything
```

---

## Common commands

```bash
make artisan ARGS="route:list"
make composer ARGS="require vendor/package"
make test
make pint
make migrate
make fresh              # migrate:fresh --seed
make shell              # bash inside FrankenPHP container
make mysql              # MariaDB CLI
make redis-cli
make logs
```

---

## Structure

| Path              | Purpose                                                        |
|-------------------|----------------------------------------------------------------|
| `app/`            | Laravel app container — clone your app(s) here (gitignored)   |
| `app/.gitkeep`    | Keeps `app/` tracked; app directories themselves are not committed |
| `docker/`         | Compose stack and FrankenPHP image                             |
| `scripts/`        | setup.sh, patch-app-env.sh                                     |
| `docs/`           | Development and operations guides                              |
| `history/`        | Decision records and session notes                             |
| `.devcontainer/`  | Dev container for VS Code / Cursor                             |
| `.cursor/`        | Cursor AI rules                                                |
| `.claude/`        | Claude Code settings and slash commands                        |

---

## Workspace .env

Key variables written by `make setup`:

| Variable               | Description                                 |
|------------------------|---------------------------------------------|
| `APP_NAME`             | App directory name (e.g. `salienture`)      |
| `APP_PATH`             | Absolute path to the Laravel app            |
| `COMPOSE_PROJECT_NAME` | Docker namespace (derived from app name)    |
| `DB_DATABASE`          | Database name (same as project name)        |
| `DB_USERNAME`          | DB user (same as project name)              |

Port variables (`APP_HTTP_PORT`, `DB_PORT`, `PMA_PORT`, etc.) can be changed
in `.env` to run multiple workspaces simultaneously without port conflicts.

---

## Multiple workspaces

Each workspace is independent. To run two Laravel apps in parallel:

```bash
# workspace-a/.env
APP_HTTP_PORT=8080
DB_PORT=3306
PMA_PORT=8081

# workspace-b/.env
APP_HTTP_PORT=8090
DB_PORT=3307
PMA_PORT=8091
```

---

## Requirements

- Docker Compose v2
- Make
- Node.js 22+ (Vite on host)
- Git

---

## Documentation

- [Development guide](docs/development.md)
- [Docker reference](docs/docker.md)
- [Architecture](docs/architecture.md)

---

## AI assistants

- **Claude Code:** `CLAUDE.md` + slash commands in `.claude/commands/`
- **Cursor:** `AGENTS.md` + `.cursor/rules/`

---

## License

© 2026 [Salienture](https://salienture.com). Workspace tooling is MIT licensed.
Each Laravel application follows its own repository license.
