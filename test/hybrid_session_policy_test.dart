import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/hybrid_session_policy.dart';

void main() {
  const policy = HybridSessionPolicy();

  HybridSessionDecision avaliar({
    int? localUserId = 1,
    String? firebaseUid = 'uid-correto',
    String? linkedFirebaseUid = 'uid-correto',
    String? linkState = 'confirmado',
    bool trustedAuthorizationValid = true,
  }) {
    return policy.evaluate(
      localUserId: localUserId,
      firebaseUid: firebaseUid,
      linkedFirebaseUid: linkedFirebaseUid,
      linkState: linkState,
      trustedAuthorizationValid: trustedAuthorizationValid,
    );
  }

  test('bloqueia ausência de sessão local', () {
    expect(
      avaliar(localUserId: null),
      HybridSessionDecision.localSessionRequired,
    );
  });

  test('bloqueia ID local inválido', () {
    expect(
      avaliar(localUserId: 0),
      HybridSessionDecision.localSessionRequired,
    );
  });

  test('bloqueia ausência de identidade Firebase', () {
    expect(
      avaliar(firebaseUid: null),
      HybridSessionDecision.firebaseIdentityRequired,
    );
  });

  test('bloqueia UID Firebase vazio', () {
    expect(
      avaliar(firebaseUid: ''),
      HybridSessionDecision.firebaseIdentityRequired,
    );
  });

  test('bloqueia vínculo pendente', () {
    expect(
      avaliar(linkState: 'pendente'),
      HybridSessionDecision.linkNotConfirmed,
    );
  });

  test('bloqueia vínculo revogado', () {
    expect(
      avaliar(linkState: 'revogado'),
      HybridSessionDecision.linkNotConfirmed,
    );
  });

  test('bloqueia vínculo inexistente', () {
    expect(
      avaliar(linkState: null),
      HybridSessionDecision.linkNotConfirmed,
    );
  });

  test('bloqueia UID diferente', () {
    expect(
      avaliar(linkedFirebaseUid: 'outro-uid'),
      HybridSessionDecision.identityMismatch,
    );
  });

  test('bloqueia UID associado ausente', () {
    expect(
      avaliar(linkedFirebaseUid: null),
      HybridSessionDecision.identityMismatch,
    );
  });

  test('bloqueia ausência de autorização confiável', () {
    expect(
      avaliar(trustedAuthorizationValid: false),
      HybridSessionDecision.authorizationRequired,
    );
  });

  test('permite somente quando todas as condições são válidas', () {
    expect(
      avaliar(),
      HybridSessionDecision.authorized,
    );
  });
}
