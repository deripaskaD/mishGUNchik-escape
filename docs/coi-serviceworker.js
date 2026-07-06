/* coi-serviceworker: включает crossOriginIsolated без COOP/COEP заголовков хостинга (GitHub Pages). */
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
        if (!window.isSecureContext || !('serviceWorker' in navigator)) return;
        const n = parseInt(sessionStorage.getItem('coi-reloads') || '0');
        if (n > 2) { console.error('coi: reload loop guard'); return; }
        const src = document.currentScript.src;
        navigator.serviceWorker.register(src).then(function (reg) {
            const doReload = function () {
                sessionStorage.setItem('coi-reloads', String(n + 1));
                window.location.reload();
            };
            if (reg.active && !navigator.serviceWorker.controller) { doReload(); return; }
            if (navigator.serviceWorker.controller && !window.crossOriginIsolated) { doReload(); return; }
            const w = reg.installing || reg.waiting;
            if (w) w.addEventListener('statechange', function () {
                if (this.state === 'activated' && !navigator.serviceWorker.controller) doReload();
            });
        }, function (err) { console.error('coi-sw register failed', err); });
    })();
}
