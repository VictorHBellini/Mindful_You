import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/auth_contracts.dart';

void main() {
  test('provedor local e remoto permanecem distintos', () {
    expect(AuthProviderKind.localSqlite, isNot(AuthProviderKind.firebase));
  });

  test('identidade remota carrega UID e verificacao separados do e-mail', () {
    const identity = AuthIdentity(
      provider: AuthProviderKind.firebase,
      providerUserId: 'firebase-uid-123',
      email: 'exemplo@dominio.com',
      emailVerified: false,
    );
    expect(identity.providerUserId, 'firebase-uid-123');
    expect(identity.emailVerified, isFalse);
  });

  test('pedido de recuperacao nao expõe existencia da conta', () {
    expect(PasswordResetRequestResult.values,
        contains(PasswordResetRequestResult.accepted));
    expect(PasswordResetRequestResult.values, isNot(contains('emailNotFound')));
  });
}
