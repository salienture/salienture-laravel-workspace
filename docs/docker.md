# Docker stack

## Services

| Service | Image | Purpose |
|---------|-------|---------|
| `frankenphp` | Custom (`docker/frankenphp`) | PHP 8.3 app server (Caddy + FrankenPHP) |
| `mariadb` | `mariadb:11.4` | Primary database |
| `phpmyadmin` | `phpmyadmin:5` | DB admin UI |
| `mailpit` | `axllent/mailpit` | SMTP catch-all + web UI |
| `redis` | `redis:7-alpine` | Cache, sessions, queues |
| `queue` | Same as FrankenPHP | `queue:listen` (profile: `workers`) |
| `scheduler` | Same as FrankenPHP | `schedule:work` (profile: `workers`) |

## Ports (defaults)

Configure in workspace `.env`:

| Variable | Default | Service |
|----------|---------|---------|
| `APP_HTTP_PORT` | 8080 | FrankenPHP HTTP |
| `APP_HTTPS_PORT` | 8443 | FrankenPHP HTTPS |
| `DB_PORT` | 3306 | MariaDB |
| `PMA_PORT` | 8081 | phpMyAdmin |
| `MAILPIT_SMTP_PORT` | 1025 | Mail SMTP |
| `MAILPIT_UI_PORT` | 8025 | Mail UI |
| `REDIS_PORT` | 6379 | Redis |

## Volumes

- `mariadb_data` — database files
- `redis_data` — Redis AOF
- `caddy_data` / `caddy_config` — TLS and Caddy state

## FrankenPHP / Caddy

- Caddyfile: `docker/frankenphp/Caddyfile`
- Document root: `/app/public` (Laravel)
- Vite proxy: requests under `/build` and `/resources` forward to `host.docker.internal:5173` when Vite runs on the host

## Troubleshooting

**App shows 502 / empty**

- Ensure `app/` is linked and contains `vendor/` (`make app-install`)
- Check logs: `make logs`

**Database connection refused**

- Wait for MariaDB healthcheck: `make ps`
- Confirm `app/.env` has `DB_HOST=mariadb` (`make app-env-docker`)

**Vite assets 404**

- Run `make vite` on the host
- Or build assets: `make npm ARGS="run build"`

**Reset everything**

```bash
make destroy   # removes volumes — deletes DB data
make init
```
