import { getSiteConfig } from './_config.js';

const GRAPHQL_URL = 'https://web-server.production.fruitsfamily.com/graphql';
const PRODUCTS_STALE_PREFIX = 'fruits:last_good:products:';
const PRODUCT_STALE_PREFIX = 'fruits:last_good:product:';
const SITE_STALE_KEY = 'fruits:last_good:site';

export const jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
  'cache-control': 'public, max-age=60, s-maxage=300',
};

export function jsonResponse(body, status = 200, headers = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...jsonHeaders,
      ...headers,
    },
  });
}

export function getKv(env) {
  return env?.CANNED_FRUITS_KV || null;
}

export async function readJsonKv(env, key) {
  const kv = getKv(env);
  if (!kv) return null;

  try {
    return await kv.get(key, 'json');
  } catch {
    return null;
  }
}

export async function writeJsonKv(env, key, value, options = {}) {
  const kv = getKv(env);
  if (!kv) return false;

  try {
    await kv.put(key, JSON.stringify(value), options);
    return true;
  } catch {
    return false;
  }
}

async function fruitsGraphql(query, variables = {}) {
  const response = await fetch(GRAPHQL_URL, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      accept: 'application/json',
    },
    body: JSON.stringify({ query, variables }),
  });

  const text = await response.text();
  let payload = {};

  try {
    payload = text ? JSON.parse(text) : {};
  } catch {
    payload = { message: text };
  }

  if (!response.ok || payload.errors?.length) {
    const message = payload.errors?.[0]?.message || payload.message || 'FruitsFamily GraphQL request failed.';
    throw new Error(message);
  }

  return payload.data || {};
}

const SELLER_QUERY = `
  query SeeUser($id: Int!) {
    seeUser(id: $id) {
      id
      username
      nickname
      bio
      resizedBigImage
      resizedBigCoverImage
      follower_count
      following_count
      seller {
        id
        rating
        review_count
        productCount
        is_certified
      }
    }
  }
`;

const PRODUCTS_QUERY = `
  query SeeSellerProducts($filter: ProductFilter!, $offset: Int, $limit: Int, $sort: String) {
    searchProducts(filter: $filter, offset: $offset, limit: $limit, sort: $sort, origin: "SELLER") {
      id
      title
      brand
      status
      external_url
      resizedSmallImages
      view_count
      createdAt
      category
      price
      original_price
      is_visible
      size
      condition
      discount_rate
      like_count
      is_liked
    }
  }
`;

const PRODUCT_QUERY = `
  query SeeProductResponse($productId: Int!) {
    seeProductResponse(id: $productId) {
      code
      message
      seeProduct {
        id
        createdAt
        category
        title
        brand
        price
        original_price
        status
        external_url
        resizedSmallImages
        resizedBigImages
        is_visible
        size
        condition
        discount_rate
        like_count
        is_liked
        description
        visible_type
        gender
        sub_category
        subcategory_id
        view_count
        seller {
          id
          rating
          review_count
          user {
            id
            username
            nickname
            bio
            resizedSmallImage
            resizedBigImage
            follower_count
          }
        }
      }
    }
  }
`;

export function toBase36Id(id) {
  return Number(id).toString(36);
}

export function slugifyTitle(title) {
  return encodeURIComponent(
    String(title || '')
      .trim()
      .replace(/\s+/g, '-')
      .replace(/[^\w가-힣ㄱ-ㅎㅏ-ㅣ-]/g, '')
      .toLowerCase(),
  );
}

export function fruitsProductUrl(product) {
  const id = product?.id || product?.productId;
  return `https://fruitsfamily.com/product/${toBase36Id(id)}/${slugifyTitle(product?.title)}`;
}

function compactSeller(user, config) {
  const seller = user?.seller || {};
  return {
    id: Number(user?.id || config.seller.id),
    base36Id: toBase36Id(user?.id || config.seller.id),
    username: user?.username || config.seller.username,
    nickname: user?.nickname || config.site.name,
    bio: user?.bio || '',
    profileImage: user?.resizedBigImage || '',
    coverImage: user?.resizedBigCoverImage || '',
    followerCount: Number(user?.follower_count || 0),
    followingCount: Number(user?.following_count || 0),
    rating: Number(seller?.rating || 0),
    reviewCount: Number(seller?.review_count || 0),
    productCount: Number(seller?.productCount || 0),
    isCertified: Boolean(seller?.is_certified),
    canonicalUrl: config.seller.canonicalUrl,
  };
}

export function compactProduct(product) {
  const images = Array.isArray(product?.resizedSmallImages) ? product.resizedSmallImages : [];
  const bigImages = Array.isArray(product?.resizedBigImages) ? product.resizedBigImages : [];
  const compact = {
    id: Number(product?.id || 0),
    base36Id: toBase36Id(product?.id || 0),
    title: product?.title || 'Untitled product',
    brand: product?.brand || 'No Brand',
    status: product?.status || 'unknown',
    category: product?.category || '',
    subCategory: product?.sub_category || '',
    price: Number(product?.price || 0),
    originalPrice: product?.original_price == null ? null : Number(product.original_price),
    discountRate: product?.discount_rate == null ? null : Number(product.discount_rate),
    size: product?.size || '',
    condition: product?.condition || '',
    description: product?.description || '',
    images,
    bigImages,
    image: images[0] || bigImages[0] || '',
    likeCount: Number(product?.like_count || 0),
    viewCount: Number(product?.view_count || 0),
    createdAt: product?.createdAt || '',
    isVisible: product?.is_visible !== false,
    externalUrl: product?.external_url || '',
  };

  compact.fruitsUrl = compact.externalUrl || fruitsProductUrl(compact);
  return compact;
}

export async function fetchSellerProfile(env) {
  const config = getSiteConfig(env);
  const data = await fruitsGraphql(SELLER_QUERY, { id: Number(config.seller.id) });
  const seller = compactSeller(data.seeUser, config);
  const payload = {
    config,
    seller,
    fetchedAt: new Date().toISOString(),
  };

  await writeJsonKv(env, SITE_STALE_KEY, payload, { expirationTtl: 60 * 60 * 24 * 14 });
  return payload;
}

export async function fetchSellerProducts(env) {
  const config = getSiteConfig(env);
  const pageSize = Number(config.products.pageSize || 40);
  const maxPages = Number(config.products.maxPages || 5);
  const items = [];
  const seen = new Set();

  for (let page = 0; page < maxPages; page += 1) {
    const offset = page * pageSize;
    const data = await fruitsGraphql(PRODUCTS_QUERY, {
      filter: {
        query: '',
        sellerId: Number(config.seller.id),
      },
      offset,
      limit: pageSize,
      sort: config.products.sort || 'NEW',
    });

    const pageItems = Array.isArray(data.searchProducts) ? data.searchProducts : [];

    for (const raw of pageItems) {
      const product = compactProduct(raw);
      if (!product.id || seen.has(product.id)) continue;
      if (!config.products.showSold && product.status === 'sold') continue;
      seen.add(product.id);
      items.push(product);
    }

    if (pageItems.length < pageSize) break;
  }

  const payload = {
    items,
    count: items.length,
    sellerId: Number(config.seller.id),
    fetchedAt: new Date().toISOString(),
    source: 'fruitsfamily',
  };

  await writeJsonKv(env, `${PRODUCTS_STALE_PREFIX}${config.seller.id}`, payload, {
    expirationTtl: 60 * 60 * 24 * 14,
  });

  return payload;
}

export async function fetchProductDetail(env, productId) {
  const data = await fruitsGraphql(PRODUCT_QUERY, { productId: Number(productId) });
  const response = data.seeProductResponse;

  if (!response || response.code !== 200 || !response.seeProduct) {
    throw new Error(response?.message || 'Product not found.');
  }

  const product = compactProduct(response.seeProduct);
  const payload = {
    product,
    fetchedAt: new Date().toISOString(),
    source: 'fruitsfamily',
  };

  await writeJsonKv(env, `${PRODUCT_STALE_PREFIX}${product.id}`, payload, {
    expirationTtl: 60 * 60 * 24 * 14,
  });

  return payload;
}

export async function readProductsFallback(env) {
  const config = getSiteConfig(env);
  return readJsonKv(env, `${PRODUCTS_STALE_PREFIX}${config.seller.id}`);
}

export async function readProductFallback(env, productId) {
  return readJsonKv(env, `${PRODUCT_STALE_PREFIX}${productId}`);
}

export async function readSiteFallback(env) {
  return readJsonKv(env, SITE_STALE_KEY);
}

