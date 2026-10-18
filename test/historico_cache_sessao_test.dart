import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/features/history/historico_global.dart';
import 'package:mindful_you/features/auth/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    invalidarCacheHistorico();
  });

  test('invalidação descarta dados do cache anterior', () {
    historicoGlobal = [
      {'sentimento': 'privado'},
    ];
    invalidarCacheHistorico();
    expect(historicoGlobal, isEmpty);
  });

  test('logout apaga identidade local e cache do histórico', () async {
    SharedPreferences.setMockInitialValues({
      'usuarioId': 10,
      'nomeUsuario': 'Conta A',
      'emailUsuario': 'a@exemplo.test',
      'tipoUsuario': 'paciente',
      'isAdmin': false,
      'fotoPerfil': 'foto-local',
    });
    historicoGlobal = [
      {'sentimento': 'privado'},
    ];
    await SessionService.encerrar();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('usuarioId'), isNull);
    expect(prefs.getString('nomeUsuario'), isNull);
    expect(prefs.getString('emailUsuario'), isNull);
    expect(prefs.getString('tipoUsuario'), isNull);
    expect(prefs.getBool('isAdmin'), isNull);
    expect(prefs.getString('fotoPerfil'), isNull);
    expect(historicoGlobal, isEmpty);
  });
}
