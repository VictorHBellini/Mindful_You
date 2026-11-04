import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:mindful_you/features/auth/services/account_link_diagnostic.dart';
import 'package:flutter/material.dart';
import 'package:mindful_you/features/auth/services/account_link_check_coordinator.dart';
import 'package:mindful_you/features/auth/services/account_link_preflight.dart';
import 'package:mindful_you/features/auth/services/account_link_proof_adapters.dart';
import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:mindful_you/features/auth/services/pending_local_link_cancellation.dart';

/// Laboratório: apenas verifica pré-requisitos. Nunca grava vínculos.
class AccountLinkPreflightScreen extends StatefulWidget {
  const AccountLinkPreflightScreen({super.key});

  @override
  State<AccountLinkPreflightScreen> createState() =>
      _AccountLinkPreflightScreenState();
}

class _AccountLinkPreflightScreenState
    extends State<AccountLinkPreflightScreen> {
  final _local = TextEditingController();
  final _remote = TextEditingController();
  bool _busy = false;
  String? _message;
  String? _diagnostic;
  String? _pendingUid;
  int? _pendingUserId;

  @override
  void dispose() {
    _local.dispose();
    _remote.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final session = await SessionService.validar();
      if (session == null) {
        if (mounted) {
          setState(() => _message = 'Entre na conta local novamente.');
        }
        return;
      }
      final preflight = AccountLinkPreflight(
        localProof: SqlitePasswordProof(password: _local.text),
        remoteProof: FirebasePasswordProof(password: _remote.text),
        conflicts: SqliteAccountLinkConflictLookup(),
      );
      final result =
          await AccountLinkCheckCoordinator(preflight).verify(session.id);
      if (!mounted) {
        return;
      }
      final sameSession = await SessionService.validar();
      if (!mounted) {
        return;
      }
      setState(() => _message = sameSession?.id == session.id
          ? result.message
          : 'A sessão local mudou. Faça login novamente.');
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Não foi possível concluir a verificação.');
      }
    } finally {
      _local.clear();
      _remote.clear();
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _diagnose() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _diagnostic = null;
      _pendingUid = null;
      _pendingUserId = null;
    });
    try {
      final session = await SessionService.validar();
      if (session == null) {
        if (mounted) {
          setState(() => _diagnostic = 'Entre na conta local novamente.');
        }
        return;
      }
      final db = await DatabaseService.instance.database;
      final rows = await db.query(
        'vinculos_contas_firebase',
        columns: ['firebase_uid', 'estado'],
        where: 'usuario_id = ?',
        whereArgs: [session.id],
        limit: 1,
      );
      final current = FirebaseAuth.instance.currentUser;
      final after = await SessionService.validar();
      if (!mounted) {
        return;
      }
      if (after?.id != session.id) {
        setState(
            () => _diagnostic = 'A sessão local mudou. Faça login novamente.');
        return;
      }
      const emulator = bool.fromEnvironment(
        'MINDFUL_FIREBASE_EMULATORS',
        defaultValue: false,
      );
      setState(() {
        if (rows.isNotEmpty && rows.first['estado'] == 'pendente') {
          _pendingUid = rows.first['firebase_uid'] as String?;
          _pendingUserId = session.id;
        }
        _diagnostic = AccountLinkDiagnostic.describe(
          storedUid:
              rows.isEmpty ? null : rows.first['firebase_uid'] as String?,
          state: rows.isEmpty ? null : rows.first['estado'] as String?,
          currentUid: current?.uid,
          usingEmulator: emulator,
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() => _diagnostic =
            'Falha ao consultar os vínculos locais. Nenhum dado foi alterado.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cancelPending() async {
    if (_busy || _pendingUid == null || _pendingUserId == null) return;
    final uid = _pendingUid!;
    final id = _pendingUserId!;
    final password = _local.text;
    if (password.isEmpty) {
      setState(
          () => _message = 'Informe a senha da conta local para cancelar.');
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar solicitação pendente?'),
        content: Text(
          'Somente a solicitação local pendente de UID '
          '${AccountLinkDiagnostic.maskUid(uid)} será revogada. '
          'O Firebase e os históricos não serão alterados. '
          'Esta ação não cria um novo vínculo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await const PendingLocalLinkCancellation().cancel(
        localUserId: id,
        expectedUid: uid,
        localPassword: password,
      );
      if (!mounted) return;
      setState(() {
        _message = result;
        _diagnostic = null;
        _pendingUid = null;
        _pendingUserId = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'Não foi possível cancelar a solicitação. Nenhuma alteração confirmada.');
      }
    } finally {
      _local.clear();
      _remote.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || kIsWeb) {
      return const Scaffold(
          body: Center(child: Text('Laboratório indisponível.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pré-verificação de contas')),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text(
              'Ambiente de testes. Nenhum vínculo será criado e nenhum histórico será transferido.'),
          const SizedBox(height: 20),
          TextField(
              controller: _local,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration:
                  const InputDecoration(labelText: 'Senha da conta local')),
          const SizedBox(height: 12),
          TextField(
              controller: _remote,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                  labelText: 'Senha da sessão Firebase atual')),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: _busy ? null : _check,
              child:
                  Text(_busy ? 'Verificando...' : 'Executar pré-verificação')),
          if (_message != null)
            Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(_message!, key: const Key('accountLinkResult'))),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _busy ? null : _diagnose,
            child: const Text('Diagnosticar vínculos (somente leitura)'),
          ),
          if (_diagnostic != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SelectableText(
                _diagnostic!,
                key: const Key('accountLinkDiagnostic'),
              ),
            ),
          if (_pendingUid != null && _pendingUserId != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _cancelPending,
              child: const Text('Cancelar solicitação pendente local'),
            ),
            const Text(
              'Para cancelar, informe sua senha local acima. '
              'A operação exige confirmação e não altera o Firebase.',
            ),
          ],
          const SizedBox(height: 16),
          const Text(
              'A conta Firebase precisa estar autenticada previamente neste dispositivo. Um resultado positivo não autoriza vinculação ou acesso a dados.'),
        ]),
      )),
    );
  }
}
