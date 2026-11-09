enum HybridSessionDecision {
  authorized,
  localSessionRequired,
  firebaseIdentityRequired,
  identityMismatch,
  linkNotConfirmed,
  authorizationRequired,
}

class HybridSessionPolicy {
  const HybridSessionPolicy();

  HybridSessionDecision evaluate({
    required int? localUserId,
    required String? firebaseUid,
    required String? linkedFirebaseUid,
    required String? linkState,
    required bool trustedAuthorizationValid,
  }) {
    // Exige uma conta local válida.
    if (localUserId == null || localUserId <= 0) {
      return HybridSessionDecision.localSessionRequired;
    }

    // Exige uma identidade Firebase conhecida.
    if (firebaseUid == null || firebaseUid.trim().isEmpty) {
      return HybridSessionDecision.firebaseIdentityRequired;
    }

    // Somente vínculos confirmados podem prosseguir.
    if (linkState != 'confirmado') {
      return HybridSessionDecision.linkNotConfirmed;
    }

    // O UID associado deve corresponder ao UID autenticado.
    if (linkedFirebaseUid == null ||
        linkedFirebaseUid.trim().isEmpty ||
        linkedFirebaseUid != firebaseUid) {
      return HybridSessionDecision.identityMismatch;
    }

    // A confirmação SQLite não é autorização do servidor.
    if (!trustedAuthorizationValid) {
      return HybridSessionDecision.authorizationRequired;
    }

    return HybridSessionDecision.authorized;
  }
}
