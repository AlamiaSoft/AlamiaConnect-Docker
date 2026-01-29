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

## 3. Deploying via Portainer Stacks (Optional)

While the `deploy.sh` script is the recommended way to manage the multi-tenant folders, you can also deploy directly via Portainer Stacks:

1. Go to **Stacks** > **Add stack**.
2. **Build method**: Repository or Web editor.
3. Paste the contents of your `docker-compose.yml`.
4. Define the Environment Variables (like `APP_PORT`, `PROJECT_NAME`) in the Portainer UI under **Environment variables**.
5. Portainer will use the credentials added in Step B to pull the image automatically.

---

> [!IMPORTANT]
> Since we use a custom `entrypoint.sh` that clones code at runtime, ensure the `BACKEND_REPO_URL` and `BACKEND_REPO_BRANCH` variables are correctly set in Portainer so the container knows what to download.
