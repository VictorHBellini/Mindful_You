
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const endpoint =
    'http://127.0.0.1:5001/mindful-tcc/' +
    'southamerica-east1/verificarAutorizacaoSessao';

test('rejeita chamada sem autenticacao Firebase', async () => {
    const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            data: {},
        }),
    });

    const body = await response.json();

    assert.equal(response.status, 401);
    assert.equal(body.error.status, 'UNAUTHENTICATED');
});

test('nao concede autorizacao sem token Firebase', async () => {
    const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            data: {
                localUserId: 1,
                firebaseUid: 'uid-inventado',
            },
        }),
    });

    const body = await response.json();

    assert.equal(response.status, 401);
    assert.equal(body.error.status, 'UNAUTHENTICATED');
});


test('usuario Firebase autenticado continua sem autorizacao', async () => {
    const apiKey = 'fake-api-key';
    const authEmulator = 'http://127.0.0.1:9099';

    // Cria uma identidade apenas no Firebase Auth Emulator.
    const signUpResponse = await fetch(
        `${authEmulator}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`,
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

    assert.equal(signUpResponse.status, 200);

    const signUpBody = await signUpResponse.json();
    const idToken = signUpBody.idToken;

    assert.ok(idToken);

    // Chama a Cloud Function usando um token Firebase válido.
    const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify({
            data: {
                localUserId: 1,
                firebaseUid: signUpBody.localId,
            },
        }),
    });

    assert.equal(response.status, 200);

    const body = await response.json();

    assert.deepEqual(body.result, {
        status: 'linkNotAuthorized',
        authorized: false,
    });
});
