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

> [!CAUTION]
> **Avoid Protocol Mismatch (502 Errors)**:
> If you are using Cloudflare Tunnels, it is **highly recommended** to point the tunnel directly to the Docker port (e.g., `localhost:9000`) using the **HTTP** protocol.
> 
> Sending HTTPS traffic from a tunnel into a CloudPanel Reverse Proxy that then hits an HTTP Docker port often results in SSL handshake failures and 502 errors.

> [!TIP]
> Use CloudPanel for static sites and PHP-FPM sites. For Dockerized AlamiaConnect instances, use the Cloudflare Tunnel as the primary entry point.
