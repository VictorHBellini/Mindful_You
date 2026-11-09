import 'dart:math';

/// Tipos de históricos inicialmente elegíveis
/// para uma futura migração.
enum MigrationRecordType {
  checkin,
  avaliacao,
}

/// Identidade estável de um registro local.
///
/// Este objeto não concede autorização Firebase
/// e não realiza sincronização.
class MigrationRecordIdentity {
  const MigrationRecordIdentity({
    required this.localUserId,
    required this.localRecordId,
    required this.type,
    required this.globalId,
  });

  final int localUserId;
  final int localRecordId;
  final MigrationRecordType type;
  final String globalId;

  bool get isValid {
    return localUserId > 0 &&
        localRecordId > 0 &&
        globalId.isNotEmpty &&
        RegExp(r'^[a-f0-9]{32}$').hasMatch(globalId);
  }
}

/// Gera identificadores aleatórios de 128 bits.
///
/// A persistência será implementada na próxima etapa.
/// Gerar um ID não significa que ele foi salvo.
class MigrationGlobalIdGenerator {
  const MigrationGlobalIdGenerator();

  String generate() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    );

    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
