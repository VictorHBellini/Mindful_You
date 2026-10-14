import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/services/crypto_utils.dart';

void main() {
  test('PBKDF2 determinístico e comprimento correto', () {
    final entrada = {
      'senha': 'senha demonstrativa',
      'saltHex': '00112233445566778899aabbccddeeff',
      'iteracoes': 10000,
    };
    final a = CryptoUtils.pbkdf2Derivar(entrada);
    final b = CryptoUtils.pbkdf2Derivar(entrada);
    expect(a, b);
    expect(a, hasLength(64));
    expect(CryptoUtils.pbkdf2Derivar({...entrada, 'senha': 'outra'}), isNot(a));
  });
}
