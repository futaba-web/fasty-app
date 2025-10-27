// public/service-worker.js
const CACHE_VERSION = 'v7';                 // 更新時は番号を上げる
const CACHE_NAME = `fasty-${CACHE_VERSION}`;
const OFFLINE_URL = '/offline.html';

// インストール時に最低限をプリキャッシュ
const PRECACHE = [OFFLINE_URL, '/'];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    await cache.addAll(PRECACHE);
  })());
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)));
  })());
  self.clients.claim();
});

// HTMLはネット優先→失敗時 offline.html、その他は cache-first
self.addEventListener('fetch', (event) => {
  const req = event.request;

  const isNavigation =
    req.mode === 'navigate' ||
    (req.method === 'GET' && req.headers.get('accept')?.includes('text/html')) ||
    req.destination === 'document';

  if (isNavigation) {
    event.respondWith((async () => {
      try {
        const preload = await event.preloadResponse;
        if (preload) return preload;
        return await fetch(req);
      } catch (_e) {
        const offline = await caches.match(OFFLINE_URL);
        return offline || new Response('offline', { status: 503, headers: { 'Content-Type': 'text/plain' } });
      }
    })());
    return;
  }

  event.respondWith((async () => {
    const cached = await caches.match(req);
    if (cached) return cached;
    try {
      const resp = await fetch(req);
      const clone = resp.clone();
      const cache = await caches.open(CACHE_NAME);
      cache.put(req, clone);
      return resp;
    } catch (_e) {
      return cached;
    }
  })());
});
