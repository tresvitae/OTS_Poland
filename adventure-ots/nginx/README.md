# Nginx Reverse Proxy (Adventure OTS)

Nginx is the public entrypoint for the Adventure OTS web stack.

It routes:

- API requests to AAC backend
- Website traffic to AAC frontend
- Download files directly from mounted static storage

## Responsibilities

- Reverse proxy for frontend and backend containers
- Single public HTTP endpoint on port 80
- Static file serving for client downloads
- Basic response compression and security headers

## Files

```text
nginx/
├── Dockerfile          # Nginx runtime image
├── nginx.conf          # Main reverse proxy configuration
├── README.md
└── downloads/          # Optional local download content source
```

## Traffic Routing

Configured in `nginx.conf`:

- `/api/` -> `aac-backend:3001`
- `/downloads/` -> direct file serving from `/srv/downloads/`
- `/` -> `aac-frontend:3000`

This allows browser clients to call API under the same origin path (`/api`) without CORS complexity in standard deployment.

## Upstreams

Defined upstream groups:

- `backend`: `aac-backend:3001`
- `frontend`: `aac-frontend:3000`

These hostnames match Docker Compose service names.

## Download Serving

Nginx serves downloads via:

- URL prefix: `/downloads/`
- Filesystem path (container): `/srv/downloads/`

Behavior:

- `try_files $uri =404` returns 404 for missing files
- `autoindex off` disables directory listing
- `Cache-Control: public, max-age=600` enables short-lived caching

In main Compose setup, this path is mounted from:

- host: `adventure-ots/aac-frontend/public/downloads`
- container: `/srv/downloads`

## Proxy Headers

Forwarded to upstreams:

- `Host`
- `X-Real-IP`
- `X-Forwarded-For`
- `X-Forwarded-Proto`

WebSocket upgrade headers are also set on frontend route:

- `Upgrade`
- `Connection: upgrade`

## Timeouts and Performance

Enabled/Configured:

- `sendfile on`
- `tcp_nopush on`
- `keepalive_timeout 65`
- `gzip on` for text, css, json, javascript, xml

API proxy timeouts:

- connect: 30s
- send: 30s
- read: 30s

## Security Headers

Always added:

- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`

## Docker Image

Image is built from `nginx:alpine` and only copies custom config:

1. `FROM nginx:alpine`
2. `COPY nginx.conf /etc/nginx/nginx.conf`
3. `EXPOSE 80`

## Run in Adventure OTS Compose

From the project root:

```bash
cd adventure-ots
docker compose up -d --build nginx
```

Or run full stack:

```bash
cd adventure-ots
docker compose up -d --build
```

Default public URL:

- http://localhost

## Verification Checklist

After startup, verify:

1. Homepage loads at `http://localhost`
2. Health API works at `http://localhost/api/health`
3. Download endpoint works for existing files under `/downloads/...`

## Logs and Debugging

Container logs:

```bash
docker logs -f aac_proxy
```

Inside container:

- access log: `/var/log/nginx/access.log`
- error log: `/var/log/nginx/error.log`

Common issues:

1. `502 Bad Gateway` on `/api`:
	backend container not running, unhealthy, or wrong upstream host/port.
2. `502 Bad Gateway` on `/`:
	frontend container not running or failed to start.
3. `404` on `/downloads/...`:
	file missing in mounted downloads directory.
4. Changes to `nginx.conf` not visible:
	rebuild/restart proxy container.

## Notes

- This config currently serves HTTP only (port 80), no TLS termination.
- If HTTPS is needed, extend this service with certificates and `listen 443 ssl` server block.

