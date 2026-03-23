---
agent: Debug Mode Instructions
description: "Debug Adventure OTS issues end-to-end with Docker-first reproduction, root-cause analysis, and verified fix evidence."
---

Debug Adventure OTS using the repository Debug Mode workflow.

Issue description:
- `${issue}`

Context to include:
- `${context}`

Required process:
1. Reproduce first using Docker-first steps.
2. Capture exact logs and errors.
3. Identify root cause with concrete evidence.
4. Apply minimal safe fix.
5. Verify with commands proving:
   - previous error is gone,
   - target behavior works,
   - no immediate regression in adjacent services.

Docker checklist:
- `docker compose up -d --build`
- `docker compose --profile debug up -d` (optional debug tools)
- `docker compose ps`
- `docker logs ots_engine --tail 200`
- `docker logs aac_api --tail 200`
- `docker logs aac_proxy --tail 200`
- `docker logs ots_db --tail 200`

Output format:
1. Reproduction summary (expected vs actual)
2. Root cause analysis
3. Fix details (files changed)
4. Verification commands/results
5. Residual risks and recommendations
