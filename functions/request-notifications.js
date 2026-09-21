// Pure routing helpers are kept separate so notification privacy can be tested.
function adminRecipients(roleDocs, flagDocs) {
  return [...new Set([...roleDocs, ...flagDocs].map(doc => doc.id))];
}

function replyChanged(before, after) {
  return after?.status === 'answered' && typeof after.reply === 'string' &&
    (before?.status !== 'answered' || before.reply !== after.reply || before.price !== after.price);
}

module.exports = { adminRecipients, replyChanged };
