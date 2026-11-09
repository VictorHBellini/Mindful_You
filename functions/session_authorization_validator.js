
'use strict';

/**
 * Valida um registro de autorização de sessão híbrida.
 *
 * Este módulo não acessa o Firestore, não cria vínculos,
 * não autentica usuários e não concede acesso por si só.
 *
 * Somente o backend deverá fornecer registros obtidos
 * de uma fonte confiável.
 */

const AUTHORIZATION_VERSION = 1;

const AuthorizationDecision = Object.freeze({
    AUTHORIZED: 'authorized',
    DENIED: 'denied',
});

function validateSessionAuthorization({
    authenticatedUid,
    documentUid,
    record,
    now,
} = {}) {
    const denied = Object.freeze({
        decision: AuthorizationDecision.DENIED,
        authorized: false,
    });

    // Exige identificadores válidos e iguais.
    if (
        typeof authenticatedUid !== 'string' ||
        authenticatedUid.trim() === '' ||
        typeof documentUid !== 'string' ||
        documentUid.trim() === '' ||
        authenticatedUid !== documentUid
    ) {
        return denied;
    }

    // O registro deve existir e ser um objeto simples.
    if (
        record === null ||
        typeof record !== 'object' ||
        Array.isArray(record)
    ) {
        return denied;
    }

    // Somente registros confirmados são elegíveis.
    if (record.estado !== 'confirmado') {
        return denied;
    }

    // Verifica a versão do contrato.
    if (record.versao !== AUTHORIZATION_VERSION) {
        return denied;
    }

    // Exige referência de migração não vazia.
    if (
        typeof record.migracaoId !== 'string' ||
        record.migracaoId.trim() === ''
    ) {
        return denied;
    }

    // Rejeita revogação registrada, inclusive se
    // o estado estiver incorretamente como confirmado.
    if (
        record.revogadoEm !== null &&
        record.revogadoEm !== undefined
    ) {
        return denied;
    }

    // A validade deve ser informada em milissegundos Unix.
    if (
        typeof record.expiraEm !== 'number' ||
        !Number.isSafeInteger(record.expiraEm) ||
        record.expiraEm <= 0
    ) {
        return denied;
    }

    // A referência temporal deverá vir do backend.
    if (
        typeof now !== 'number' ||
        !Number.isSafeInteger(now) ||
        now <= 0
    ) {
        return denied;
    }

    // Autorização vencida não concede acesso.
    if (record.expiraEm <= now) {
        return denied;
    }

    return {
        decision: AuthorizationDecision.AUTHORIZED,
        authorized: true,
    };
}

module.exports = {
    AUTHORIZATION_VERSION,
    AuthorizationDecision,
    validateSessionAuthorization,
};
