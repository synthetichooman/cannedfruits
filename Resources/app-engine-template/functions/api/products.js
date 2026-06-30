import { fetchSellerProducts, jsonResponse, readProductsFallback } from '../_fruits.js';

export async function onRequestGet({ env }) {
  try {
    const payload = await fetchSellerProducts(env);
    return jsonResponse(payload);
  } catch (error) {
    const fallback = await readProductsFallback(env);
    if (fallback) {
      return jsonResponse({ ...fallback, stale: true, error: String(error.message || error) });
    }

    return jsonResponse({ error: String(error.message || error), items: [] }, 502, {
      'cache-control': 'no-store',
    });
  }
}

