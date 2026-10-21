import 'package:firebase_auth/firebase_auth.dart';

import 'auth_contracts.dart';

/// Adaptador remoto isolado: nao substitui a sessao SQLite.
/// Nunca associe um UID remoto a um usuario local somente pelo e-mail.
class FirebaseIdentityProvider implements RemoteIdentityProvider {
  FirebaseIdentityProvider({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  AuthIdentity _identity(User user) => AuthIdentity(
        provider: AuthProviderKind.firebase,
        providerUserId: user.uid,
        email: user.email,
        emailVerified: user.emailVerified,
      );

  @override
  Future<AuthIdentity?> currentIdentity() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    final refreshed = _auth.currentUser;
    return refreshed == null ? null : _identity(refreshed);
  }

  @override
  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('O provedor nao retornou uma identidade.');
    }
    return _identity(user);
  }

  @override
  Future<AuthIdentity> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('O provedor nao retornou uma identidade.');
    }
    await user.sendEmailVerification();
    return _identity(user);
  }

  @override
  Future<PasswordResetRequestResult> requestPasswordReset(
    String email,
  ) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return PasswordResetRequestResult.accepted;
    } on FirebaseAuthException catch (error) {
      // Nao exponha a existencia da conta, mesmo quando a protecao
      // contra enumeracao de e-mails nao estiver habilitada no projeto.
      if (error.code == 'user-not-found' || error.code == 'email-not-found') {
        return PasswordResetRequestResult.accepted;
      }
      return PasswordResetRequestResult.temporarilyUnavailable;
    } catch (_) {
      return PasswordResetRequestResult.temporarilyUnavailable;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
