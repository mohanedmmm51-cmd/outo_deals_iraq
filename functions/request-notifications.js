// Pure routing helpers are kept separate so notification privacy can be tested.
function adminRecipients(roleDocs, flagDocs) {
  return [...new Set([...roleDocs, ...flagDocs].map(doc => doc.id))];
}

function replyChanged(before, after) {
  return after?.status === 'answered' && typeof after.reply === 'string' &&
    (before?.status !== 'answered' || before.reply !== after.reply || before.price !== after.price);
}

function validPushEndpoint(endpoint) {
  try {
    const url = new URL(endpoint);
    return url.protocol === 'https:' && !url.username && !url.password && !url.port &&
      ['fcm.googleapis.com', 'updates.push.services.mozilla.com', 'web.push.apple.com'].includes(url.hostname);
  } catch (_) { return false; }
}

module.exports = { adminRecipients, replyChanged, validPushEndpoint };
