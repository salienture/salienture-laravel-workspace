# History

Local project memory: decisions, session notes, and migration from ad-hoc docs.

## Suggested layout

```
history/
├── decisions/     # ADRs (architecture decision records)
├── sessions/      # Dated work logs (YYYY-MM-DD-topic.md)
└── migrations/    # One-off upgrade / deploy notes
```

## Conventions

- Use `YYYY-MM-DD-short-title.md` for session files.
- Keep decisions short: context, decision, consequences.
- Do not commit secrets or customer data.
- Files matching `*.local.md` are gitignored.

## Example decision record

```markdown
# 2026-05-25 — FrankenPHP over php artisan serve

**Context:** Need production-parity HTTP/2 and worker mode locally.

**Decision:** FrankenPHP via Docker; Vite stays on host for HMR.

**Consequences:** APP_URL uses port 8080; queue runs in compose profile `workers`.
```
