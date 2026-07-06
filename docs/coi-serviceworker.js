/* coi-serviceworker: включает crossOriginIsolated на хостингах без COOP/COEP заголовков (GitHub Pages).
   Схема известного приёма coi-serviceworker (MIT). Регистрирует SW, добавляет заголовки, перезагружает раз. */
if (typeof window === 'undefined') {
    self.addEventListener('install', () => self.skipWaiting());
    self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
    self.addEventListener('fetch', function (e) {
        if (e.request.cache === 'only-if-cached' && e.request.mode !== 'same-origin') return;
        e.respondWith(fetch(e.request).then(function (res) {
            if (res.status === 0) return res;
            const h = new Headers(res.headers);
            h.set('Cross-Origin-Embedder-Policy', 'require-corp');
            h.set('Cross-Origin-Opener-Policy', 'same-origin');
            h.set('Cross-Origin-Resource-Policy', 'cross-origin');
            return new Response(res.body, { status: res.status, statusText: res.statusText, headers: h });
        }).catch(console.error));
    });
} else {
    (function () {
        if (window.crossOriginIsolated) return;
        if (!window.isSecureContext) return;
        navigator.serviceWorker.register(window.document.currentScript.src).then(function (reg) {
            if (reg.active && !navigator.serviceWorker.controller) window.location.reload();
            reg.addEventListener('updatefound', function () {
                window.location.reload();
            });
        }, function (err) { console.error('coi-sw register failed', err); });
    })();
}
