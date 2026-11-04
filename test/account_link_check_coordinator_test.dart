import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/account_link_check_coordinator.dart';
import 'package:mindful_you/features/auth/services/account_link_policy.dart';
import 'package:mindful_you/features/auth/services/account_link_preflight.dart';
import 'package:mindful_you/features/auth/services/auth_contracts.dart';

class LocalProofFake implements RecentLocalAccountProof {
  LocalProofFake(this.ok, {this.fail = false});

  final bool ok;
  final bool fail;

  @override
  Future<bool> verifyLocalUser(int id) async {
    if (fail) throw StateError('internal secret');
    return ok;
  }
}

class RemoteProofFake implements FreshRemoteAccountProof {
  RemoteProofFake(this.identity);

  final AuthIdentity? identity;

  @override
  Future<AuthIdentity?> authenticateAgain() async => identity;
}

class ConflictLookupFake implements AccountLinkConflictLookup {
  ConflictLookupFake({
    this.existing,
    this.existingState,
    this.other = false,
  });

  final String? existing;
  final String? existingState;
  final bool other;

  @override
  Future<LocalAccountLinkSnapshot?> linkForLocalUser(int id) async {
    if (existing == null) return null;

    return LocalAccountLinkSnapshot(
      firebaseUid: existing!,
      state: existingState ?? 'confirmado',
    );
  }

  @override
  Future<bool> uidBelongsToOtherUser(
    String uid,
    int id,
  ) async {
    return other;
  }
}

const verified = AuthIdentity(
  provider: AuthProviderKind.firebase,
  providerUserId: 'uid-verified',
  email: 'teste@example.com',
  emailVerified: true,
);

Future<AccountLinkCheckResult> check({
  int localId = 8,
  bool localOk = true,
  bool localThrows = false,
  AuthIdentity? remote = verified,
  String? existing,
  String? existingState,
  bool other = false,
}) {
  return AccountLinkCheckCoordinator(
    AccountLinkPreflight(
      localProof: LocalProofFake(
        localOk,
        fail: localThrows,
      ),
      remoteProof: RemoteProofFake(remote),
      conflicts: ConflictLookupFake(
        existing: existing,
        existingState: existingState,
        other: other,
      ),
    ),
  ).verify(localId);
}

void main() {
  test('exige ID local válido', () async {
    final result = await check(localId: 0);

    expect(
      result.decision,
      AccountLinkDecision.localAuthenticationRequired,
    );
    expect(result.canRequestServerVerification, false);
  });

  test('bloqueia senha local incorreta', () async {
    final result = await check(localOk: false);

    expect(
      result.decision,
      AccountLinkDecision.localAuthenticationRequired,
    );
    expect(result.canRequestServerVerification, false);
  });

  test('bloqueia ausência de autenticação remota', () async {
    final result = await check(remote: null);

    expect(
      result.decision,
      AccountLinkDecision.remoteAuthenticationRequired,
    );
    expect(result.canRequestServerVerification, false);
  });

  test('bloqueia e-mail não confirmado', () async {
    const unverified = AuthIdentity(
      provider: AuthProviderKind.firebase,
      providerUserId: 'uid-verified',
      email: 'teste@example.com',
      emailVerified: false,
    );

    final result = await check(remote: unverified);

    expect(
      result.decision,
      AccountLinkDecision.verifiedEmailRequired,
    );
    expect(result.canRequestServerVerification, false);
  });

  test('bloqueia UID usado por outra conta', () async {
    final result = await check(other: true);

    expect(
      result.decision,
      AccountLinkDecision.remoteIdentityAlreadyLinked,
    );
    expect(result.canRequestServerVerification, false);
  });

  test('bloqueia troca de UID já vinculado', () async {
    final result = await check(
      existing: 'uid-diferente',
    );

    expect(
      result.decision,
      AccountLinkDecision.conflictingRemoteIdentity,
    );
    expect(result.canRequestServerVerification, false);
  });

  test('bloqueia vínculo pendente', () async {
    final result = await check(
      existing: 'uid-verified',
      existingState: 'pendente',
    );

    expect(
      result.decision,
      AccountLinkDecision.pendingLinkRequiresReview,
    );
    expect(result.canRequestServerVerification, false);
  });

  test('bloqueia vínculo revogado', () async {
    final result = await check(
      existing: 'uid-verified',
      existingState: 'revogado',
    );

    expect(
      result.decision,
      AccountLinkDecision.revokedLinkRequiresReview,
    );
    expect(result.canRequestServerVerification, false);
  });

  test('bloqueia estado de vínculo desconhecido', () async {
    final result = await check(
      existing: 'uid-verified',
      existingState: 'estado_invalido',
    );

    expect(
      result.decision,
      AccountLinkDecision.conflictingRemoteIdentity,
    );
    expect(result.canRequestServerVerification, false);
  });

  test('aprovação é somente pré-verificação', () async {
    final result = await check();

    expect(
      result.decision,
      AccountLinkDecision.eligibleForServerVerification,
    );
    expect(result.canRequestServerVerification, true);
    expect(result.message, contains('servidor'));
  });

  test('falha inesperada não expõe detalhes internos', () async {
    final result = await check(localThrows: true);

    expect(result.failedUnexpectedly, true);
    expect(result.canRequestServerVerification, false);
    expect(result.message, isNot(contains('internal secret')));
  });
}
