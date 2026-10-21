/// Contratos para a futura migração da autenticação local para Firebase Auth.
/// Esta etapa não altera o login, o cadastro nem as sessões atuais.
///
/// O UID remoto nunca deve ser associado a um usuário local somente porque
/// ambos informaram o mesmo e-mail. O vínculo exige comprovação de identidade.
enum AuthProviderKind { localSqlite, firebase }

enum AccountLinkStatus {
  notLinked,
  pendingVerification,
  linked,
  conflict,
}

/// Identidade autenticada pelo provedor correspondente.
/// [providerUserId] não é um e-mail e não deve ser usado como ID SQLite.
class AuthIdentity {
  const AuthIdentity({
    required this.provider,
    required this.providerUserId,
    required this.email,
    required this.emailVerified,
  });

  final AuthProviderKind provider;
  final String providerUserId;
  final String? email;
  final bool emailVerified;
}

/// Resultado genérico: não revela se o e-mail está cadastrado.
enum PasswordResetRequestResult { accepted, temporarilyUnavailable }

/// Porta para o provedor de identidade remoto. Nenhuma implementação é
/// conectada ao aplicativo nesta fase.
abstract class RemoteIdentityProvider {
  Future<AuthIdentity?> currentIdentity();

  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  });

  Future<AuthIdentity> register({
    required String email,
    required String password,
  });

  Future<PasswordResetRequestResult> requestPasswordReset(String email);

  Future<void> signOut();
}

/// Porta de associação segura entre um usuário SQLite e um UID remoto.
/// A implementação futura deverá exigir login local válido e verificação
/// da identidade remota, além de impedir vínculos duplicados.
abstract class LocalRemoteAccountLinker {
  Future<AccountLinkStatus> getStatus(int localUserId);

  Future<void> linkVerifiedIdentity({
    required int authenticatedLocalUserId,
    required AuthIdentity verifiedRemoteIdentity,
  });
}
