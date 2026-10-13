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
