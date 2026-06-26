// Service Worker mínimo — habilita instalación PWA + cache básico (network-first)
const CACHE = 'ij-cache-v1';

self.addEventListener('install', (e) => { self.skipWaiting(); });

self.addEventListener('activate', (e) => { e.waitUntil(self.clients.claim()); });

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return; // no cachear POST/PUT, etc.
  e.respondWith(
    fetch(req)
      .then((res) => {
        // guardar copia para uso offline (solo respuestas válidas del mismo origen)
        try {
          if (res && res.status === 200 && res.type === 'basic') {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
          }
        } catch (_) {}
        return res;
      })
      .catch(() => caches.match(req))
  );
});
