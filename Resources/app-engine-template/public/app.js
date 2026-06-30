const state = {
  site: null,
  products: [],
};

const formatPrice = new Intl.NumberFormat('ko-KR', {
  style: 'currency',
  currency: 'KRW',
  maximumFractionDigits: 0,
});

function text(value, fallback = '') {
  return value == null || value === '' ? fallback : String(value);
}

async function fetchJson(url) {
  const response = await fetch(url, {
    headers: { accept: 'application/json' },
  });
  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload.error || `Request failed: ${url}`);
  }
  return payload;
}

function setDocumentMeta(sitePayload) {
  const name = sitePayload?.seller?.nickname || sitePayload?.config?.site?.name || 'cannedfruits';
  const description = sitePayload?.config?.site?.description || '';
  document.title = name;
  document.querySelector('meta[name="description"]')?.setAttribute('content', description);
}

function applyTheme(config = {}) {
  const theme = config.theme || {};
  const root = document.documentElement;

  if (theme.background) root.style.setProperty('--bg', theme.background);
  if (theme.text) root.style.setProperty('--ink', theme.text);
  if (theme.accent) root.style.setProperty('--accent', theme.accent);
}

function renderBrand(payload) {
  const seller = payload.seller || {};
  const config = payload.config || {};
  const brand = document.getElementById('site-brand');
  const logo = document.getElementById('site-logo');
  const favicon = document.getElementById('site-favicon');
  const logoConfig = config.design?.logo || {};

  if (brand) brand.textContent = seller.nickname || config.site?.name || 'cannedfruits';

  if (logoConfig.symbol && logo) {
    logo.src = logoConfig.symbol;
    logo.hidden = false;
  }

  if (logoConfig.favicon && favicon) {
    favicon.href = logoConfig.favicon;
  }
}

function renderStoreIntro(payload) {
  const config = payload.config || {};
  const description = document.getElementById('store-description');
  const descriptionText = config.site?.description || '';

  if (description) {
    description.textContent = descriptionText;
    description.hidden = !descriptionText;
  }
}

function renderFooter(payload) {
  const seller = payload.seller || {};
  const config = payload.config || {};
  const statement = document.getElementById('footer-statement');
  const disclaimer = document.getElementById('footer-disclaimer');
  const legal = document.getElementById('footer-legal');

  if (statement) {
    statement.textContent = `This independent storefront mirrors public FruitsFamily product data for ${seller.nickname || config.site?.name || 'this seller'}.`;
  }

  if (disclaimer) {
    disclaimer.textContent = config.cta?.disclaimer || '';
  }

  if (legal) {
    legal.textContent = config.legal?.disclaimer || '';
  }
}

function productCard(product) {
  const status = product.status === 'sold' ? 'Sold' : 'Available';
  const price = product.price ? formatPrice.format(product.price) : 'Price on FruitsFamily';
  const meta = text(product.brand);

  return `
    <article class="product-card ${product.status === 'sold' ? 'is-sold' : ''}">
      <a href="/product.html?id=${product.id}" aria-label="${text(product.title)}">
        <div class="product-image-wrap">
          ${
            product.image
              ? `<img src="${product.image}" alt="${text(product.title)}" loading="lazy" decoding="async" />`
              : '<div class="image-placeholder"></div>'
          }
          ${product.status === 'sold' ? `<span class="status-badge">${status}</span>` : ''}
        </div>
        <div class="product-info">
          <div>
            <h2>${text(product.title, 'Untitled product')}</h2>
            ${meta ? `<p class="product-meta">${meta}</p>` : ''}
          </div>
          <p class="product-price">${price}</p>
        </div>
      </a>
    </article>
  `;
}

function getVisibleProducts() {
  let items = [...state.products];

  items.sort((a, b) => {
    return new Date(b.createdAt || 0) - new Date(a.createdAt || 0);
  });

  return items;
}

function renderProducts() {
  const grid = document.getElementById('product-grid');
  const counter = document.getElementById('product-count');
  const items = getVisibleProducts();

  if (counter) {
    counter.textContent = `${items.length} products`;
  }

  if (!items.length) {
    grid.innerHTML = '<div class="empty">No products to display.</div>';
    return;
  }

  grid.innerHTML = items.map(productCard).join('');
}

async function boot() {
  try {
    const [sitePayload, productsPayload] = await Promise.all([
      fetchJson('/api/site'),
      fetchJson('/api/products'),
    ]);

    state.site = sitePayload;
    state.products = productsPayload.items || [];

    setDocumentMeta(sitePayload);
    applyTheme(sitePayload.config);
    renderBrand(sitePayload);
    renderStoreIntro(sitePayload);
    renderFooter(sitePayload);
    renderProducts();
  } catch (error) {
    document.getElementById('product-grid').innerHTML = `
      <div class="empty">
        Could not load FruitsFamily listings.<br />
        ${text(error.message)}
      </div>
    `;
  }
}

boot();
