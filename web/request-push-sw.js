self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('push', event => {
  let data = {};
  try { data = event.data?.json() || {}; } catch (_) {}
  event.waitUntil(self.registration.showNotification(data.title || 'إشعار طلب', {
    body: data.body || 'افتح التطبيق لمتابعة طلباتك',
    icon: '/icons/Icon-192.png', tag: data.tag || 'auto-deals-request',
    data: { url: data.url || '/' },
  }));
});
self.addEventListener('notificationclick', event => {
  event.notification.close();
  const target = new URL(event.notification.data?.url || '/', self.location.origin);
  if (target.origin !== self.location.origin) return;
  event.waitUntil(clients.openWindow(target.href));
});
