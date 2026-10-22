import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:scteccom_app/data/repositories/atendimento_repository.dart';
import 'package:scteccom_app/utils/constants.dart';

/// ViewModel de Sincronização Automática em Segundo Plano (RF13)
///
/// Monitora o status de rede via connectivity_plus e executa a sincronização
/// dos atendimentos pendentes a cada 5 minutos ou no restabelecimento da conectividade.
class SyncViewModel extends ChangeNotifier {
  final AtendimentoRepository _atendimentoRepository;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timerPeriodico;

  bool _isSincronizando = false;
  bool _temConexao = true;
  int _totalPendentes = 0;
  String? _ultimaSincronizacao;

  SyncViewModel({
    AtendimentoRepository? atendimentoRepository,
    Connectivity? connectivity,
  })  : _atendimentoRepository = atendimentoRepository ?? AtendimentoRepository(),
        _connectivity = connectivity ?? Connectivity() {
    _iniciarMonitoramento();
  }

  bool get isSincronizando => _isSincronizando;
  bool get temConexao => _temConexao;
  int get totalPendentes => _totalPendentes;
  String? get ultimaSincronizacao => _ultimaSincronizacao;

  /// Inicia o ouvinte de rede e o timer de 5 minutos, caso não utilize botão sincronizar (RF13)
  void _iniciarMonitoramento() {
    // 1. Escuta mudanças na conectividade
    _subscription = _connectivity.onConnectivityChanged.listen((resultados) {
      final conectou = resultados.any((r) => r != ConnectivityResult.none);
      final conectividadeRestabelecida = !_temConexao && conectou;
      _temConexao = conectou;
      notifyListeners();

      // Se a conexão foi restabelecida, dispara a sincronização imediatamente
      if (conectividadeRestabelecida) {
        sincronizarPendentes();
      }
    });

    // 2. Timer de 5 minutos para sincronização contínua de pendências (RF13)
    _timerPeriodico = Timer.periodic(
      const Duration(minutes: AppConstants.syncIntervalMinutes),
      (_) => sincronizarPendentes(),
    );

    // Atualiza contagem inicial de pendências
    atualizarContagemPendentes();
  }

  /// Atualiza o total de atendimentos com sincronizado = 0
  Future<void> atualizarContagemPendentes() async {
    try {
      final pendentes = await _atendimentoRepository.getPendentes();
      _totalPendentes = pendentes.length;
      notifyListeners();
    } catch (_) {}
  }

  /// Executa o upload multipart dos atendimentos pendentes
  Future<int> sincronizarPendentes() async {
    if (_isSincronizando) return 0;

    // Checa conectividade rápida
    final resultados = await _connectivity.checkConnectivity();
    _temConexao = resultados.any((r) => r != ConnectivityResult.none);
    if (!_temConexao) {
      await atualizarContagemPendentes();
      return 0;
    }

    _isSincronizando = true;
    notifyListeners();

    try {
      final sincronizados = await _atendimentoRepository.sincronizarAtendimentosPendentes();
      await atualizarContagemPendentes();

      if (sincronizados > 0) {
        final agora = DateTime.now();
        _ultimaSincronizacao =
            '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';
      }

      return sincronizados;
    } catch (e) {
      debugPrint('Erro na rotina de sincronização em segundo plano: $e');
      return 0;
    } finally {
      _isSincronizando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timerPeriodico?.cancel();
    super.dispose();
  }
}
