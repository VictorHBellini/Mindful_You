
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const PROJECT_ID = 'mindful-tcc';
const AUTH_HOST = '127.0.0.1:9099';
const FIRESTORE_HOST = '127.0.0.1:8080';

const FUNCTION_URL =
    `http://127.0.0.1:5001/${PROJECT_ID}` +
    '/southamerica-east1/verificarAutorizacaoSessao';

// Proteção: este teste nunca deve apontar para produção.
if (
    process.env.FIRESTORE_EMULATOR_HOST &&
    process.env.FIRESTORE_EMULATOR_HOST !== FIRESTORE_HOST
) {
    throw new Error('Firestore Emulator diferente do esperado.');
}

if (
    process.env.FIREBASE_AUTH_EMULATOR_HOST &&
    process.env.FIREBASE_AUTH_EMULATOR_HOST !== AUTH_HOST
) {
    throw new Error('Auth Emulator diferente do esperado.');
}

process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_HOST;
process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_HOST;
process.env.GCLOUD_PROJECT = PROJECT_ID;

const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

const app = initializeApp(
    { projectId: PROJECT_ID },
    'session-authorization-emulator-test'
);

const db = getFirestore(app);
const auth = getAuth(app);

async function verificarEmuladores() {
    const urls = [
        `http://${AUTH_HOST}/`,
        `http://${FIRESTORE_HOST}/`,
    ];

    for (const url of urls) {
        const response = await fetch(url, {
            signal: AbortSignal.timeout(5000),
        });

        assert.ok(
            response.status < 500,
            `Emulador indisponível: ${url}`
        );
    }
}

async function criarUsuario() {
    const response = await fetch(
        `http://${AUTH_HOST}` +
        '/identitytoolkit.googleapis.com/v1/' +
        'accounts:signUp?key=fake-api-key',
        {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                returnSecureToken: true,
            }),
        }
    );

    assert.equal(response.status, 200);

    const data = await response.json();

    assert.ok(data.localId);
    assert.ok(data.idToken);

    return {
        uid: data.localId,
        token: data.idToken,
    };
}

async function consultarFuncao(token) {
    const response = await fetch(FUNCTION_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
            data: {},
        }),
    });

    assert.equal(response.status, 200);

    const body = await response.json();

    assert.deepEqual(body.result, {
        status: 'linkNotAuthorized',
        authorized: false,
    });
}

function registro(estado, expiraEm) {
    return {
        estado,
        versao: 1,
        migracaoId: 'migracao-somente-teste',
        revogadoEm: null,
        expiraEm: Timestamp.fromMillis(expiraEm),
    };
}

test(
    'Firestore Emulator: autorizacao permanece negada',
    { timeout: 30000 },
    async (t) => {
        await verificarEmuladores();

        const usuario = await criarUsuario();

        const ref = db
            .collection('autorizacoes_sessao')
            .doc(usuario.uid);

        // Limpeza obrigatória, inclusive quando uma
        // das verificações falhar.
        try {
            await t.test('documento inexistente', async () => {
                const snapshot = await ref.get();

                assert.equal(snapshot.exists, false);

                await consultarFuncao(usuario.token);
            });

            const cenarios = [
                {
                    nome: 'documento pendente',
                    dados: registro(
                        'pendente',
                        Date.now() + 60000
                    ),
                },
                {
                    nome: 'documento revogado',
                    dados: {
                        ...registro(
                            'revogado',
                            Date.now() + 60000
                        ),
                        revogadoEm: Timestamp.now(),
                    },
                },
                {
                    nome: 'documento expirado',
                    dados: registro(
                        'confirmado',
                        Date.now() - 60000
                    ),
                },
                {
                    nome: 'documento confirmado e nao expirado',
                    dados: registro(
                        'confirmado',
                        Date.now() + 60000
                    ),
                },
            ];

            for (const cenario of cenarios) {
                await t.test(cenario.nome, async () => {
                    await ref.set(cenario.dados);

                    // Confirma que o documento realmente
                    // existe no Firestore Emulator.
                    const snapshot = await ref.get();

                    assert.equal(snapshot.exists, true);
                    assert.equal(
                        snapshot.data().estado,
                        cenario.dados.estado
                    );

                    // Mesmo assim, a função não libera acesso.
                    await consultarFuncao(usuario.token);
                });
            }
        } finally {
            await ref.delete();
            await auth.deleteUser(usuario.uid);
            await deleteApp(app);
        }
    }
);
