import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/account_link_policy.dart';
import 'package:mindful_you/features/auth/services/auth_contracts.dart';

void main() {
  const policy = AccountLinkPolicy();

  const identity = AuthIdentity(
    provider: AuthProviderKind.firebase,
    providerUserId: 'firebase-uid-123',
    email: 'teste@example.com',
    emailVerified: true,
  );

  AccountLinkDecision evaluate({
    String? state,
    String? linkedUid,
    bool uidLinkedElsewhere = false,
  }) {
    return policy.evaluate(
      authenticatedLocalUserId: 1,
      remoteIdentity: identity,
      alreadyLinkedUidForLocalUser: linkedUid,
      remoteUidLinkedToAnotherLocalUser: uidLinkedElsewhere,
      existingLinkState: state,
    );
  }

  group('Seguranca de vinculos Firebase', () {
    test('sem vinculo pode solicitar verificacao no servidor', () {
      expect(
        evaluate(),
        AccountLinkDecision.eligibleForServerVerification,
      );
    });

    test('vinculo pendente exige revisao', () {
      expect(
        evaluate(
          state: 'pendente',
          linkedUid: 'firebase-uid-123',
        ),
        AccountLinkDecision.pendingLinkRequiresReview,
      );
    });

    test('vinculo revogado bloqueia reutilizacao do mesmo UID', () {
      expect(
        evaluate(
          state: 'revogado',
          linkedUid: 'firebase-uid-123',
        ),
        AccountLinkDecision.revokedLinkRequiresReview,
      );
    });

    test('vinculo revogado bloqueia outro UID', () {
      expect(
        evaluate(
          state: 'revogado',
          linkedUid: 'outro-uid',
        ),
        AccountLinkDecision.revokedLinkRequiresReview,
      );
    });

    test('vinculo confirmado com outro UID gera conflito', () {
      expect(
        evaluate(
          state: 'confirmado',
          linkedUid: 'outro-uid',
        ),
        AccountLinkDecision.conflictingRemoteIdentity,
      );
    });

    test('UID associado a outra conta gera conflito', () {
      expect(
        evaluate(uidLinkedElsewhere: true),
        AccountLinkDecision.remoteIdentityAlreadyLinked,
      );
    });

    test('estado desconhecido bloqueia preventivamente', () {
      expect(
        evaluate(
          state: 'desconhecido',
          linkedUid: 'firebase-uid-123',
        ),
        AccountLinkDecision.conflictingRemoteIdentity,
      );
    });

    test('vinculo confirmado com mesmo UID passa na pre-verificacao', () {
      expect(
        evaluate(
          state: 'confirmado',
          linkedUid: 'firebase-uid-123',
        ),
        AccountLinkDecision.eligibleForServerVerification,
      );
    });
  });
}
