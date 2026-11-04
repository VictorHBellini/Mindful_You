import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/account_link_preflight.dart';
import 'package:mindful_you/features/auth/services/account_link_policy.dart';
import 'package:mindful_you/features/auth/services/auth_contracts.dart';

class LocalFake implements RecentLocalAccountProof {
  LocalFake(this.ok);

  final bool ok;

  @override
  Future<bool> verifyLocalUser(int id) async => ok;
}

class RemoteFake implements FreshRemoteAccountProof {
  RemoteFake(this.identity);

  final AuthIdentity? identity;

  @override
  Future<AuthIdentity?> authenticateAgain() async => identity;
}

class ConflictFake implements AccountLinkConflictLookup {
  ConflictFake({
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
  providerUserId: 'firebase-uid',
  email: 'teste@example.com',
  emailVerified: true,
);

Future<AccountLinkDecision> run({
  int id = 7,
  bool local = true,
  AuthIdentity? remote = verified,
  String? existing,
  String? existingState,
  bool other = false,
}) {
  return AccountLinkPreflight(
    localProof: LocalFake(local),
    remoteProof: RemoteFake(remote),
    conflicts: ConflictFake(
      existing: existing,
      existingState: existingState,
      other: other,
    ),
  ).check(id);
}

void main() {
  test('exige conta local válida', () async {
    expect(
      await run(id: 0),
      AccountLinkDecision.localAuthenticationRequired,
    );
  });

  test('exige nova comprovação local', () async {
    expect(
      await run(local: false),
      AccountLinkDecision.localAuthenticationRequired,
    );
  });

  test('exige autenticação Firebase', () async {
    expect(
      await run(remote: null),
      AccountLinkDecision.remoteAuthenticationRequired,
    );
  });

  test('exige email verificado', () async {
    const unverified = AuthIdentity(
      provider: AuthProviderKind.firebase,
      providerUserId: 'firebase-uid',
      email: 'teste@example.com',
      emailVerified: false,
    );

    expect(
      await run(remote: unverified),
      AccountLinkDecision.verifiedEmailRequired,
    );
  });

  test('rejeita UID de outra conta', () async {
    expect(
      await run(other: true),
      AccountLinkDecision.remoteIdentityAlreadyLinked,
    );
  });

  test('rejeita UID diferente já associado ao usuário', () async {
    expect(
      await run(existing: 'outro-uid'),
      AccountLinkDecision.conflictingRemoteIdentity,
    );
  });

  test('bloqueia vínculo pendente', () async {
    expect(
      await run(
        existing: 'firebase-uid',
        existingState: 'pendente',
      ),
      AccountLinkDecision.pendingLinkRequiresReview,
    );
  });

  test('bloqueia vínculo revogado', () async {
    expect(
      await run(
        existing: 'firebase-uid',
        existingState: 'revogado',
      ),
      AccountLinkDecision.revokedLinkRequiresReview,
    );
  });

  test('bloqueia estado de vínculo desconhecido', () async {
    expect(
      await run(
        existing: 'firebase-uid',
        existingState: 'estado_invalido',
      ),
      AccountLinkDecision.conflictingRemoteIdentity,
    );
  });

  test('vínculo confirmado com mesmo UID passa na pré-verificação', () async {
    expect(
      await run(
        existing: 'firebase-uid',
        existingState: 'confirmado',
      ),
      AccountLinkDecision.eligibleForServerVerification,
    );
  });

  test('permite somente seguir para verificação no servidor', () async {
    expect(
      await run(),
      AccountLinkDecision.eligibleForServerVerification,
    );
  });
}
