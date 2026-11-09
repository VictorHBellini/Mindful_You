import 'package:flutter_test/flutter_test.dart';

import 'package:mindful_you/features/auth/services/migration_record_identity.dart';

void main() {
  group('Identidade de registros para migração', () {
    test('gera identificador global com 32 caracteres hexadecimais', () {
      const generator = MigrationGlobalIdGenerator();

      final id = generator.generate();

      expect(id.length, 32);
      expect(RegExp(r'^[a-f0-9]{32}$').hasMatch(id), true);
    });

    test('gera identificadores distintos em chamadas consecutivas', () {
      const generator = MigrationGlobalIdGenerator();

      final ids = List.generate(
        100,
        (_) => generator.generate(),
      );

      expect(ids.toSet().length, 100);
    });

    test('aceita identidade com IDs locais válidos', () {
      const identity = MigrationRecordIdentity(
        localUserId: 7,
        localRecordId: 15,
        type: MigrationRecordType.checkin,
        globalId: '0123456789abcdef0123456789abcdef',
      );

      expect(identity.isValid, true);
    });

    test('rejeita usuário local inválido', () {
      const identity = MigrationRecordIdentity(
        localUserId: 0,
        localRecordId: 15,
        type: MigrationRecordType.checkin,
        globalId: '0123456789abcdef0123456789abcdef',
      );

      expect(identity.isValid, false);
    });

    test('rejeita registro local inválido', () {
      const identity = MigrationRecordIdentity(
        localUserId: 7,
        localRecordId: -1,
        type: MigrationRecordType.avaliacao,
        globalId: '0123456789abcdef0123456789abcdef',
      );

      expect(identity.isValid, false);
    });

    test('rejeita identificador global vazio', () {
      const identity = MigrationRecordIdentity(
        localUserId: 7,
        localRecordId: 15,
        type: MigrationRecordType.avaliacao,
        globalId: '',
      );

      expect(identity.isValid, false);
    });

    test('rejeita identificador global fora do formato', () {
      const identity = MigrationRecordIdentity(
        localUserId: 7,
        localRecordId: 15,
        type: MigrationRecordType.checkin,
        globalId: 'id-invalido',
      );

      expect(identity.isValid, false);
    });
  });
}
