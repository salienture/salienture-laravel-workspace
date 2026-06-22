# Architecture

## Workspace layout

```
salienture-workspace/
├── app/                 # Laravel application (symlink or clone)
├── docker/              # Compose stack + FrankenPHP image
├── docs/                # Human documentation
├── history/             # ADRs and session notes
├── scripts/             # Setup helpers
├── .devcontainer/       # VS Code / Cursor dev container
├── .cursor/rules/       # Cursor AI rules
├── .claude/             # Claude Code settings & commands
├── Makefile             # Primary dev interface
├── CLAUDE.md            # Claude Code project context
└── AGENTS.md            # Cross-agent instructions (Cursor, etc.)
```

## Design choices

1. **Monorepo workspace, separate app git** — `app/` points at the Salienture Laravel repo so application history stays in its own repository.

2. **FrankenPHP in Docker** — Matches modern PHP deployment (Caddy, HTTP/2, optional workers) without replacing Laravel’s `artisan` workflow.

3. **Vite on host** — Faster HMR and simpler debugging; Caddy proxies asset paths to port 5173.

4. **Redis for ephemeral state** — Sessions, cache, and queues use Redis in Docker; SQLite in `.env.example` is overridden by `make app-env-docker`.

5. **Makefile as CLI** — Single entry point for humans and AI agents; wraps `docker compose` and `artisan`.

## Application stack (Salienture)

- Laravel 13, PHP 8.3+
- Inertia.js 3 + React 19 + TypeScript + Tailwind CSS 4
- Laravel Fortify (auth)
- Pest 4 (tests)

See `app/` repository `CLAUDE.md` or `composer.json` for app-specific details once linked.
