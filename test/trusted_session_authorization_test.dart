import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/trusted_session_authorization.dart';

void main() {
  const authorization = DenyByDefaultSessionAuthorization();

  test('nega autorizacao enquanto backend nao estiver integrado', () async {
    final result = await authorization.verify(
      localUserId: 1,
      firebaseUid: 'uid-teste',
    );

    expect(
      result.status,
      TrustedAuthorizationStatus.linkNotAuthorized,
    );

    expect(result.isAuthorized, isFalse);
  });

  test('nao autoriza UID vazio', () async {
    final result = await authorization.verify(
      localUserId: 1,
      firebaseUid: '',
    );

    expect(result.isAuthorized, isFalse);
  });

  test('nao autoriza ID local invalido', () async {
    final result = await authorization.verify(
      localUserId: 0,
      firebaseUid: 'uid-teste',
    );

    expect(result.isAuthorized, isFalse);
  });

  test('status de indisponibilidade nao concede acesso', () {
    const result = TrustedAuthorizationResult(
      status: TrustedAuthorizationStatus.unavailable,
    );

    expect(result.isAuthorized, isFalse);
  });

  test('status de autenticacao obrigatoria nao concede acesso', () {
    const result = TrustedAuthorizationResult(
      status: TrustedAuthorizationStatus.authenticationRequired,
    );

    expect(result.isAuthorized, isFalse);
  });
}
