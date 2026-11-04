import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/account_link_policy.dart';
import 'package:mindful_you/features/auth/services/auth_contracts.dart';

void main() {
  const policy = AccountLinkPolicy();
  const verified = AuthIdentity(
    provider: AuthProviderKind.firebase,
    providerUserId: 'firebase-uid-1',
    email: 'teste@example.com',
    emailVerified: true,
  );

  test('não permite vínculo sem autenticação local', () {
    expect(
        policy.evaluate(
            authenticatedLocalUserId: null,
            remoteIdentity: verified,
            alreadyLinkedUidForLocalUser: null,
            remoteUidLinkedToAnotherLocalUser: false),
        AccountLinkDecision.localAuthenticationRequired);
  });

  test('não permite vínculo sem identidade Firebase', () {
    expect(
        policy.evaluate(
            authenticatedLocalUserId: 1,
            remoteIdentity: null,
            alreadyLinkedUidForLocalUser: null,
            remoteUidLinkedToAnotherLocalUser: false),
        AccountLinkDecision.remoteAuthenticationRequired);
  });

  test('exige email verificado no Firebase', () {
    const unverified = AuthIdentity(
        provider: AuthProviderKind.firebase,
        providerUserId: 'uid',
        email: 'teste@example.com',
        emailVerified: false);
    expect(
        policy.evaluate(
            authenticatedLocalUserId: 1,
            remoteIdentity: unverified,
            alreadyLinkedUidForLocalUser: null,
            remoteUidLinkedToAnotherLocalUser: false),
        AccountLinkDecision.verifiedEmailRequired);
  });

  test('bloqueia UID vinculado a outro usuário local', () {
    expect(
        policy.evaluate(
            authenticatedLocalUserId: 1,
            remoteIdentity: verified,
            alreadyLinkedUidForLocalUser: null,
            remoteUidLinkedToAnotherLocalUser: true),
        AccountLinkDecision.remoteIdentityAlreadyLinked);
  });

  test('bloqueia troca silenciosa do UID já associado', () {
    expect(
        policy.evaluate(
            authenticatedLocalUserId: 1,
            remoteIdentity: verified,
            alreadyLinkedUidForLocalUser: 'outro-uid',
            remoteUidLinkedToAnotherLocalUser: false),
        AccountLinkDecision.conflictingRemoteIdentity);
  });

  test('aprovação preliminar não efetua vínculo', () {
    expect(
        policy.evaluate(
            authenticatedLocalUserId: 1,
            remoteIdentity: verified,
            alreadyLinkedUidForLocalUser: null,
            remoteUidLinkedToAnotherLocalUser: false),
        AccountLinkDecision.eligibleForServerVerification);
  });
}
