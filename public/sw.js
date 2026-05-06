// EcoSentinel Service Worker
// Cache-first strategy for static assets, network-first for API calls

const CACHE_VERSION = 'ecosentinel-v1.0.0';
const STATIC_CACHE = `static-${CACHE_VERSION}`;
const RUNTIME_CACHE = `runtime-${CACHE_VERSION}`;

// Files to cache on install (the app shell)
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/js/config.js',
  '/js/supabase-client.js',
];

// Install: pre-cache static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then((cache) => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
      .catch((err) => console.warn('[SW] Install cache failed:', err))
  );
});

// Activate: clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys
          .filter((key) => key !== STATIC_CACHE && key !== RUNTIME_CACHE)
          .map((key) => caches.delete(key))
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch: smart caching strategy
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests (POST/PUT/DELETE go straight to network)
  if (request.method !== 'GET') return;

  // Skip Supabase API calls (always need fresh data)
  if (url.hostname.includes('supabase')) return;

  // Skip Chrome extension requests
  if (url.protocol === 'chrome-extension:') return;

  // Strategy: cache-first for static assets
  if (
    request.destination === 'style' ||
    request.destination === 'script' ||
    request.destination === 'image' ||
    request.destination === 'font' ||
    url.pathname.endsWith('.svg') ||
    url.pathname.endsWith('.png') ||
    url.pathname.endsWith('.json')
  ) {
    event.respondWith(cacheFirst(request));
    return;
  }

  // Strategy: network-first for HTML and other resources
  event.respondWith(networkFirst(request));
});

// Cache-first: try cache, fall back to network, cache the result
async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) return cached;

  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(RUNTIME_CACHE);
      cache.put(request, response.clone()).catch(() => {});
    }
    return response;
  } catch (err) {
    // Offline + not cached: graceful degradation
    return new Response('離線狀態,此資源無法載入', {
      status: 503,
      statusText: 'Offline',
    });
  }
}

// Network-first: try network, fall back to cache
async function networkFirst(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(RUNTIME_CACHE);
      cache.put(request, response.clone()).catch(() => {});
    }
    return response;
  } catch (err) {
    // Network failed, try cache
    const cached = await caches.match(request);
    if (cached) return cached;

    // For navigation requests, return cached index.html as fallback
    if (request.mode === 'navigate') {
      const indexCached = await caches.match('/index.html');
      if (indexCached) return indexCached;
    }

    return new Response('離線狀態 · 請檢查網路連線', {
      status: 503,
      statusText: 'Offline',
      headers: { 'Content-Type': 'text/plain; charset=utf-8' },
    });
  }
}
