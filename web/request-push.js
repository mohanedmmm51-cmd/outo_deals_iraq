async function requestPushRegistration() {
  const registration = await navigator.serviceWorker.register('/request-push-sw.js', { scope: '/request-push/' });
  if (!registration.active) {
    const worker = registration.installing || registration.waiting;
    await new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Worker activation timed out')), 15000);
      const check = () => {
        if (worker?.state === 'activated') { clearTimeout(timer); resolve(); }
        if (worker?.state === 'redundant') { clearTimeout(timer); reject(new Error('Worker failed')); }
      };
      worker?.addEventListener('statechange', check); check();
    });
  }
  return registration;
}
async function subscriptionInfo(subscription) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(subscription.endpoint));
  return { id: Array.from(new Uint8Array(digest)).map(x => x.toString(16).padStart(2, '0')).join(''), subscription: subscription.toJSON() };
}
window.autoDealsPushEnable = async function () {
  if (!('Notification' in window) || !('PushManager' in window) || !navigator.serviceWorker) throw new Error('Unsupported');
  // The permission prompt must remain in the original user gesture on iOS.
  if (Notification.permission !== 'granted' && await Notification.requestPermission() !== 'granted') throw new Error('Permission denied');
  const registration = await requestPushRegistration();
  let subscription = await registration.pushManager.getSubscription();
  {
    const response = await fetch('https://auto-deals-push.mohanedmmm51.chatgpt.site/api/push');
    if (!response.ok) throw new Error('Push configuration unavailable');
    const { publicKey } = await response.json();
    const decoded = atob(publicKey.replace(/-/g, '+').replace(/_/g, '/'));
    const key = Uint8Array.from(decoded, c => c.charCodeAt(0));
    const oldKey = subscription?.options.applicationServerKey;
    if (subscription && (!oldKey || Array.from(new Uint8Array(oldKey)).join(',') !== Array.from(key).join(','))) { await subscription.unsubscribe(); subscription = null; }
    if (!subscription) subscription = await registration.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: key });
  }
  return JSON.stringify(await subscriptionInfo(subscription));
};
window.autoDealsPushCurrent = async function () {
  const registration = await navigator.serviceWorker?.getRegistration('/request-push/');
  const subscription = await registration?.pushManager.getSubscription();
  return JSON.stringify(subscription ? await subscriptionInfo(subscription) : null);
};
window.autoDealsPushDisable = async function () {
  const registration = await navigator.serviceWorker?.getRegistration('/request-push/');
  const subscription = await registration?.pushManager.getSubscription();
  if (subscription) await subscription.unsubscribe();
  return '';
};
