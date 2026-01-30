# Blueprint: Next.js Frontend Deployment Strategy

As we move toward deploying the Next.js frontend for various clients, we will maintain the same professional isolation standards used for the backend.

## 1. Directory Structure

Next.js apps will be centralized similarly to the backend instances.

**Root Path**: `/home/alamiaconnect/clients/nextjs/`

**Structure**:
```text
/home/alamiaconnect/clients/
└── nextjs/
    ├── demo/
    ├── ktd/
    └── mkautos/
```

## 2. Port Management (Standardized)

We will allocate a distinct port range for frontends to avoid overlap with backends (9000 range).

**Recommended Range**: `3000` series
- **Demo Frontend**: `3000`
- **KTD Frontend**: `3100`
- **MKAutos Frontend**: `3200`

## 3. Environment Variable Standards

Each Next.js instance will need a `.env.production` file that points to its specific backend instance:

**Example (KTD Demo Frontend)**:
- `NEXT_PUBLIC_API_URL=https://demo-ktd.alamiaconnect.com`
- `PORT=3100`

## 4. Dockerization Strategy

We will use a multi-stage Dockerfile for the frontend:
1. **Build Stage**: Runs `npm run build`.
2. **Runner Stage**: Uses a lightweight Node-Alpine image to serve the `standalone` output.

## 5. Routing (Cloudflare Tunnels)

Just like the backend, the tunnel will point directly to the Node.js port.

`Cloudflare (e.g. crm.kausartrade.com)` -> `Tunnel` -> `http://localhost:3100`

---

> [!NOTE]
> By keeping the backend and frontend on separate ports and using clear environment variables, we ensure that a "Stage" frontend never accidentally talks to a "Prod" backend.
