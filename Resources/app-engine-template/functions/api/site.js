import { fetchSellerProfile, jsonResponse, readSiteFallback } from '../_fruits.js';

export async function onRequestGet({ env }) {
  try {
    const payload = await fetchSellerProfile(env);
    return jsonResponse(payload);
  } catch (error) {
    const fallback = await readSiteFallback(env);
    if (fallback) {
      return jsonResponse({ ...fallback, stale: true, error: String(error.message || error) });
    }

    return jsonResponse({ error: String(error.message || error) }, 502, {
      'cache-control': 'no-store',
    });
  }
}

