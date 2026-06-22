---
description: Start the Docker dev stack and show service URLs
---

Start the Salienture workspace development environment.

1. Ensure `.env` exists at workspace root (copy from `.env.example` if missing).
2. Ensure `app/` is linked (`make link-app SOURCE=../salienture` if `app/artisan` is missing).
3. Run `make up` and `make workers-up` if queue processing is needed.
4. Report URLs: app (8080), Mailpit (8025), phpMyAdmin (8081).
5. Remind the user to run `make vite` in another terminal for frontend HMR.
