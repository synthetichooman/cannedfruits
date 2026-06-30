import { createServer } from 'node:http';
import { execFile } from 'node:child_process';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import { onRequestGet as site } from '../functions/api/site.js';
import { onRequestGet as products } from '../functions/api/products.js';
import { onRequestGet as product } from '../functions/api/product.js';
import { onRequestGet as sitemap } from '../functions/sitemap.xml.js';

const execFileAsync = promisify(execFile);

const root = fileURLToPath(new URL('../public/', import.meta.url));
const projectRoot = fileURLToPath(new URL('../', import.meta.url));
const siteConfigPath = join(projectRoot, 'site.config.json');
const functionConfigPath = join(projectRoot, 'functions/_config.js');
const contentRoot = join(projectRoot, 'content');
const publicIndexPath = join(projectRoot, 'public/index.html');
const publicProductPath = join(projectRoot, 'public/product.html');
const readmePath = join(projectRoot, 'README.md');
const llmConnectionPath = join(projectRoot, 'harness/LLM_CONNECTION.md');
const llmPromptPath = join(projectRoot, 'harness/LLM_PROMPT.md');
const port = Number(process.env.PORT || 8788);
const GRAPHQL_URL = 'https://web-server.production.fruitsfamily.com/graphql';

const types = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.gif': 'image/gif',
};

function json(res, body, status = 200) {
  res.statusCode = status;
  res.setHeader('content-type', 'application/json; charset=utf-8');
  res.end(JSON.stringify(body));
}

async function runGit(args) {
  const result = await execFileAsync('git', args, {
    cwd: projectRoot,
    timeout: 5000,
  });
  return result.stdout.trim();
}

async function getProjectStatus() {
  const status = {
    gitAvailable: false,
    isGitRepository: false,
    branch: '',
    remote: '',
    changedFiles: 0,
  };

  try {
    await runGit(['--version']);
    status.gitAvailable = true;
  } catch {
    return status;
  }

  try {
    status.isGitRepository = (await runGit(['rev-parse', '--is-inside-work-tree'])) === 'true';
  } catch {
    return status;
  }

  if (!status.isGitRepository) return status;

  try {
    status.branch = await runGit(['branch', '--show-current']);
  } catch {
    status.branch = '';
  }

  try {
    status.remote = await runGit(['remote', 'get-url', 'origin']);
  } catch {
    status.remote = '';
  }

  try {
    const output = await runGit(['status', '--short']);
    status.changedFiles = output ? output.split('\n').filter(Boolean).length : 0;
  } catch {
    status.changedFiles = 0;
  }

  return status;
}

function readRequestBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

async function readRequestJson(req) {
  const body = await readRequestBody(req);
  return body ? JSON.parse(body) : {};
}

async function loadLocalConfig() {
  const config = JSON.parse(await readFile(siteConfigPath, 'utf8'));
  globalThis.__CANNED_FRUITS_SITE_CONFIG__ = config;
  return config;
}

function toBase36Id(id) {
  return Number(id).toString(36);
}

function configModuleSource(config) {
  return `export const SITE_CONFIG = ${JSON.stringify(config, null, 2)};\n\nexport function getSiteConfig(env = {}) {\n  const runtimeConfig = globalThis.__CANNED_FRUITS_SITE_CONFIG__ || SITE_CONFIG;\n  const domain = env.SITE_DOMAIN || runtimeConfig.site.domain;\n  return {\n    ...runtimeConfig,\n    site: {\n      ...runtimeConfig.site,\n      domain,\n    },\n  };\n}\n`;
}

function escapeHtml(value = '') {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

async function updateStaticFallbackHtml(config) {
  const name = escapeHtml(config.site?.name || 'cannedfruits');
  const description = escapeHtml(config.site?.description || `${config.site?.name || 'cannedfruits'} storefront.`);
  const indexHtml = await readFile(publicIndexPath, 'utf8');
  const nextIndexHtml = indexHtml
    .replace(/<title>.*?<\/title>/, `<title>${name}</title>`)
    .replace(/<meta name="description" content=".*?" \/>/, `<meta name="description" content="${description}" />`)
    .replace(
      /<a class="brand" href="\/">[\s\S]*?<\/a>/,
      `<a class="brand" href="/">\n          <img class="brand-logo" id="site-logo" alt="" hidden />\n          <span id="site-brand">${name}</span>\n        </a>`,
    );

  const productHtml = await readFile(publicProductPath, 'utf8');
  const nextProductHtml = productHtml
    .replace(/<title>.*?<\/title>/, `<title>Product | ${name}</title>`)
    .replace(/<meta name="description" content=".*?" \/>/, `<meta name="description" content="${name} product detail." />`)
    .replace(
      /<a class="brand" href="\/">[\s\S]*?<\/a>/,
      `<a class="brand" href="/">\n          <img class="brand-logo" id="site-logo" alt="" hidden />\n          <span id="site-brand">${name}</span>\n        </a>`,
    );

  await writeFile(publicIndexPath, nextIndexHtml);
  await writeFile(publicProductPath, nextProductHtml);
}

function imageExtension(mimeType = '') {
  const map = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
    'image/gif': 'gif',
  };
  return map[mimeType] || '';
}

async function saveDesignReferenceImage(designInput = {}, currentDesign = {}) {
  if (!designInput.referenceImageData) {
    return currentDesign.referenceImage || '';
  }

  const match = String(designInput.referenceImageData).match(/^data:(image\/[a-zA-Z0-9.+-]+);base64,(.+)$/);
  if (!match) throw new Error('디자인 레퍼런스 이미지를 읽지 못했습니다.');

  const extension = imageExtension(match[1]);
  if (!extension) throw new Error('png, jpg, webp, gif 이미지만 업로드할 수 있습니다.');

  const buffer = Buffer.from(match[2], 'base64');
  if (buffer.length > 8 * 1024 * 1024) {
    throw new Error('디자인 레퍼런스 이미지는 8MB 이하만 저장할 수 있습니다.');
  }

  await mkdir(contentRoot, { recursive: true });
  const relativePath = `content/design-reference.${extension}`;
  await writeFile(join(projectRoot, relativePath), buffer);
  return relativePath;
}

async function fruitsGraphql(query, variables = {}) {
  const response = await fetch(GRAPHQL_URL, {
    method: 'POST',
    headers: {
      accept: 'application/json',
      'content-type': 'application/json',
    },
    body: JSON.stringify({ query, variables }),
  });

  const payload = await response.json();
  if (!response.ok || payload.errors?.length) {
    throw new Error(payload.errors?.[0]?.message || 'FruitsFamily seller check failed.');
  }
  return payload.data || {};
}

function parseCanonicalSellerUrl(value) {
  const url = new URL(value);
  const match = url.pathname.match(/^\/seller\/([0-9a-z]+)\/([^/?#]+)/i);
  if (!match) return null;

  return {
    id: parseInt(match[1], 36),
    base36Id: match[1].toLowerCase(),
    username: decodeURIComponent(match[2]),
    canonicalUrl: `https://fruitsfamily.com/seller/${match[1].toLowerCase()}/${decodeURIComponent(match[2])}`,
  };
}

async function resolveSellerUrl(rawUrl) {
  if (!rawUrl) throw new Error('FruitsFamily 셀러 링크를 입력해주세요.');

  let sourceUrl = String(rawUrl).trim();
  if (!/^https?:\/\//i.test(sourceUrl)) sourceUrl = `https://${sourceUrl}`;

  let parsed = parseCanonicalSellerUrl(sourceUrl);

  if (!parsed) {
    const response = await fetch(sourceUrl, { redirect: 'follow' });
    parsed = parseCanonicalSellerUrl(response.url);
  }

  if (!parsed?.id) {
    throw new Error('셀러 링크에서 숫자 seller id를 찾지 못했습니다. fruitsfamily.com/seller/... 형태의 링크를 입력해주세요.');
  }

  const query = `
    query SeeUser($id: Int!) {
      seeUser(id: $id) {
        id
        username
        nickname
        bio
        seller {
          productCount
        }
      }
    }
  `;
  const data = await fruitsGraphql(query, { id: parsed.id });
  const user = data.seeUser;

  if (!user?.id) {
    throw new Error('FruitsFamily에서 셀러 정보를 확인하지 못했습니다.');
  }

  const base36Id = toBase36Id(user.id);
  const username = user.username || parsed.username;

  return {
    id: Number(user.id),
    base36Id,
    username,
    nickname: user.nickname || username,
    bio: user.bio || '',
    productCount: Number(user.seller?.productCount || 0),
    canonicalUrl: `https://fruitsfamily.com/seller/${base36Id}/${username}`,
    sourceUrl,
  };
}

async function saveSetupConfig(req, res) {
  const current = await loadLocalConfig();
  const input = await readRequestJson(req);
  const designReferenceImage = await saveDesignReferenceImage(input.design, current.design);
  const next = {
    ...current,
    site: {
      ...current.site,
      name: String(input.site?.name || current.site.name).trim(),
      domain: String(input.site?.domain || current.site.domain).trim(),
      description: String(input.site?.description || current.site.description).trim(),
      locale: current.site.locale || 'ko-KR',
      currency: current.site.currency || 'KRW',
    },
    seller: {
      ...current.seller,
      id: Number(input.seller?.id || current.seller.id),
      base36Id: String(input.seller?.base36Id || current.seller.base36Id).trim(),
      username: String(input.seller?.username || current.seller.username).trim(),
      canonicalUrl: String(input.seller?.canonicalUrl || current.seller.canonicalUrl).trim(),
      sourceUrl: String(input.seller?.sourceUrl || current.seller.sourceUrl).trim(),
    },
    products: {
      ...current.products,
      showSold: Boolean(input.products?.showSold),
    },
    cta: {
      ...current.cta,
      label: String(input.cta?.label || current.cta.label).trim(),
      soldLabel: String(input.cta?.soldLabel || current.cta.soldLabel).trim(),
      disclaimer: String(input.cta?.disclaimer || current.cta.disclaimer).trim(),
    },
    legal: {
      ...current.legal,
      disclaimer: String(
        input.legal?.disclaimer ||
          current.legal?.disclaimer ||
          'cannedfruits는 FruitsFamily와 관련이 없는 비공식 독립 도구입니다. 사용 과정에서 발생하는 계정, 운영, 정책상 불이익은 사용자에게 귀속됩니다.',
      ).trim(),
    },
    design: {
      ...current.design,
      referenceUrl: String(input.design?.referenceUrl || current.design?.referenceUrl || '').trim(),
      referenceImage: designReferenceImage,
      notes: String(input.design?.notes || current.design?.notes || '').trim(),
    },
    theme: {
      ...current.theme,
      accent: String(input.theme?.accent || current.theme.accent).trim(),
      background: String(input.theme?.background || current.theme.background).trim(),
      text: String(input.theme?.text || current.theme.text).trim(),
    },
  };

  if (!next.site.name || !next.seller.id || !next.seller.username) {
    return json(res, { error: '샵 이름과 셀러 정보는 필수입니다.' }, 400);
  }

  await writeFile(siteConfigPath, `${JSON.stringify(next, null, 2)}\n`);
  await writeFile(functionConfigPath, configModuleSource(next));
  await updateStaticFallbackHtml(next);
  globalThis.__CANNED_FRUITS_SITE_CONFIG__ = next;

  return json(res, { ok: true, config: next });
}

async function buildPreflight() {
  const env = {
    SITE_DOMAIN: `localhost:${port}`,
  };
  const checks = [];

  try {
    const config = await loadLocalConfig();
    checks.push({
      ok: Boolean(config.site?.name && config.seller?.id && config.seller?.username),
      label: '설정 파일',
      detail: `${config.site?.name || '이름 없음'} / seller id ${config.seller?.id || '없음'}`,
    });
  } catch (error) {
    checks.push({ ok: false, label: '설정 파일', detail: String(error.message || error) });
  }

  try {
    const response = await site({
      request: new Request(`http://localhost:${port}/api/site`),
      env,
    });
    const payload = await response.json();
    checks.push({
      ok: response.ok && Boolean(payload.seller?.nickname),
      label: '셀러 데이터',
      detail: payload.seller?.nickname || payload.error || '응답 없음',
    });
  } catch (error) {
    checks.push({ ok: false, label: '셀러 데이터', detail: String(error.message || error) });
  }

  try {
    const response = await products({
      request: new Request(`http://localhost:${port}/api/products`),
      env,
    });
    const payload = await response.json();
    checks.push({
      ok: response.ok && Number(payload.count || payload.items?.length || 0) > 0,
      label: '상품 데이터',
      detail: `${payload.count || payload.items?.length || 0}개 상품`,
    });
  } catch (error) {
    checks.push({ ok: false, label: '상품 데이터', detail: String(error.message || error) });
  }

  try {
    const response = await sitemap({
      request: new Request(`http://localhost:${port}/sitemap.xml`),
      env,
    });
    const body = await response.text();
    checks.push({
      ok: response.ok && body.includes('<urlset'),
      label: 'sitemap',
      detail: response.ok ? '생성 가능' : '생성 실패',
    });
  } catch (error) {
    checks.push({ ok: false, label: 'sitemap', detail: String(error.message || error) });
  }

  const git = await getProjectStatus();
  checks.push({
    ok: git.gitAvailable,
    label: 'Git 설치',
    detail: git.gitAvailable ? '사용 가능' : '설치 필요',
  });

  return {
    ok: checks.every((check) => check.ok),
    checks,
    git,
  };
}

async function runPreflight(res) {
  return json(res, await buildPreflight());
}

async function getMaintainStatus() {
  const env = {
    SITE_DOMAIN: `localhost:${port}`,
  };
  const config = await loadLocalConfig();
  const [siteResponse, productsResponse, preflight] = await Promise.all([
    site({
      request: new Request(`http://localhost:${port}/api/site`),
      env,
    }),
    products({
      request: new Request(`http://localhost:${port}/api/products`),
      env,
    }),
    buildPreflight(),
  ]);
  const sitePayload = await siteResponse.json();
  const productsPayload = await productsResponse.json();

  return {
    config,
    seller: sitePayload.seller || null,
    productCount: Number(productsPayload.count || productsPayload.items?.length || 0),
    firstProduct: productsPayload.items?.[0] || null,
    preflight,
    updatedAt: new Date().toISOString(),
    urls: {
      preview: `http://localhost:${port}/`,
    },
  };
}

function maintainPrompt(status = {}, kind = 'status') {
  const config = status.config || {};
  const seller = status.seller || {};
  const checks = status.preflight?.checks || [];
  const checkLines = checks.map((check) => `- ${check.label}: ${check.ok ? '통과' : '확인 필요'} (${check.detail})`).join('\n');
  const base = `이 폴더는 cannedfruits v0.1 프로젝트입니다.
모든 답변은 한국어로 해줘.
먼저 README.md, AGENTS.md, harness/LLM_PROMPT.md, harness/REFERENCE.md를 읽고 구조를 파악해줘.
수정 후에는 npm run check를 실행해줘.

현재 상태:
- 샵 이름: ${config.site?.name || '확인 필요'}
- 셀러: ${seller.nickname || config.seller?.username || '확인 필요'}
- 셀러 URL: ${config.seller?.canonicalUrl || '확인 필요'}
- 상품 수: ${status.productCount ?? '확인 필요'}
- 도메인 메모: ${config.site?.domain || '없음'}
- Sold 표시: ${config.products?.showSold ? '켜짐' : '꺼짐'}

점검 결과:
${checkLines || '- 아직 점검 결과 없음'}
`;

  const requests = {
    status: '위 상태를 보고 문제가 있어 보이는 부분과 다음에 할 일을 쉽게 설명해줘.',
    design:
      '기본 디자인을 더 좋게 다듬고 싶어. FruitsFamily 데이터 연결과 구매 CTA는 건드리지 말고, public/ 안의 화면과 스타일을 중심으로 개선해줘.',
    data: '상품 데이터 연결이 정상인지 점검하고, 문제가 있으면 원인과 수정 방법을 알려줘.',
    deploy:
      '이 프로젝트를 GitHub에 올리고 Cloudflare Pages에 연결하는 과정을 아주 쉽게 단계별로 도와줘. 도메인 연결은 Cloudflare Pages Custom domains 기준으로 설명해줘.',
  };

  return `${base}
요청:
${requests[kind] || requests.status}
`;
}

async function sendResponse(res, response) {
  res.statusCode = response.status;
  response.headers.forEach((value, key) => res.setHeader(key, value));
  res.end(Buffer.from(await response.arrayBuffer()));
}

async function serveFile(req, res, baseRoot, pathname) {
  const safePath = normalize(pathname).replace(/^(\.\.[/\\])+/, '');
  const filePath = join(baseRoot, safePath);
  const body = await readFile(filePath);
  res.statusCode = 200;
  res.setHeader('content-type', types[extname(filePath)] || 'application/octet-stream');
  res.setHeader('cache-control', 'no-store');
  res.end(body);
}

async function serveStatic(req, res) {
  const url = new URL(req.url, `http://localhost:${port}`);
  const pathname = url.pathname === '/' ? '/index.html' : url.pathname;

  return serveFile(req, res, root, pathname);
}

await loadLocalConfig();

const server = createServer(async (req, res) => {
  try {
    const request = new Request(`http://localhost:${port}${req.url}`, {
      method: req.method,
      headers: req.headers,
    });
    const url = new URL(request.url);
    const context = {
      request,
      env: {
        SITE_DOMAIN: `localhost:${port}`,
      },
    };

    if (url.pathname === '/api/site') return sendResponse(res, await site(context));
    if (url.pathname === '/api/products') return sendResponse(res, await products(context));
    if (url.pathname === '/api/product') return sendResponse(res, await product(context));
    if (url.pathname === '/sitemap.xml') return sendResponse(res, await sitemap(context));

    if (url.pathname === '/api/setup/config' && req.method === 'GET') {
      return json(res, { config: await loadLocalConfig() });
    }

    if (url.pathname === '/api/setup/config' && req.method === 'POST') {
      return saveSetupConfig(req, res);
    }

    if (url.pathname === '/api/setup/resolve-seller' && req.method === 'POST') {
      const body = await readRequestJson(req);
      return json(res, { seller: await resolveSellerUrl(body.url) });
    }

    if (url.pathname === '/api/setup/preflight' && req.method === 'POST') {
      return runPreflight(res);
    }

    if (url.pathname === '/api/setup/project-status' && req.method === 'GET') {
      return json(res, await getProjectStatus());
    }

    if (url.pathname === '/api/maintain/status' && req.method === 'GET') {
      return json(res, await getMaintainStatus());
    }

    if (url.pathname === '/api/maintain/llm-summary' && req.method === 'GET') {
      const kind = url.searchParams.get('kind') || 'status';
      return json(res, { title: 'LLM 유지보수 요청', body: maintainPrompt(await getMaintainStatus(), kind) });
    }

    if (url.pathname === '/api/setup/readme' && req.method === 'GET') {
      return json(res, { title: 'cannedfruits v0.1 README', body: await readFile(readmePath, 'utf8') });
    }

    if (url.pathname === '/api/setup/llm-connection' && req.method === 'GET') {
      return json(res, { title: 'LLM 연결 방법', body: await readFile(llmConnectionPath, 'utf8') });
    }

    if (url.pathname === '/api/setup/llm-prompt' && req.method === 'GET') {
      return json(res, { title: 'LLM 시작 하네스', body: await readFile(llmPromptPath, 'utf8') });
    }

    if (url.pathname === '/api/setup/design-reference' && req.method === 'GET') {
      const config = await loadLocalConfig();
      const relativePath = config.design?.referenceImage;
      if (!relativePath) return json(res, { error: '디자인 레퍼런스 이미지가 없습니다.' }, 404);

      const filePath = join(projectRoot, relativePath);
      const body = await readFile(filePath);
      res.statusCode = 200;
      res.setHeader('content-type', types[extname(filePath)] || 'application/octet-stream');
      return res.end(body);
    }

    await serveStatic(req, res);
  } catch (error) {
    res.statusCode = error?.code === 'ENOENT' ? 404 : 500;
    const message = error?.code === 'ENOENT' ? 'Not found' : String(error.message || error);
    if (req.url?.startsWith('/api/')) {
      return json(res, { error: message }, res.statusCode);
    }
    res.setHeader('content-type', 'text/plain; charset=utf-8');
    res.end(message);
  }
});

server.listen(port, () => {
  console.log(`fruits mirror dev server: http://localhost:${port}`);
});
