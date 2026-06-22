# AGENTS.md

Instructions for AI coding agents (Cursor, Claude Code, Copilot, etc.) in the workspace.

## Repository model

- **Workspace root** — Docker, Makefile, docs, AI config (you are here)
- **`app/`** — Laravel application; may be a symlink to another git repo

Prefer `make <target>` over raw `docker compose` or host `php artisan` unless the user explicitly runs without Docker.

## Before changing code

1. Confirm `app/` exists (`make link-app` if not)
2. Read `CLAUDE.md` and `docs/architecture.md`
3. For app-only work, follow patterns in `app/` (Inertia pages, Fortify, Pest)

## Safe defaults

- Do not create git commits unless asked
- Do not modify `app/.env` secrets; use `.env.example` and `make app-env-docker`
- Minimize diff scope — workspace vs app changes should not mix in one unrelated PR

## Testing

```bash
make test          # inside container
make pint          # PHP style
cd app && npm run lint   # ESLint (host or container)
```

## Key paths

| Task | Location |
|------|----------|
| Routes / controllers | `app/routes/`, `app/app/Http/` |
| React pages | `app/resources/js/Pages/` |
| Docker | `docker/compose.yml` |
| Env patch script | `scripts/patch-app-env.sh` |
