import 'account_link_policy.dart';
import 'auth_contracts.dart';

/// Prova local recente deve vir de uma nova validação da senha SQLite.
/// Não aceite apenas uma sessão persistida como prova de posse.
abstract class RecentLocalAccountProof {
  Future<bool> verifyLocalUser(int localUserId);
}

/// Identidade remota deve ser obtida de uma autenticação Firebase recente.
/// Não confie em e-mail digitado ou em um UID fornecido pela interface.
abstract class FreshRemoteAccountProof {
  Future<AuthIdentity?> authenticateAgain();
}

/// Representa um vínculo local entre SQLite e Firebase.
///
/// O UID e o estado devem ser consultados juntos para evitar
/// resultados inconsistentes entre consultas separadas.
class LocalAccountLinkSnapshot {
  const LocalAccountLinkSnapshot({
    required this.firebaseUid,
    required this.state,
  });

  final String firebaseUid;
  final String state;
}

/// Consulta os vínculos atuais sem modificar os dados locais.
abstract class AccountLinkConflictLookup {
  Future<LocalAccountLinkSnapshot?> linkForLocalUser(
    int localUserId,
  );

  Future<bool> uidBelongsToOtherUser(
    String uid,
    int localUserId,
  );
}

/// Apenas pré-verificação:
/// NÃO grava vínculos, NÃO cria sessões e NÃO autoriza sincronização.
///
/// O backend ainda deverá comprovar as identidades e
/// autorizar explicitamente qualquer associação.
class AccountLinkPreflight {
  const AccountLinkPreflight({
    required this.localProof,
    required this.remoteProof,
    required this.conflicts,
  });

  final RecentLocalAccountProof localProof;
  final FreshRemoteAccountProof remoteProof;
  final AccountLinkConflictLookup conflicts;

  Future<AccountLinkDecision> check(int localUserId) async {
    // 1. Validar o identificador local.
    if (localUserId <= 0) {
      return AccountLinkDecision.localAuthenticationRequired;
    }

    // 2. Exigir comprovação recente da senha SQLite.
    if (!await localProof.verifyLocalUser(localUserId)) {
      return AccountLinkDecision.localAuthenticationRequired;
    }

    // 3. Reautenticar a identidade Firebase.
    final identity = await remoteProof.authenticateAgain();

    if (identity == null ||
        identity.provider != AuthProviderKind.firebase ||
        identity.providerUserId.trim().isEmpty) {
      return AccountLinkDecision.remoteAuthenticationRequired;
    }

    // 4. Exigir e-mail Firebase verificado.
    if (!identity.emailVerified) {
      return AccountLinkDecision.verifiedEmailRequired;
    }

    // 5. Consultar UID e estado do vínculo na mesma leitura.
    final existing = await conflicts.linkForLocalUser(localUserId);

    // 6. Verificar se o UID já pertence a outra conta local.
    final other = await conflicts.uidBelongsToOtherUser(
      identity.providerUserId,
      localUserId,
    );

    // 7. Aplicar a política de segurança.
    return const AccountLinkPolicy().evaluate(
      authenticatedLocalUserId: localUserId,
      remoteIdentity: identity,
      alreadyLinkedUidForLocalUser: existing?.firebaseUid,
      remoteUidLinkedToAnotherLocalUser: other,
      existingLinkState: existing?.state,
    );
  }
}
