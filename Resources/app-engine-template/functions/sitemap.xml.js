import { fetchSellerProducts } from './_fruits.js';
import { getSiteConfig } from './_config.js';

function escapeXml(value) {
  return String(value || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

function xmlResponse(body) {
  return new Response(body, {
    headers: {
      'content-type': 'application/xml; charset=utf-8',
      'cache-control': 'public, max-age=300, s-maxage=1800',
    },
  });
}

function siteOrigin(config) {
  const domain = config.site.domain || 'localhost:8788';
  return domain.startsWith('http') ? domain : `https://${domain}`;
}

function urlEntry(loc, lastmod, priority = '0.7') {
  return [
    '  <url>',
    `    <loc>${escapeXml(loc)}</loc>`,
    lastmod ? `    <lastmod>${escapeXml(lastmod)}</lastmod>` : '',
    `    <priority>${priority}</priority>`,
    '  </url>',
  ]
    .filter(Boolean)
    .join('\n');
}

export async function onRequestGet({ env }) {
  const config = getSiteConfig(env);
  const origin = siteOrigin(config);
  const now = new Date().toISOString();
  const urls = [urlEntry(`${origin}/`, now, '1.0')];

  try {
    const payload = await fetchSellerProducts(env);
    for (const product of payload.items || []) {
      urls.push(urlEntry(`${origin}/product.html?id=${product.id}`, product.createdAt || now, '0.8'));
    }
  } catch {
    // Keep sitemap valid even when the upstream API fails.
  }

  return xmlResponse(
    [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
      ...urls,
      '</urlset>',
    ].join('\n'),
  );
}

