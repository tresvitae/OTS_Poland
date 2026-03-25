---
name: Nginx Edge Integration
description: "Nginx reverse-proxy and edge routing guidance for Adventure OTS. Use when: updating nginx.conf, tuning headers/timeouts/caching, changing /api forwarding, or validating frontend/backend edge behavior."
applyTo: "adventure-ots/nginx/**"
---

# Nginx Edge Integration Guidelines

**Location**: `adventure-ots/nginx/`

Use these rules when changing nginx proxy behavior for Adventure OTS.

## Core Routing Contract

1. Keep `/api/` routed to backend unless explicitly requested otherwise.
2. Keep non-API routes routed to frontend.
3. Preserve required proxy headers for upstream services.

## Change Safety

1. Keep changes minimal and scoped to the requested behavior.
2. Avoid broad rewrites of nginx structure unless requested.
3. Document any user-visible behavior changes (redirects, caching, downloads, errors).

## Validation Checklist

After config updates, validate:
1. API path responds through nginx (for example `/api/health`).
2. Frontend root path responds through nginx (`/`).
3. Any changed special route (for example `/downloads/`) behaves as expected.
4. No accidental header or timeout regressions.

## Operational Notes

1. Keep backend/frontend service names aligned with compose networking.
2. Call out rollback steps when changing routing logic.
3. Prefer explicitness over implicit defaults for edge-critical directives.
