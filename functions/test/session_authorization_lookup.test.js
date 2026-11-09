
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
    inspectSessionAuthorization,
} = require('../session_authorization_lookup');

const NOW = 1800000000000;
const UID = 'uid-teste';

function makeDb({
    id = UID,
    exists = true,
    record,
    throwError = false,
} = {}) {
    const data = record === undefined
        ? {
            estado: 'confirmado',
            versao: 1,
            migracaoId: 'migracao-teste',
            revogadoEm: null,
            expiraEm: {
                toMillis: () => NOW + 60000,
            },
        }
        : record;

    return {
        collection(name) {
            assert.equal(name, 'autorizacoes_sessao');

            return {
                doc(uid) {
                    assert.equal(uid, UID);

                    return {
                        async get() {
                            if (throwError) {
                                throw new Error('falha interna simulada');
                            }

                            return {
                                id,
                                exists,
                                data: () => data,
                            };
                        },
                    };
                },
            };
        },
    };
}

async function inspect(options = {}) {
    return inspectSessionAuthorization({
        db: makeDb(),
        authenticatedUid: UID,
        now: NOW,
        ...options,
    });
}

test('reconhece registro estruturalmente valido', async () => {
    const result = await inspect();

    assert.equal(result.eligible, true);
});

test('nega UID vazio', async () => {
    const result = await inspect({
        authenticatedUid: '',
    });

    assert.equal(result.eligible, false);
});

test('nega UID com barra no caminho', async () => {
    const result = await inspect({
        authenticatedUid: 'outro/uid',
    });

    assert.equal(result.eligible, false);
});

test('nega documento inexistente', async () => {
    const result = await inspect({
        db: makeDb({ exists: false }),
    });

    assert.equal(result.eligible, false);
});

test('nega ID de documento diferente', async () => {
    const result = await inspect({
        db: makeDb({ id: 'outro-uid' }),
    });

    assert.equal(result.eligible, false);
});

test('nega vinculo revogado', async () => {
    const db = makeDb({
        record: {
            estado: 'revogado',
            versao: 1,
            migracaoId: 'migracao-teste',
            revogadoEm: null,
            expiraEm: { toMillis: () => NOW + 60000 },
        },
    });

    const result = await inspect({ db });

    assert.equal(result.eligible, false);
});

test('nega expiracao sem Timestamp valido', async () => {
    const db = makeDb({
        record: {
            estado: 'confirmado',
            versao: 1,
            migracaoId: 'migracao-teste',
            revogadoEm: null,
            expiraEm: NOW + 60000,
        },
    });

    const result = await inspect({ db });

    assert.equal(result.eligible, false);
});

test('nega falha na consulta Firestore', async () => {
    const result = await inspect({
        db: makeDb({ throwError: true }),
    });

    assert.equal(result.eligible, false);
});

test('nega referencia temporal invalida', async () => {
    const result = await inspect({ now: NaN });

    assert.equal(result.eligible, false);
});
