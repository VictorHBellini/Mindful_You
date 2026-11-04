import 'auth_contracts.dart';

/// Validação preliminar para um futuro vínculo SQLite <-> Firebase.
/// NÃO cria vínculos, não concede sessão local e não migra dados.
/// A implementação persistente deverá validar novamente os IDs e a
/// unicidade dentro de uma transação no banco de dados.
enum AccountLinkDecision {
  eligibleForServerVerification,
  localAuthenticationRequired,
  remoteAuthenticationRequired,
  verifiedEmailRequired,
  conflictingRemoteIdentity,
  remoteIdentityAlreadyLinked,
  pendingLinkRequiresReview,
  revokedLinkRequiresReview,
}

class AccountLinkPolicy {
  const AccountLinkPolicy();

  AccountLinkDecision evaluate({
    required int? authenticatedLocalUserId,
    required AuthIdentity? remoteIdentity,
    required String? alreadyLinkedUidForLocalUser,
    required bool remoteUidLinkedToAnotherLocalUser,
    String? existingLinkState,
  }) {
    if (authenticatedLocalUserId == null || authenticatedLocalUserId <= 0) {
      return AccountLinkDecision.localAuthenticationRequired;
    }

    if (remoteIdentity == null ||
        remoteIdentity.provider != AuthProviderKind.firebase ||
        remoteIdentity.providerUserId.trim().isEmpty) {
      return AccountLinkDecision.remoteAuthenticationRequired;
    }

    if (!remoteIdentity.emailVerified) {
      return AccountLinkDecision.verifiedEmailRequired;
    }

    // Vínculos revogados não podem ser reutilizados
    // pelo fluxo normal de pré-verificação.
    if (existingLinkState == 'revogado') {
      return AccountLinkDecision.revokedLinkRequiresReview;
    }

    // Uma solicitação pendente não deve gerar
    // outra associação automaticamente.
    if (existingLinkState == 'pendente') {
      return AccountLinkDecision.pendingLinkRequiresReview;
    }

    // Estado desconhecido: bloqueia preventivamente.
    if (existingLinkState != null && existingLinkState != 'confirmado') {
      return AccountLinkDecision.conflictingRemoteIdentity;
    }

    // Um UID não pode pertencer a outra conta local.
    if (remoteUidLinkedToAnotherLocalUser) {
      return AccountLinkDecision.remoteIdentityAlreadyLinked;
    }

    final existing = alreadyLinkedUidForLocalUser?.trim();

    if (existingLinkState == 'confirmado' &&
        (existing == null || existing.isEmpty)) {
      return AccountLinkDecision.conflictingRemoteIdentity;
    }

    if (existing != null &&
        existing.isNotEmpty &&
        existing != remoteIdentity.providerUserId) {
      return AccountLinkDecision.conflictingRemoteIdentity;
    }

    return AccountLinkDecision.eligibleForServerVerification;
  }
}
