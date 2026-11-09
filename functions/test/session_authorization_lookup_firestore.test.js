
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const PROJECT_ID = 'mindful-tcc';
const FIRESTORE_HOST = '127.0.0.1:8080';

if (
    process.env.FIRESTORE_EMULATOR_HOST &&
    process.env.FIRESTORE_EMULATOR_HOST !== FIRESTORE_HOST
) {
    throw new Error('Firestore Emulator diferente do esperado.');
}

process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_HOST;
process.env.GCLOUD_PROJECT = PROJECT_ID;

const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

const {
    inspectSessionAuthorization,
} = require('../session_authorization_lookup');

const app = initializeApp(
    { projectId: PROJECT_ID },
    'authorization-lookup-firestore-test'
);

const db = getFirestore(app);

test(
    'consulta interna no Firestore Emulator',
    { timeout: 30000 },
    async (t) => {
        // Confirma que o Emulator está disponível.
        const response = await fetch(
            `http://${FIRESTORE_HOST}/`,
            { signal: AbortSignal.timeout(5000) }
        );

        assert.ok(response.status < 500);

        const uid = `teste-lookup-${crypto.randomUUID()}`;
        const ref = db.collection('autorizacoes_sessao').doc(uid);

        const now = Date.now();

        const base = {
            estado: 'confirmado',
            versao: 1,
            migracaoId: 'migracao-teste',
            revogadoEm: null,
            expiraEm: Timestamp.fromMillis(now + 60000),
        };

        try {
            await t.test('documento inexistente', async () => {
                const result = await inspectSessionAuthorization({
                    db,
                    authenticatedUid: uid,
                    now,
                });

                assert.equal(result.eligible, false);
            });

            await t.test('documento pendente', async () => {
                await ref.set({
                    ...base,
                    estado: 'pendente',
                });

                const result = await inspectSessionAuthorization({
                    db,
                    authenticatedUid: uid,
                    now,
                });

                assert.equal(result.eligible, false);
            });

            await t.test('documento revogado', async () => {
                await ref.set({
                    ...base,
                    estado: 'revogado',
                    revogadoEm: Timestamp.now(),
                });

                const result = await inspectSessionAuthorization({
                    db,
                    authenticatedUid: uid,
                    now,
                });

                assert.equal(result.eligible, false);
            });

            await t.test('documento expirado', async () => {
                await ref.set({
                    ...base,
                    expiraEm: Timestamp.fromMillis(now - 1000),
                });

                const result = await inspectSessionAuthorization({
                    db,
                    authenticatedUid: uid,
                    now,
                });

                assert.equal(result.eligible, false);
            });

            await t.test('documento estruturalmente valido', async () => {
                await ref.set(base);

                const result = await inspectSessionAuthorization({
                    db,
                    authenticatedUid: uid,
                    now,
                });

                assert.equal(result.eligible, true);
            });
        } finally {
            await ref.delete();
            await deleteApp(app);
        }
    }
);
