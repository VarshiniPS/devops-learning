'use strict';

const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || '1.0.0';
const ENV = process.env.NODE_ENV || 'development';

app.use(express.json());

// ── Routes ────────────────────────────────────────────────────────────────────

// GET / — home
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from the DevOps Node.js app!',
    version: VERSION,
    environment: ENV,
  });
});

// GET /health — liveness probe (Kubernetes uses this)
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

// GET /ready — readiness probe (Kubernetes uses this)
app.get('/ready', (req, res) => {
  res.json({
    status: 'ready',
    timestamp: new Date().toISOString(),
  });
});

// GET /info — app metadata
app.get('/info', (req, res) => {
  res.json({
    name: 'devops-node-app',
    version: VERSION,
    environment: ENV,
    node: process.version,
    pid: process.pid,
    memory: process.memoryUsage(),
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found', path: req.path });
});

// ── Start server (only when run directly, not when imported by tests) ─────────
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${ENV}`);
    console.log(`Version:     ${VERSION}`);
  });
}

module.exports = app;