import { fetchProductDetail, jsonResponse, readProductFallback } from '../_fruits.js';

export async function onRequestGet({ request, env }) {
  const url = new URL(request.url);
  const id = Number(url.searchParams.get('id'));

  if (!Number.isFinite(id) || id <= 0) {
    return jsonResponse({ error: 'Missing valid product id.' }, 400, {
      'cache-control': 'no-store',
    });
  }

  try {
    const payload = await fetchProductDetail(env, id);
    return jsonResponse(payload);
  } catch (error) {
    const fallback = await readProductFallback(env, id);
    if (fallback) {
      return jsonResponse({ ...fallback, stale: true, error: String(error.message || error) });
    }

    return jsonResponse({ error: String(error.message || error) }, 502, {
      'cache-control': 'no-store',
    });
  }
}

