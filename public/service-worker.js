// public/service-worker.js
// ======================= Fasty SW (safe & minimal) =======================
// 目的：
// - 認証（Devise/OmniAuth）には一切介入しない
// - URL 文字列連結は行わず、Request をそのまま中継
// - HTML: online-first（失敗時 offline.html）
// - 静的資産: cache-first + backfill
// - SW が壊れてもサイト全体が壊れない安全設計

const CACHE_VERSION = "v10";               // ← 変更時は上げる
const CACHE_NAME    = `fasty-${CACHE_VERSION}`;
const OFFLINE_URL   = "/offline.html";

// 最低限のプリキャッシュ
const PRECACHE = [OFFLINE_URL, "/"];

// -- install --------------------------------------------------------------
self.addEventListener("install", (event) => {
  event.waitUntil((async () => {
    try {
      const cache = await caches.open(CACHE_NAME);
      await cache.addAll(PRECACHE);
    } catch (_) { /* noop */ }
  })());
  // すぐ有効化
  self.skipWaiting();
});

// -- activate -------------------------------------------------------------
self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    // Navigation Preload（対応ブラウザのみ）
    if ("navigationPreload" in self.registration) {
      try { await self.registration.navigationPreload.enable(); } catch (_) {}
    }
    // 古いキャッシュ削除
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)));
  })());
  self.clients.claim();
});

// -- optional: 外から更新指示（dev用） -----------------------------------
self.addEventListener("message", (event) => {
  if (!event.data) return;
  if (event.data === "SKIP_WAITING") self.skipWaiting();
});

// ============================ Fetch Strategy =============================
// 重要：非GET/認証系は必ず素通し。Request/URL を書き換えない。
self.addEventListener("fetch", (event) => {
  const req = event.request;

  // 1) 非GETは素通し（POST/PUT/DELETE/PATCH/HEADなど）
  if (req.method !== "GET") return;

  const url = new URL(req.url);

  // 2) 認証・セッション・コールバック等は素通し（GETでも触らない）
  //    必要に応じて追加してください。
  const bypassPrefixes = [
    "/users/auth/",                       // /users/auth/google_oauth2(.*)
    "/users/sign_in",
    "/users/sign_out",
    "/users/password",
    "/users/confirmation",
    "/users/unlock",
    "/rails/active_storage/",            // ActiveStorage 経路
  ];
  if (
    url.origin === location.origin &&
    bypassPrefixes.some(p => url.pathname.startsWith(p))
  ) {
    return; // Service Worker 介入なし
  }

  // 3) HTMLナビゲーション判定
  const isHTMLNavigation =
    req.mode === "navigate" ||
    req.destination === "document" ||
    (req.headers.get("accept") || "").includes("text/html");

  if (isHTMLNavigation) {
    // HTML: online-first → 失敗時 offline
    event.respondWith((async () => {
      try {
        // navigation preload があれば最優先
        const preload = await event.preloadResponse;
        if (preload) return preload;

        // Request をそのまま中継（URL連結など一切しない）
        const fresh = await fetch(req);
        return fresh;
      } catch (_) {
        const offline = await caches.match(OFFLINE_URL);
        return (
          offline ||
          new Response("offline", {
            status: 503,
            headers: { "Content-Type": "text/plain" },
          })
        );
      }
    })());
    return;
  }

  // 4) 非HTML（CSS/JS/画像/フォント…）: cache-first + backfill
  event.respondWith((async () => {
    const cached = await caches.match(req);
    if (cached) return cached;

    try {
      const resp = await fetch(req);
      // 同一オリジン & 正常応答のみキャッシュに保存
      if (url.origin === location.origin && resp.ok) {
        const cache = await caches.open(CACHE_NAME);
        cache.put(req, resp.clone());
      }
      return resp;
    } catch (_) {
      if (cached) return cached;
      return new Response("offline", {
        status: 503,
        headers: { "Content-Type": "text/plain" },
      });
    }
  })());
});
// ========================================================================
