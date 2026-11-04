import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/account_link_repository.dart';

void main() {
  test('interpreta registro persistido pendente', () {
    final link = StoredAccountLink.fromRow({
      'usuario_id': 7,
      'firebase_uid': 'uid-abc',
      'estado': 'pendente',
    });
    expect(link.localUserId, 7);
    expect(link.firebaseUid, 'uid-abc');
    expect(link.state, 'pendente');
  });

  test('interpreta registro revogado sem reativar vínculo', () {
    final link = StoredAccountLink.fromRow({
      'usuario_id': 7,
      'firebase_uid': 'uid-abc',
      'estado': 'revogado',
    });
    expect(link.state, 'revogado');
  });

  test('rejeita estados não reconhecidos', () {
    expect(
      () => StoredAccountLink.fromRow({
        'usuario_id': 7,
        'firebase_uid': 'uid-abc',
        'estado': 'ativo',
      }),
      throwsStateError,
    );
  });

  test('rejeita UID vazio', () {
    expect(
      () => StoredAccountLink.fromRow({
        'usuario_id': 7,
        'firebase_uid': '',
        'estado': 'pendente',
      }),
      throwsStateError,
    );
  });
}
