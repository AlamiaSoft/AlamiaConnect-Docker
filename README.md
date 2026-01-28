# AlamiaConnect Dockerization

## Introduction

[AlamiaConnect](https://alamiaconnect.com) is a hand-tailored CRM framework built on [Krayin CRM](https://krayincrm.com), leveraging [Laravel](https://laravel.com) and [Next.js](https://nextjs.org).

**Free & Opensource CRM solution for complete customer lifecycle management.**

## Docker Architecture

This repository handles the backend Dockerization (Admin Panel + REST APIs). The frontend is typically deployed separately (e.g., Cloudflare Pages).

The architecture includes:
- **PHP 8.4 + Apache**: The core Laravel application.
- **MySQL 8.0**: Persistent database storage.
- **Redis 6.2**: For caching and queues.
- **PHPMyAdmin**: Database management interface.
- **Mailhog**: Local SMTP testing.

## Deployment (VPS / Portainer)

1. Set the following environment variables in your Portainer stack or `.env` file:
   - `BACKEND_REPO_URL`: The Git URL of your AlamiaConnect-Backend.
   - `BACKEND_REPO_BRANCH`: The branch to deploy (defaults to `main`).
   - `DB_PASSWORD`: Root password for MySQL (defaults to `root`).
   - `ALAMIA_ADMIN_NAME`: Initial admin name.
   - `ALAMIA_ADMIN_EMAIL`: Initial admin email.
   - `ALAMIA_ADMIN_PASSWORD`: Initial admin password.

2. Deploy the stack using the `docker-compose.yml`.

3. The `entrypoint.sh` will automatically:
   - Clone/Pull the repository.
   - Install Composer and NPM dependencies.
   - Build Vite assets for all packages.
   - Run the specialized `alamia:install-docker` command.

## Local Test

If you have Docker Desktop, you can test locally by running:

```sh
docker-compose up -d
```

## After Installation

- **Admin Panel**: `http://localhost/admin/login`
- **PHPMyAdmin**: `http://localhost:8080`
- **Mailhog**: `http://localhost:8025`

Default Admin Credentials:
- **Email**: admin@alamiaconnect.com
- **Password**: admin123
