const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

const VEHDB_TOKEN = defineSecret('VEHDB_TOKEN');
const VEHDB_BASE = 'https://api.vehdb.com/v1';

function sendJson(res, status, body) {
  res.status(status).set('Cache-Control', 'public, max-age=300').json(body);
}

async function vehdbGet(path, params = {}) {
  const url = new URL(`${VEHDB_BASE}${path}`);
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== null && `${value}`.trim() !== '') {
      url.searchParams.set(key, `${value}`);
    }
  }

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${VEHDB_TOKEN.value()}`,
      Accept: 'application/json',
    },
  });

  const text = await response.text();
  let body;
  try {
    body = text ? JSON.parse(text) : {};
  } catch (_) {
    body = { message: text || 'Invalid VehDB response' };
  }

  if (!response.ok) {
    const error = new Error(`VehDB HTTP ${response.status}`);
    error.status = response.status;
    error.body = body;
    throw error;
  }

  return body;
}

exports.vehdb = onRequest(
  {
    region: 'europe-west1',
    secrets: [VEHDB_TOKEN],
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (req, res) => {
    if (req.method !== 'GET') {
      return sendJson(res, 405, { error: 'Method not allowed' });
    }

    try {
      const route = req.path.replace(/^\/+|\/+$/g, '');
      let data;

      if (route === 'makes') {
        data = await vehdbGet('/tire-sizes/makes');
      } else if (route === 'models') {
        if (!req.query.make) return sendJson(res, 400, { error: 'make is required' });
        data = await vehdbGet('/tire-sizes/models', { make: req.query.make });
      } else if (route === 'cars') {
        const { make, model, year } = req.query;
        if (!make || !model || !year) {
          return sendJson(res, 400, { error: 'make, model and year are required' });
        }
        data = await vehdbGet('/cars', { make, model, year });
      } else if (route === 'sizes') {
        const { make, model, year } = req.query;
        if (!make || !model || !year) {
          return sendJson(res, 400, { error: 'make, model and year are required' });
        }
        data = await vehdbGet('/tire-sizes', {
          make,
          model,
          year,
          per_page: 100,
        });
      } else if (route.startsWith('car-sizes/')) {
        const carId = route.substring('car-sizes/'.length).trim();
        if (!carId) return sendJson(res, 400, { error: 'car id is required' });
        data = await vehdbGet(`/cars/${encodeURIComponent(carId)}/tire-sizes`);
      } else {
        return sendJson(res, 404, { error: 'Unknown endpoint' });
      }

      return sendJson(res, 200, data);
    } catch (error) {
      console.error('VehDB proxy error', error);
      return sendJson(res, error.status || 500, {
        error: 'VehDB request failed',
        details: error.body || error.message,
      });
    }
  },
);
