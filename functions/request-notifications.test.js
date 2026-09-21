const { test } = require('node:test');
const assert = require('node:assert/strict');
const { adminRecipients, replyChanged, validPushEndpoint } = require('./request-notifications');

test('administrators matching both role conventions receive only one notification', () => {
  assert.deepEqual(adminRecipients([{ id: 'owner' }], [{ id: 'owner' }, { id: 'admin2' }]), ['owner', 'admin2']);
  assert.deepEqual(adminRecipients([], []), []);
});
test('customer is notified only for a new or changed answer', () => {
  const answered = { status: 'answered', reply: 'متوفر', price: 100000 };
  assert.equal(replyChanged({ status: 'pending' }, answered), true);
  assert.equal(replyChanged(answered, { ...answered, updatedAt: 123 }), false);
  assert.equal(replyChanged(answered, { ...answered, price: 110000 }), true);
  assert.equal(replyChanged(answered, { ...answered, reply: 'غير متوفر', price: null }), true);
  assert.equal(replyChanged(answered, { status: 'pending' }), false);
});

test('web push sends only to browser push services', () => {
  assert.equal(validPushEndpoint('https://web.push.apple.com/Qtest'), true);
  assert.equal(validPushEndpoint('https://fcm.googleapis.com/fcm/send/test'), true);
  for (const url of ['http://fcm.googleapis.com/test', 'https://127.0.0.1/', 'https://fcm.googleapis.com.evil.example/', 'https://user@web.push.apple.com/test', 'https://web.push.apple.com:444/test']) {
    assert.equal(validPushEndpoint(url), false);
  }
});
