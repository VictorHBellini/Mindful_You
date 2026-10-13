import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Registros fictícios F3.1. Nunca concede leitura ao terapeuta.
/// Não armazena respostas individuais ou o item sensível de avaliações.
class FirebaseRegistrosService {
  FirebaseRegistrosService._();
  static final instance = FirebaseRegistrosService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> _pacienteUid() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Faça login no Firebase.');
    final perfil = await _db.collection('usuarios').doc(uid).get();
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Sessão alterada.');
    }
    if (perfil.data()?['tipo_usuario'] != 'paciente') {
      throw StateError('Somente pacientes podem registrar dados.');
    }
    return uid;
  }

  Future<String> registrarCheckin({
    required int bemEstar,
    required double ansiedade,
    required double cansaco,
    required double sono,
    required double produtividade,
    required String sentimento,
  }) async {
    if (bemEstar < 0 ||
        bemEstar > 100 ||
        [ansiedade, cansaco, sono, produtividade]
            .any((v) => !v.isFinite || v < 0 || v > 100) ||
        sentimento.length > 120) {
      throw ArgumentError('Dados do check-in fora dos limites permitidos.');
    }
    final uid = await _pacienteUid();
    final ref =
        _db.collection('usuarios').doc(uid).collection('checkins').doc();
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Sessão alterada.');
    }
    await ref.set({
      'bem_estar': bemEstar,
      'ansiedade': ansiedade,
      'cansaco': cansaco,
      'sono': sono,
      'produtividade': produtividade,
      'sentimento': sentimento,
      'criado_em': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> registrarAvaliacao({
    required String instrumento,
    required String versao,
    required List<int> respostas,
  }) async {
    final quantidade = switch (instrumento) {
      'GAD7' => 7,
      'PHQ9' => 9,
      _ => throw ArgumentError('Instrumento inválido.'),
    };
    if (respostas.length != quantidade ||
        respostas.any((v) => v < 0 || v > 3) ||
        versao.trim().isEmpty ||
        versao.length > 80) {
      throw ArgumentError('Avaliação inválida.');
    }
    final uid = await _pacienteUid();
    final ref =
        _db.collection('usuarios').doc(uid).collection('avaliacoes').doc();
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Sessão alterada.');
    }
    await ref.set({
      'instrumento': instrumento,
      'versao': versao.trim(),
      'pontuacao': respostas.fold<int>(0, (total, v) => total + v),
      'criado_em': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> meusCheckins() async {
    final uid = await _pacienteUid();
    final docs = await _db
        .collection('usuarios')
        .doc(uid)
        .collection('checkins')
        .orderBy('criado_em', descending: true)
        .limit(50)
        .get();
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Sessão alterada.');
    }
    return docs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> minhasAvaliacoes() async {
    final uid = await _pacienteUid();
    final docs = await _db
        .collection('usuarios')
        .doc(uid)
        .collection('avaliacoes')
        .orderBy('criado_em', descending: true)
        .limit(50)
        .get();
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Sessão alterada.');
    }
    return docs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
