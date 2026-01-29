# CloudPanel Reverse Proxy Configuration

To expose your Docker containers through CloudPanel, follow these steps for each domain.

## 1. Create a "Reverse Proxy" Site in CloudPanel
In your CloudPanel dashboard:
1. Go to **Sites** > **Add Site** > **Create a Reverse Proxy Site**.
2. **Domain Name**: `ktd.alamiaconnect.com` (for Prod) or `demo.alamiaconnect.com` (for Demo).
3. **Reverse Proxy URL**:
   - For Production: `http://127.0.0.1:9001`
   - For Demo: `http://127.0.0.1:9000`

## 2. Configure SSL
Once the site is created:
1. Go to the site's **SSL** tab.
2. If you are using Cloudflare Tunnels (recommended), you can set SSL to "Disabled" or use a self-signed cert, as Cloudflare handles the encryption between the edge and your tunnel.
3. If you want CloudPanel to handle SSL, use the "New Let's Encrypt Certificate" option.

## 3. Cloudflare Tunnel (Optional but Recommended)
If you prefer Cloudflare Tunnels over direct IP access:
1. Ensure `cloudflared` is running on the VPS.
2. Add public hostnames in your Cloudflare Zero Trust dashboard:
   - `ktd.alamiaconnect.com` -> `http://localhost:9001`
   - `demo.alamiaconnect.com` -> `http://localhost:9000`

---

> [!TIP]
> Using CloudPanel as a reverse proxy allows you to easily manage logs and basic auth if needed, even for Docker-based sites.
