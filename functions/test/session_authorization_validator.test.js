
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
    validateSessionAuthorization,
} = require('../session_authorization_validator');

const NOW = 1800000000000;

function validRecord() {
    return {
        estado: 'confirmado',
        versao: 1,
        migracaoId: 'migracao-teste-123',
        expiraEm: NOW + 60000,
        revogadoEm: null,
    };
}

function validate(overrides = {}) {
    return validateSessionAuthorization({
        authenticatedUid: 'uid-correto',
        documentUid: 'uid-correto',
        record: validRecord(),
        now: NOW,
        ...overrides,
    });
}

void test('aceita registro estruturalmente valido', () => {
    const result = validate();

    assert.equal(result.authorized, true);
    assert.equal(result.decision, 'authorized');
});

test('rejeita UID autenticado diferente', () => {
    assert.equal(
        validate({ authenticatedUid: 'outro-uid' }).authorized,
        false
    );
});

test('rejeita UID do documento diferente', () => {
    assert.equal(
        validate({ documentUid: 'outro-uid' }).authorized,
        false
    );
});

test('rejeita registro ausente', () => {
    assert.equal(
        validate({ record: null }).authorized,
        false
    );
});

test('rejeita vinculo pendente', () => {
    assert.equal(
        validate({
            record: { ...validRecord(), estado: 'pendente' },
        }).authorized,
        false
    );
});

test('rejeita vinculo revogado', () => {
    assert.equal(
        validate({
            record: { ...validRecord(), estado: 'revogado' },
        }).authorized,
        false
    );
});

test('rejeita estado desconhecido', () => {
    assert.equal(
        validate({
            record: { ...validRecord(), estado: 'desconhecido' },
        }).authorized,
        false
    );
});

test('rejeita versao incompatível', () => {
    assert.equal(
        validate({
            record: { ...validRecord(), versao: 2 },
        }).authorized,
        false
    );
});

test('rejeita referencia de migracao ausente', () => {
    assert.equal(
        validate({
            record: { ...validRecord(), migracaoId: '' },
        }).authorized,
        false
    );
});

test('rejeita registro com revogacao informada', () => {
    assert.equal(
        validate({
            record: { ...validRecord(), revogadoEm: NOW - 1000 },
        }).authorized,
        false
    );
});

test('rejeita autorizacao expirada', () => {
    assert.equal(
        validate({
            record: { ...validRecord(), expiraEm: NOW - 1 },
        }).authorized,
        false
    );
});

test('rejeita autorizacao no instante da expiracao', () => {
    assert.equal(
        validate({
            record: { ...validRecord(), expiraEm: NOW },
        }).authorized,
        false
    );
});

test('rejeita data de expiracao invalida', () => {
    assert.equal(
        validate({
            record: { ...validRecord(), expiraEm: 'amanha' },
        }).authorized,
        false
    );
});

test('rejeita horario de referencia invalido', () => {
    assert.equal(
        validate({ now: NaN }).authorized,
        false
    );
});

test('rejeita UID vazio', () => {
    assert.equal(
        validate({ authenticatedUid: '' }).authorized,
        false
    );
});
