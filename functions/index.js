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


// Emulator-only: authenticated cancellation of an existing demo request.
// Never changes SQLite, grants a link, or enables synchronization.
exports.cancelarSolicitacaoVinculoDemo = onCall(
  {region: 'southamerica-east1', enforceAppCheck: false},
  async (request) => {
    if (process.env.FUNCTIONS_EMULATOR !== 'true') {
      throw new HttpsError('failed-precondition', 'Operação exclusiva do Emulator.');
    }
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Entre na conta Firebase.');
    const {installationId} = request.data || {};
    if (typeof installationId !== 'string' ||
        !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(installationId)) {
      throw new HttpsError('invalid-argument', 'Identificador inválido.');
    }
    const db = getFirestore();
    const ref = db.collection('solicitacoes_vinculo_demo').doc(uid);
    const audit = ref.collection('auditoria').doc();
    return db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) {
        throw new HttpsError('not-found', 'Solicitação não encontrada.');
      }
      const data = snapshot.data();
      if (data.installationId !== installationId) {
        throw new HttpsError('permission-denied', 'Instalação diferente.');
      }
      if (data.estado === 'cancelado') {
        return {estado: 'cancelado', alterado: false};
      }
      if (data.estado !== 'pendente' ||
          data.finalidade !== 'demo_sem_autorizacao_de_sincronizacao') {
        throw new HttpsError('failed-precondition', 'Estado não permite cancelamento.');
      }
      tx.update(ref, {estado: 'cancelado', canceladoEm: FieldValue.serverTimestamp()});
      tx.create(audit, {
        evento: 'cancelamento_solicitacao_demo',
        executadoPorUid: uid,
        ocorridoEm: FieldValue.serverTimestamp(),
        ambiente: 'firebase_emulator'
      });
      return {estado: 'cancelado', alterado: true};
    });
  }
);
