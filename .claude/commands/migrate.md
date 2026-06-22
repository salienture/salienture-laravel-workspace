---
description: Run Laravel migrations in the FrankenPHP container
---

Run database migrations:

1. `make up` if stack is not running.
2. `make migrate` (or `make artisan ARGS="migrate"` for options).
3. On schema conflicts in local dev only, mention `make fresh` as destructive recovery.
