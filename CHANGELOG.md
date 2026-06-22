# Changelog

All notable changes to this **workspace** (not the Laravel app in `app/`) are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Initial workspace scaffold
- Docker Compose: FrankenPHP, MariaDB, phpMyAdmin, Mailpit, Redis
- Optional queue and scheduler services (`workers` profile)
- Makefile with `init`, `link-app`, and common Laravel targets
- Dev container configuration
- Documentation (`docs/`), history folders, Claude & Cursor setup
- Script to patch `app/.env` for Docker service hostnames
