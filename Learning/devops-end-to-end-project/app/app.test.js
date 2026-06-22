'use strict';

const request = require('supertest');
const app = require('./app');

describe('GET /', () => {
  it('returns 200 with a welcome message', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Hello from the DevOps Node.js app!');
    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('environment');
  });
});

describe('GET /health', () => {
  it('returns 200 with status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body).toHaveProperty('uptime');
    expect(res.body).toHaveProperty('timestamp');
  });
});

describe('GET /ready', () => {
  it('returns 200 with status ready', async () => {
    const res = await request(app).get('/ready');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ready');
  });
});

describe('GET /info', () => {
  it('returns 200 with app metadata', async () => {
    const res = await request(app).get('/info');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('name');
    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('node');
    expect(res.body).toHaveProperty('memory');
  });
});

describe('GET /unknown-route', () => {
  it('returns 404 for unknown routes', async () => {
    const res = await request(app).get('/this-does-not-exist');
    expect(res.statusCode).toBe(404);
    expect(res.body).toHaveProperty('error');
  });
});