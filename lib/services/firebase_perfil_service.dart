import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Laboratório F2.2: somente perfis fictícios; não acessa dados clínicos.
class FirebasePerfilService {
  FirebasePerfilService._();
  static final instance = FirebasePerfilService._();

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      FirebaseFirestore.instance.collection('usuarios');

  Future<void> criarPerfil({required String nome, required String tipo}) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null || usuario.email == null) {
      throw StateError('Faça login para cadastrar o perfil.');
    }
    if (nome.trim().length < 3 || !['paciente', 'terapeuta'].contains(tipo)) {
      throw ArgumentError('Nome ou perfil inválido.');
    }
    final ref = _usuarios.doc(usuario.uid);
    await ref.set({
      'nome': nome.trim(),
      'email': usuario.email!.trim().toLowerCase(),
      'tipo_usuario': tipo,
      'criado_em': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> meuPerfil() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return null;
    final doc = await _usuarios.doc(usuario.uid).get();
    return doc.data();
  }
}
