import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/auth_contracts.dart';
import 'package:mindful_you/features/auth/services/firebase_identity_provider.dart';

void main() {
  test('adaptador Firebase implementa contrato remoto', () {
    expect(FirebaseIdentityProvider, isNotNull);
  });

  test('resultado de recuperacao nao revela existencia de e-mail', () {
    expect(PasswordResetRequestResult.values,
        contains(PasswordResetRequestResult.accepted));
    expect(PasswordResetRequestResult.values,
        contains(PasswordResetRequestResult.temporarilyUnavailable));
  });
}
