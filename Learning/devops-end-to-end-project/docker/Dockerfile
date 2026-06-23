# ── Stage 1: dependencies ─────────────────────────────────────────────────────
FROM node:22-alpine AS deps

WORKDIR /app

# Copy only package files first — Docker caches this layer
# so npm ci only re-runs when dependencies actually change
COPY app/package*.json ./

RUN npm ci --only=production


# ── Stage 2: production image ─────────────────────────────────────────────────
FROM node:22-alpine AS runner

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy installed dependencies from stage 1
COPY --from=deps /app/node_modules ./node_modules

# Copy application source code
COPY app/app.js ./

# Set ownership to non-root user
RUN chown -R appuser:appgroup /app

USER appuser

# Document the port (doesn't publish it — that's done at docker run)
EXPOSE 3000

# Healthcheck — Docker itself will poll /health every 30s
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Environment defaults (overridable at runtime)
ENV NODE_ENV=production \
    PORT=3000 \
    APP_VERSION=1.0.0

# Start the app
CMD ["node", "app.js"]
