import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/account_link_diagnostic.dart';

void main() {
  test('oculta UID e identifica conflito', () {
    final result = AccountLinkDiagnostic.describe(
      storedUid: 'abcde123456789',
      state: 'pendente',
      currentUid: 'zzzzz123456789',
      usingEmulator: true,
    );
    expect(result, contains('CONFLITO'));
    expect(result, contains('Firebase Emulator'));
    expect(result, isNot(contains('abcde123456789')));
    expect(result, isNot(contains('zzzzz123456789')));
  });

  test('vínculo revogado não é tratado como ativo', () {
    final result = AccountLinkDiagnostic.describe(
      storedUid: 'abcde123456789',
      state: 'revogado',
      currentUid: 'zzzzz123456789',
      usingEmulator: false,
    );
    expect(result, contains('registro revogado'));
    expect(result, isNot(contains('CONFLITO')));
  });

  test('identifica UID coincidente sem autorizar vínculo', () {
    final result = AccountLinkDiagnostic.describe(
      storedUid: 'abcde123456789',
      state: 'confirmado',
      currentUid: 'abcde123456789',
      usingEmulator: true,
    );
    expect(result, contains('UIDs coincidem'));
    expect(result, contains('Nenhum vínculo ou histórico foi alterado'));
  });
}
