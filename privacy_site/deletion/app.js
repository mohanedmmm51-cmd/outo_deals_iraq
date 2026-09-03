'use strict';

const form = document.getElementById('deletion-form');
const submitButton = document.getElementById('submit');
const statusMessage = document.getElementById('status');

function showStatus(message, type) {
  statusMessage.textContent = message;
  statusMessage.className = type;
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  submitButton.disabled = true;
  showStatus('جاري التحقق وإرسال الطلب…', '');

  try {
    await firebase.auth().setPersistence(firebase.auth.Auth.Persistence.NONE);
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const credential = await firebase.auth().signInWithEmailAndPassword(
      email,
      password,
    );
    const user = credential.user;
    if (!user) throw new Error('missing-user');

    await firebase.firestore().collection('deletion_requests').doc(user.uid).set({
      userUid: user.uid,
      email: user.email || '',
      status: 'pending',
      source: 'web',
      requestedAt: firebase.firestore.FieldValue.serverTimestamp(),
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    await firebase.auth().signOut();
    form.reset();
    showStatus(
      'تم استلام طلبك. ستتم مراجعته وتنفيذه خلال 30 يوماً.',
      'success',
    );
  } catch (_) {
    try { await firebase.auth().signOut(); } catch (_) {}
    showStatus(
      'تعذر إرسال الطلب. تأكد من البريد وكلمة المرور والاتصال ثم حاول مرة ثانية.',
      'error',
    );
  } finally {
    submitButton.disabled = false;
  }
});
