import 'account_link_policy.dart';
import 'account_link_preflight.dart';

/// Resultado de uma tentativa isolada de pré-verificação.
/// Nunca autoriza leitura de histórico, sincronização ou vínculo persistente.
class AccountLinkCheckResult {
  const AccountLinkCheckResult._(this.decision, this.failedUnexpectedly);

  final AccountLinkDecision? decision;
  final bool failedUnexpectedly;

  bool get canRequestServerVerification =>
      !failedUnexpectedly &&
      decision == AccountLinkDecision.eligibleForServerVerification;

  String get message {
    if (failedUnexpectedly) {
      return 'Não foi possível concluir a verificação. Tente novamente.';
    }
    switch (decision!) {
      case AccountLinkDecision.localAuthenticationRequired:
        return 'Confirme novamente a senha da conta local.';
      case AccountLinkDecision.remoteAuthenticationRequired:
        return 'Entre novamente na conta Firebase para continuar.';
      case AccountLinkDecision.verifiedEmailRequired:
        return 'Confirme o e-mail da conta Firebase antes de continuar.';
      case AccountLinkDecision.conflictingRemoteIdentity:
        return 'Esta conta local já possui outra identidade Firebase associada.';
      case AccountLinkDecision.remoteIdentityAlreadyLinked:
        return 'Esta identidade Firebase já está associada a outra conta local.';
      case AccountLinkDecision.eligibleForServerVerification:
        return 'Pré-verificação concluída. Ainda falta autorização no servidor.';
      case AccountLinkDecision.pendingLinkRequiresReview:
        return 'Esta conta já possui uma solicitação de vínculo pendente.';
      case AccountLinkDecision.revokedLinkRequiresReview:
        return 'Existe um vínculo Firebase revogado. '
            'Uma nova associação exige verificação específica.';
    }
  }
}

/// Coordena somente as provas já implementadas. Sem gravações e sem UI.
class AccountLinkCheckCoordinator {
  const AccountLinkCheckCoordinator(this.preflight);

  final AccountLinkPreflight preflight;

  Future<AccountLinkCheckResult> verify(int localUserId) async {
    try {
      final decision = await preflight.check(localUserId);
      return AccountLinkCheckResult._(decision, false);
    } catch (_) {
      // Não mostrar exceções de banco/Firebase ou dados sensíveis na interface.
      return const AccountLinkCheckResult._(null, true);
    }
  }
}
