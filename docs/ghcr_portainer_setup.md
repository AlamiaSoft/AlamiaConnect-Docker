# GHCR & Portainer Setup Guide

This guide explains how to manage your Docker images using GitHub Container Registry (GHCR) and how to configure Portainer on your Hetzner VPS to pull these private images.

## 1. GHCR Image Naming Policy

Your images are automatically built and tagged by the GitHub Action in `.github/workflows/docker-publish.yml`.

- **Registry**: `ghcr.io`
- **Image Name**: `ghcr.io/alamiasoft/alamia-connect-docker` (always lowercase)
- **Tags**:
    - `main`: The latest stable image from the main branch.
    - `sha-<commit-hash>`: Specific builds for traceability.
    - `v*`: Semantic versioning if you use Git tags (e.g., `v1.0.0`).

### Example URI:
`ghcr.io/alamiasoft/alamia-connect-docker:main`

---

## 2. Portainer Configuration

To allow Portainer (and the VPS) to pull your images from GHCR, you need to add the GitHub Registry.

### Step A: Generate a GitHub PAT (token)
1. Go to **GitHub Settings** > **Developer Settings** > **Personal access tokens** > **Tokens (classic)**.
2. Generate a new token with at least `read:packages` scope.
3. Copy the token.

### Step B: Add Registry in Portainer
1. Open your Portainer dashboard.
2. Go to **Registries** > **Add registry**.
3. Select **Custom registry**.
4. **Name**: `GitHub Container Registry`
5. **Registry URL**: `ghcr.io`
6. **Authentication**: Toggle **ON**.
7. **Username**: Your GitHub username.
8. **Password/PAT**: Paste the token you created in Step A.
9. Click **Add registry**.

---

## 4. CLI vs Portainer UI: How they work together

It is important to understand that **Portainer is a mirror of your Docker engine**.

- **Option A (The Script Way)**: When you run `./deploy.sh` on the CLI, it uses `docker-compose`. Portainer will **automatically detect** these containers. They will appear under the **Stacks** or **Containers** menu in the Portainer UI without you doing anything.
- **Option B (The Portainer Way)**: If you prefer to use Portainer's web interface to click "Deploy", you should use the **Stacks** feature and point it to your GitHub repo.

> [!TIP]
> **Use the Script (`deploy.sh`)** for the initial setup. It's faster and handles the complex folder/branch logic. Use **Portainer** for monitoring, checking logs, and restarting containers via the web UI.

---

> [!IMPORTANT]
> Since we use a custom `entrypoint.sh` that clones code at runtime, ensure the `BACKEND_REPO_URL` and `BACKEND_REPO_BRANCH` variables are correctly set in Portainer so the container knows what to download.
