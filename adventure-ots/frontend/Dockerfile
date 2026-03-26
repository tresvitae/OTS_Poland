# ==============================
# Frontend — Multi-stage Build
# Next.js 14 with standalone output
# ==============================

# Stage 1: Install dependencies
FROM node:20.19.0-bookworm-slim AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: Build application
FROM node:20.19.0-bookworm-slim AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN mkdir -p public
RUN npm run build

# Stage 3: Production runtime
FROM node:20.19.0-bookworm-slim
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy standalone output
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 3000

CMD ["node", "server.js"]
