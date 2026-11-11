import 'package:flutter/foundation.dart';

/// Notifica widgets de avatar sobre alteracoes da foto ou da sessao.
/// Nao armazena dados pessoais nem substitui validacao de sessao.
class AvatarPerfilNotifier {
  AvatarPerfilNotifier._();

  static final ValueNotifier<int> revisao = ValueNotifier<int>(0);

  static void notificarAlteracao() {
    revisao.value++;
  }
}
