# Docker Optimization Roadmap

To address the build time (~5 mins) and large image size, we can implement the following optimizations in future phases.

## 1. Multi-Stage Builds
**Goal**: Reduce image size by keeping only necessary runtime files.
- **Node Stage**: Build assets (JS/CSS) in a temporary Node.js container.
- **PHP Stage**: Copy only the *built* assets and vendor folder into the final PHP/Apache image.
- **Result**: Node.js and its large `node_modules` folder won't be in the final production image.

## 2. Optimized Layer Caching
**Goal**: Speed up rebuilding when only code changes.
- Copy `composer.json`, `composer.lock`, `package.json`, and `package-lock.json` *before* the rest of the source code.
- Run `composer install` and `npm install` immediately after.
- **Result**: Docker will cache the dependency layers. If you only change a PHP controller, Docker skips the "install dependencies" steps entirely.

## 3. Alpine-Based Foundation
**Goal**: Use a much smaller base OS.
- Switch from `php:8.3-apache` (Debian-based, ~400MB) to `php:8.3-fpm-alpine` (Alpine-based, ~50MB).
- Note: This would require switching from Apache to Nginx, as Apache is not standard on Alpine.

## 4. Offloading Builders to CI (GitHub Actions)
**Goal**: Make the image ready-to-run immediately.
- Instead of cloning the repo in the `entrypoint.sh` on the VPS, build the entire application inside GitHub Actions.
- Bake the vendor and public/build folders into the image.
- **Result**: The container starts in seconds because everything is already "baked in."

## 5. Cleaning Up Build Artifacts
**Goal**: Reduce layer bloat.
- After `apt-get install`, run `rm -rf /var/lib/apt/lists/*`.
- Use `--no-install-recommends` with `apt-get`.
- Combine all `RUN` commands into a single block to reduce the number of intermediate layers.

## 6. Effective `.dockerignore`
**Goal**: Don't send unnecessary files to the Docker daemon.
- Ensure `.git`, `node_modules`, `storage/logs`, and local `.env` files are in `.dockerignore`.

---

> [!NOTE]
> Currently, the setup is designed for **flexibility** (cloning code on the fly). While this is great for development and rapid testing, moving to a **Pre-built/Baked** strategy (Point 4) is the ultimate way to achieve sub-1-minute deployments.
