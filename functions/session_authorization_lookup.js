
'use strict';

const {
    validateSessionAuthorization,
} = require('./session_authorization_validator');

/**
 * Consulta interna, exclusiva do backend.
 *
 * Retorna apenas um resultado interno de validação.
 * NÃO concede acesso, NÃO cria vínculos e NÃO autoriza sync.
 */
async function inspectSessionAuthorization({
    db,
    authenticatedUid,
    now = Date.now(),
} = {}) {
    const denied = Object.freeze({
        eligible: false,
    });

    if (
        !db ||
        typeof db.collection !== 'function' ||
        typeof authenticatedUid !== 'string' ||
        authenticatedUid.trim() === '' ||
        authenticatedUid.includes('/') ||
        !Number.isSafeInteger(now) ||
        now <= 0
    ) {
        return denied;
    }

    try {
        // O caminho depende exclusivamente do UID autenticado.
        const snapshot = await db
            .collection('autorizacoes_sessao')
            .doc(authenticatedUid)
            .get();

        if (!snapshot.exists || snapshot.id !== authenticatedUid) {
            return denied;
        }

        const record = snapshot.data();

        if (!record || typeof record !== 'object') {
            return denied;
        }

        // Firestore Timestamp deve ser convertido explicitamente.
        const expiresAt = record.expiraEm;

        if (
            !expiresAt ||
            typeof expiresAt.toMillis !== 'function'
        ) {
            return denied;
        }

        const normalizedRecord = {
            ...record,
            expiraEm: expiresAt.toMillis(),
        };

        const validation = validateSessionAuthorization({
            authenticatedUid,
            documentUid: snapshot.id,
            record: normalizedRecord,
            now,
        });

        return {
            eligible: validation.authorized === true,
        };
    } catch (_) {
        // Falhas de leitura ou conversão não concedem acesso.
        return denied;
    }
}

module.exports = {
    inspectSessionAuthorization,
};
