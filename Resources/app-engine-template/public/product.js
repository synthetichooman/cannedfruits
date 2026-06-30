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

function productImages(product) {
  return product.bigImages?.length ? product.bigImages : product.images || [];
}

function imageGallery(product) {
  const images = productImages(product);
  const [firstImage, ...restImages] = images;
  if (!firstImage) return '<div class="detail-gallery"><div class="image-placeholder detail-main-image"></div></div>';
  const thumbnailImages = images.length > 1 ? images : restImages;

  return `
    <div class="detail-gallery">
      <img
        id="detail-main-image"
        class="detail-main-image"
        src="${firstImage}"
        alt="${text(product.title)} image 1"
        loading="eager"
        decoding="async"
      />
      ${
        thumbnailImages.length
          ? `<div class="detail-thumbs">
      ${thumbnailImages
        .map(
          (src, index) => `
            <button
              class="thumb-button ${index === 0 ? 'is-active' : ''}"
              type="button"
              data-src="${src}"
              data-alt="${text(product.title)} image ${index + 1}"
              aria-label="Show image ${index + 1}"
            >
              <img
                src="${src}"
                alt=""
                loading="lazy"
                decoding="async"
              />
            </button>
          `,
        )
        .join('')}
        </div>`
          : ''
      }
    </div>
  `;
}

function bindGallery(root) {
  const mainImage = root.querySelector('#detail-main-image');
  const buttons = [...root.querySelectorAll('.thumb-button')];
  if (!mainImage || buttons.length === 0) return;

  buttons.forEach((button) => {
    button.addEventListener('click', () => {
      mainImage.src = button.dataset.src;
      mainImage.alt = button.dataset.alt || mainImage.alt;
      buttons.forEach((item) => item.classList.toggle('is-active', item === button));
    });
  });
}

function applyTheme(config = {}) {
  const theme = config.theme || {};
  const root = document.documentElement;

  if (theme.background) root.style.setProperty('--bg', theme.background);
  if (theme.text) root.style.setProperty('--ink', theme.text);
  if (theme.accent) root.style.setProperty('--accent', theme.accent);
}

function renderBrand(sitePayload = {}) {
  const config = sitePayload.config || {};
  const siteName = sitePayload.seller?.nickname || config.site?.name || 'cannedfruits';
  const brand = document.getElementById('site-brand');
  const logo = document.getElementById('site-logo');
  const favicon = document.getElementById('site-favicon');
  const logoConfig = config.design?.logo || {};

  if (brand) brand.textContent = siteName;

  if (logoConfig.symbol && logo) {
    logo.src = logoConfig.symbol;
    logo.hidden = false;
  }

  if (logoConfig.favicon && favicon) {
    favicon.href = logoConfig.favicon;
  }
}

function renderProduct(payload, sitePayload = {}) {
  const product = payload.product;
  const config = sitePayload.config || {};
  const root = document.getElementById('product-root');
  const isSold = product.status === 'sold';
  const price = product.price ? formatPrice.format(product.price) : 'Price on FruitsFamily';
  const original = product.originalPrice
    ? `<span class="original-price">${formatPrice.format(product.originalPrice)}</span>`
    : '';
  const siteName = sitePayload.seller?.nickname || config.site?.name || 'cannedfruits';
  const ctaLabel = isSold ? config.cta?.soldLabel || 'View sold item on FruitsFamily' : config.cta?.label || 'Buy on FruitsFamily';
  const disclaimer =
    config.cta?.disclaimer ||
    'Product data is mirrored from FruitsFamily. Checkout and final availability are handled by FruitsFamily.';

  document.title = `${product.title} | ${siteName}`;
  document.querySelector('meta[name="description"]')?.setAttribute('content', product.description || product.title);
  renderBrand(sitePayload);
  document.getElementById('footer-disclaimer').textContent = disclaimer;
  document.getElementById('footer-legal').textContent = config.legal?.disclaimer || '';
  applyTheme(config);

  root.innerHTML = `
    <section class="detail-layout">
      ${imageGallery(product)}
      <aside class="detail-panel">
        <a class="back-link" href="/">back</a>
        <p class="product-brand">${text(product.brand, 'No Brand')}</p>
        <h1>${text(product.title, 'Untitled product')}</h1>
        <div class="detail-status ${isSold ? 'sold' : 'available'}">
          ${isSold ? 'Sold' : 'Available'}
        </div>
        <div class="detail-price">${price} ${original}</div>
        <a class="cta" href="${product.fruitsUrl}" target="_blank" rel="noopener noreferrer">
          ${ctaLabel}
        </a>
        <p class="cta-note">
          ${disclaimer}
        </p>
        <p class="detail-description">${text(product.description, 'No description provided.')}</p>
      </aside>
    </section>
  `;
  bindGallery(root);
}

async function boot() {
  const id = Number(new URLSearchParams(window.location.search).get('id'));
  const root = document.getElementById('product-root');

  if (!Number.isFinite(id) || id <= 0) {
    root.innerHTML = '<div class="empty">Missing product id.</div>';
    return;
  }

  try {
    const [payload, sitePayload] = await Promise.all([fetchJson(`/api/product?id=${id}`), fetchJson('/api/site')]);
    renderProduct(payload, sitePayload);
  } catch (error) {
    root.innerHTML = `
      <div class="empty">
        Could not load this product.<br />
        ${text(error.message)}
      </div>
    `;
  }
}

boot();
