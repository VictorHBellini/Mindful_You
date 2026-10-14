'use strict';
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
initializeApp();

// Important: A Firebase login alone cannot attest to an Android SQLite session.
// Therefore this callable NEVER creates a confirmed link or enables sync.
exports.solicitarVinculoDemo = onCall({region: 'southamerica-east1', enforceAppCheck: false}, async (request) => {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Entre na conta Firebase.');
  const {installationId} = request.data || {};
  if (typeof installationId !== 'string' || !/^[a-f0-9-]{36}$/.test(installationId)) {
    throw new HttpsError('invalid-argument', 'Identificador de instalação inválido.');
  }
  const uid = request.auth.uid;
  const db = getFirestore();
  const ref = db.collection('solicitacoes_vinculo_demo').doc(uid);
  return db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (doc.exists) {
      const old = doc.data();
      if (old.installationId !== installationId) {
        throw new HttpsError('already-exists', 'UID já possui solicitação em outra instalação.');
      }
      return {estado: 'pendente', uid, reutilizada: true};
    }
    tx.create(ref, {
      installationId,
      estado: 'pendente',
      criadoEm: FieldValue.serverTimestamp(),
      finalidade: 'demo_sem_autorizacao_de_sincronizacao'
    });
    return {estado: 'pendente', uid, reutilizada: false};
  });
});
