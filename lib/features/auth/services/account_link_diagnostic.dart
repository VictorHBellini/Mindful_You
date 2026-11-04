/// Diagnóstico de vínculos: formata somente dados não sensíveis.
/// Não altera estado nem considera um vínculo local como autorização remota.
class AccountLinkDiagnostic {
  const AccountLinkDiagnostic._();

  static String maskUid(String? uid) {
    if (uid == null || uid.isEmpty) return '(ausente)';
    if (uid.length < 10) return '••••';
    return '${uid.substring(0, 5)}…${uid.substring(uid.length - 4)}';
  }

  static String describe({
    required String? storedUid,
    required String? state,
    required String? currentUid,
    required bool usingEmulator,
  }) {
    final buffer = StringBuffer()
      ..writeln(
          'Ambiente configurado: ${usingEmulator ? 'Firebase Emulator' : 'Firebase real'}')
      ..writeln('UID da sessão atual: ${maskUid(currentUid)}')
      ..writeln('Vínculo local: ${state ?? 'inexistente'}')
      ..writeln('UID salvo no SQLite: ${maskUid(storedUid)}');

    if (state == null) {
      buffer.writeln('Resultado: não há vínculo local registrado.');
    } else if (state == 'revogado') {
      buffer.writeln('Resultado: registro revogado; não é vínculo ativo.');
    } else if (currentUid == null || currentUid.isEmpty) {
      buffer.writeln('Resultado: não há sessão Firebase ativa para comparar.');
    } else if (storedUid == currentUid) {
      buffer.writeln('Resultado: os UIDs coincidem neste dispositivo.');
    } else {
      buffer.writeln('Resultado: CONFLITO — os UIDs são diferentes.');
    }
    buffer.write('O SQLite atual não registra o ambiente de origem do vínculo. '
        'Não é possível afirmar se o UID salvo veio do Firebase real ou do Emulator. '
        'Nenhum vínculo ou histórico foi alterado.');
    return buffer.toString();
  }
}
