# Changelog

## [1.0.0] - 2026-01-28

### Adapted
- Adapted Krayin Dockerization to AlamiaConnect.
- Switched to PHP 8.4 and Node.js 22.
- Renamed all services with `ac-` prefix.
- Overhauled initialization logic to support VPS/Portainer deployment via `entrypoint.sh`.
- Added automated asset building (NPM phase) for all packages.
- Introduced `alamia:install-docker` specialized installer to handle migration conflicts.
