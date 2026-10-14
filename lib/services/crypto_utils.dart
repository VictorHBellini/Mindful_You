import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Funções de hash e comparação de senha compartilhadas entre
/// `DatabaseService` (senha de cada usuário) e `AdminService` (senha
/// extra de administrador).
///
/// MELHORIA: antes, `DatabaseService` tinha uma implementação própria
/// do algoritmo SHA-256 (mais de 60 linhas reimplementando o padrão
/// na mão). Funcionava, mas qualquer bug sutil nela comprometeria a
/// segurança das senhas sem nenhum aviso. Agora usamos o pacote
/// `crypto` (mantido pela equipe do Dart), testado e usado por milhões
/// de apps — e as duas classes compartilham a mesma lógica em vez de
/// cada uma reimplementar a sua.
class CryptoUtils {
  CryptoUtils._();

  /// PBKDF2-HMAC-SHA256 (32 bytes), implementação conforme RFC 8018.
  /// Usada em isolate via compute; não chamar diretamente na UI.
  static String pbkdf2Derivar(Map<String, Object> parametros) {
    final senha = parametros['senha'] as String;
    final saltHex = parametros['saltHex'] as String;
    final iteracoes = parametros['iteracoes'] as int;
    if (iteracoes < 10000 ||
        iteracoes > 1000000 ||
        saltHex.length != 32 ||
        !RegExp(r'^[0-9a-fA-F]+$').hasMatch(saltHex)) {
      throw ArgumentError('Parâmetros PBKDF2 inválidos');
    }
    final salt = List<int>.generate(
        16, (i) => int.parse(saltHex.substring(i * 2, i * 2 + 2), radix: 16));
    final mac = Hmac(sha256, utf8.encode(senha));
    var bloco = <int>[...salt, 0, 0, 0, 1];
    var u = mac.convert(bloco).bytes;
    final acumulado = List<int>.from(u);
    for (var i = 1; i < iteracoes; i++) {
      u = mac.convert(u).bytes;
      for (var j = 0; j < acumulado.length; j++) {
        acumulado[j] ^= u[j];
      }
    }
    return acumulado.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hash SHA-256 (hexadecimal) de [texto].
  static String sha256Hex(String texto) {
    return sha256.convert(utf8.encode(texto)).toString();
  }

  /// Compara dois hashes em tempo constante (não retorna assim que
  /// encontra a primeira diferença), para que o tempo de resposta não
  /// vaze informação sobre em qual posição um hash diverge do outro
  /// (proteção contra timing attacks).
  static bool hashesIguais(String a, String b) {
    if (a.length != b.length) return false;

    var diferenca = 0;
    for (var i = 0; i < a.length; i++) {
      diferenca |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return diferenca == 0;
  }
}
