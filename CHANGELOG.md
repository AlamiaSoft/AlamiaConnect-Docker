## **v1.1.0 (10th of February 2026)** - *Infrastructure & Frontend Unified*

- **Unified Infrastructure**: Added support for deploying Next.js frontends alongside Laravel backends.
- **Data Safety**: Introduced `storage/installed` check to prevent accidental database resets on container restart.
- **Improved Deployment**: `deploy.sh` now auto-syncs frontend and backend repositories.
- **Secure Auth**: Integrated Sanctum stateful domains and explicit CORS origin configuration for cross-subdomain SPA authentication.
- **Optimization**: Frontend now uses Next.js `standalone` mode in production Docker builds.

## **v1.0.0 (20th of September 2024)** - *First Release*

- Initial release for **AlamiaConnect** (based on Krayin v2.0.0+).
