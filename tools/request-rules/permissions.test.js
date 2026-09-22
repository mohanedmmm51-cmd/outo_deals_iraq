import { readFileSync } from 'node:fs';
import { after, before, test } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, updateDoc, collection, query, where, serverTimestamp } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-auto-deals-requests', firestore: { rules: readFileSync('../../firestore.rules', 'utf8') } });
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/admin'), { role: 'admin' });
    await setDoc(doc(db, 'users/shop'), { role: 'shop', shopId: 'shop1' });
    await setDoc(doc(db, 'shops/shop1'), { ownerUid: 'shop', approved: true });
  });
});
after(async () => { await env?.cleanup(); });
const request = () => ({ customerUid: 'customer', type: 'tire', size: '205/55 R16', note: '', status: 'pending', createdAt: serverTimestamp(), updatedAt: serverTimestamp() });

test('customer can create and retrieve requests, but others and shops cannot read or answer', async () => {
  const customer = env.authenticatedContext('customer').firestore();
  const other = env.authenticatedContext('other').firestore();
  const shop = env.authenticatedContext('shop').firestore();
  const admin = env.authenticatedContext('admin').firestore();
  const path = 'product_requests/request1';
  await assertSucceeds(getDoc(doc(customer, path))); // Retry transaction preflight for missing ID.
  await assertSucceeds(setDoc(doc(customer, path), request()));
  await assertSucceeds(getDoc(doc(customer, path)));
  await assertSucceeds(getDocs(query(collection(customer, 'product_requests'), where('customerUid', '==', 'customer'))));
  await assertFails(getDocs(collection(customer, 'product_requests')));
  await assertFails(getDoc(doc(other, path)));
  await assertFails(getDoc(doc(shop, path)));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), path)));
  await assertSucceeds(getDocs(collection(admin, 'product_requests')));
  const answer = { reply: 'متوفر', price: 100000, status: 'answered', repliedBy: 'admin', repliedAt: serverTimestamp(), updatedAt: serverTimestamp() };
  await assertFails(updateDoc(doc(customer, path), answer));
  await assertFails(updateDoc(doc(shop, path), answer));
  await assertSucceeds(updateDoc(doc(admin, path), answer));
  await assertFails(updateDoc(doc(admin, path), { ...answer, customerUid: 'other' }));
  await assertSucceeds(updateDoc(doc(admin, path), { ...answer, reply: 'غير متوفر', price: null }));
});

test('forged requests and notification registrations are rejected', async () => {
  const customer = env.authenticatedContext('customer').firestore();
  await assertFails(setDoc(doc(customer, 'product_requests/forged'), { ...request(), customerUid: 'admin' }));
  await assertFails(setDoc(doc(customer, 'product_requests/forged'), { ...request(), reply: 'fake' }));
  await assertFails(setDoc(doc(customer, 'product_requests/forged'), { ...request(), status: 'answered' }));
  await assertFails(setDoc(doc(customer, 'product_requests/forged'), { ...request(), type: 'invalid' }));
  await assertSucceeds(setDoc(doc(customer, 'push_devices/customer/tokens/device1'), { token: 'test-token', updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(customer, 'push_devices/admin/tokens/device1'), { token: 'test-token', updatedAt: serverTimestamp() }));
  await assertFails(getDocs(collection(customer, 'push_devices/admin/tokens')));
});


test('web subscriptions stay private and secrets cannot be read even by admin', async () => {
  const customer = env.authenticatedContext('customer').firestore();
  const subscription = { endpoint: 'https://web.push.apple.com/test', keys: { auth: 'auth', p256dh: 'key' }, expirationTime: null };
  await assertSucceeds(setDoc(doc(customer, 'push_devices/customer/tokens/web'), { subscription, updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(customer, 'push_devices/customer/tokens/forged'), { subscription: { ...subscription, endpoint: 'https://127.0.0.1/' }, updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(env.authenticatedContext('admin').firestore(), 'request_push_secrets/vapid')));
});

test('relay can check current admin authorization without reading profiles or writing probe documents', async () => {
 const customer = env.authenticatedContext('customer').firestore();
 const admin = env.authenticatedContext('admin').firestore();
 await assertSucceeds(getDoc(doc(customer, 'push_admin_checks/admin')));
 await assertFails(getDoc(doc(customer, 'push_admin_checks/shop')));
 await assertFails(getDoc(doc(customer, 'users/admin')));
 await assertFails(getDocs(collection(customer, 'push_admin_checks')));
 await assertFails(setDoc(doc(admin, 'push_admin_checks/admin'), {admin:true}));
 await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'push_admin_checks/admin')));
 await env.withSecurityRulesDisabled(async c => {await setDoc(doc(c.firestore(), 'users/revoked'), {role:'admin'});});
 await assertSucceeds(getDoc(doc(customer, 'push_admin_checks/revoked')));
 await env.withSecurityRulesDisabled(async c => {await setDoc(doc(c.firestore(), 'users/revoked'), {role:'customer'});});
 await assertFails(getDoc(doc(customer, 'push_admin_checks/revoked')));
});
