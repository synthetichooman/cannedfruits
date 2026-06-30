import { onRequestGet as site } from '../functions/api/site.js';
import { onRequestGet as products } from '../functions/api/products.js';
import { onRequestGet as product } from '../functions/api/product.js';

async function readJson(response) {
  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload.error || `HTTP ${response.status}`);
  }
  return payload;
}

const env = { SITE_DOMAIN: 'localhost:8788' };

const sitePayload = await readJson(
  await site({
    env,
    request: new Request('http://localhost:8788/api/site'),
  }),
);

const productsPayload = await readJson(
  await products({
    env,
    request: new Request('http://localhost:8788/api/products'),
  }),
);

const first = productsPayload.items?.[0];
if (!first) {
  throw new Error('No products returned.');
}

const detailPayload = await readJson(
  await product({
    env,
    request: new Request(`http://localhost:8788/api/product?id=${first.id}`),
  }),
);

console.log(
  JSON.stringify(
    {
      seller: sitePayload.seller.nickname,
      products: productsPayload.items.length,
      firstProduct: detailPayload.product.title,
      firstProductUrl: detailPayload.product.fruitsUrl,
    },
    null,
    2,
  ),
);

