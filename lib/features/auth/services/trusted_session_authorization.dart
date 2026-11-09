enum TrustedAuthorizationStatus {
  authorized,
  authenticationRequired,
  linkNotAuthorized,
  unavailable,
}

class TrustedAuthorizationResult {
  const TrustedAuthorizationResult({
    required this.status,
  });

  final TrustedAuthorizationStatus status;

  bool get isAuthorized => status == TrustedAuthorizationStatus.authorized;
}

/// Porta para um verificador confiável de autorização.
///
/// A implementação online deverá consultar um backend autenticado,
/// que validará a identidade Firebase e o vínculo autorizado.
///
/// A implementação offline exigirá um mecanismo próprio de
/// verificação criptográfica, expiração e proteção local.
abstract class TrustedSessionAuthorization {
  Future<TrustedAuthorizationResult> verify({
    required int localUserId,
    required String firebaseUid,
  });
}

/// Implementação segura por padrão.
///
/// Enquanto a autorização real não existir, nenhuma sessão
/// híbrida recebe permissão.
class DenyByDefaultSessionAuthorization implements TrustedSessionAuthorization {
  const DenyByDefaultSessionAuthorization();

  @override
  Future<TrustedAuthorizationResult> verify({
    required int localUserId,
    required String firebaseUid,
  }) async {
    return const TrustedAuthorizationResult(
      status: TrustedAuthorizationStatus.linkNotAuthorized,
    );
  }
}
