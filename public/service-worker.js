// public/service-worker.js
// ======================= Fasty SW (safe auth bypass) =======================
const CACHE_VERSION = 'v8';                         // ← 変更時は上げる
const CACHE_NAME    = `fasty-${CACHE_VERSION}`;
const OFFLINE_URL   = '/offline.html';

// 最低限のプリキャッシュ
const PRECACHE = [OFFLINE_URL, '/'];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    try {
      const cache = await caches.open(CACHE_NAME);
      await cache.addAll(PRECACHE);
    } catch (_) {}
  })());
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    // Navigation Preload を有効化（対応ブラウザのみ）
    if ('navigationPreload' in self.registration) {
      try { await self.registration.navigationPreload.enable(); } catch (_) {}
    }
    // 古いキャッシュを一掃
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)));
  })());
  self.clients.claim();
});

// ============================ Fetch Strategy =============================
// 重要：OmniAuth / Devise など認証周りと非GETは *絶対に介入しない*。
self.addEventListener('fetch', (event) => {
  const req = event.request;

  // 1) 非GETは素通し（POST/PUT/DELETEなど）
  if (req.method !== 'GET') return;

  const url = new URL(req.url);

  // 2) 認証・セッション系パスは素通し（GETでも触らない）
  //    ここを必要に応じて追加/調整
  const bypassPrefixes = [
    '/users/auth/',        // /users/auth/google_oauth2 など
    '/users/sign_in',
    '/users/sign_out',
    '/users/password',
    '/users/confirmation',
    '/users/unlock'
  ];
  if (url.origin === location.origin &&
      bypassPrefixes.some(p => url.pathname.startsWith(p))) {
    return; // Service Worker 介入なし
  }

  // 3) 以降は通常のキャッシュ戦略
  const isHTMLNavigation =
    req.mode === 'navigate' ||
    req.destination === 'document' ||
    (req.headers.get('accept') || '').includes('text/html');

  if (isHTMLNavigation) {
    // HTMLはネット優先 → 失敗時 offline.html
    event.respondWith((async () => {
      try {
        // navigation preload があればそれを先に使う
        const preload = await event.preloadResponse;
        if (preload) return preload;

        const fresh = await fetch(req, { credentials: 'same-origin' });
        return fresh;
      } catch (_) {
        const offline = await caches.match(OFFLINE_URL);
        return offline || new Response('offline', { status: 503, headers: { 'Content-Type': 'text/plain' } });
      }
    })());
    return;
  }

  // HTML以外（CSS/JS/画像/フォント等）は cache-first + backfill
  event.respondWith((async () => {
    const cached = await caches.match(req);
    if (cached) return cached;

    try {
      const resp = await fetch(req, { credentials: 'same-origin' });

      // 同一オリジン & 正常応答のみキャッシュ（opaque等は無理に保存しない）
      if (url.origin === location.origin && resp.ok) {
        const clone = resp.clone();
        const cache = await caches.open(CACHE_NAME);
        cache.put(req, clone);
      }
      return resp;
    } catch (_) {
      // ネットもダメなら、手元のキャッシュがあればそれを返す
      if (cached) return cached;
      // 最後の砦：プレーンなエラー
      return new Response('offline', { status: 503, headers: { 'Content-Type': 'text/plain' } });
    }
  })());
});
// ========================================================================
