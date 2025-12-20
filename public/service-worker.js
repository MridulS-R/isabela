const VERSION = 'v1';
const CORE = [
  '/',
  '/home',
  '/offline',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('core-' + VERSION).then((cache) => cache.addAll(CORE)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => !k.endsWith(VERSION)).map((k) => caches.delete(k)))).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  event.respondWith(
    fetch(req).catch(() => caches.match(req).then((res) => res || caches.match('/offline')))
  );
});

