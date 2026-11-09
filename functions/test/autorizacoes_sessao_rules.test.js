
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const authEmulator = 'http://127.0.0.1:9099';
const firestoreEmulator = 'http://127.0.0.1:8080';
const projectId = 'mindful-tcc';

async function criarUsuarioTeste() {
    const response = await fetch(
        `${authEmulator}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
        {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                returnSecureToken: true,
            }),
        },
    );

    assert.equal(response.status, 200);

    const body = await response.json();

    assert.ok(body.idToken);
    assert.ok(body.localId);

    return body;
}

function urlDocumento(uid) {
    return (
        `${firestoreEmulator}/v1/projects/${projectId}` +
        `/databases/(default)/documents/autorizacoes_sessao/${uid}`
    );
}

test('usuario autenticado nao pode ler autorizacao', async () => {
    const usuario = await criarUsuarioTeste();

    const response = await fetch(
        urlDocumento(usuario.localId),
        {
            method: 'GET',
            headers: {
                Authorization: `Bearer ${usuario.idToken}`,
            },
        },
    );

    assert.equal(response.status, 403);
});

test('usuario autenticado nao pode criar autorizacao', async () => {
    const usuario = await criarUsuarioTeste();

    const response = await fetch(
        urlDocumento(usuario.localId),
        {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${usuario.idToken}`,
            },
            body: JSON.stringify({
                fields: {
                    estado: {
                        stringValue: 'confirmado',
                    },
                    autorizado: {
                        booleanValue: true,
                    },
                },
            }),
        },
    );

    assert.equal(response.status, 403);
});

test('usuario sem autenticacao nao pode ler autorizacao', async () => {
    const response = await fetch(
        urlDocumento('usuario-sem-token'),
        {
            method: 'GET',
        },
    );

    assert.equal(response.status, 403);
});
