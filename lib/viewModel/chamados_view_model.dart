import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:projeto_telecom/data/models/chamado_model.dart';
import 'package:projeto_telecom/data/repositories/chamado_repository.dart';
import 'package:projeto_telecom/utils/location_helper.dart';

/// ViewModel de Gestão de Ordens de Serviço (RF06, RF07, RF08)
class ChamadosViewModel extends ChangeNotifier {
  final ChamadoRepository _chamadoRepository;

  List<ChamadoModel> _chamados = [];
  bool _isLoading = false;
  bool _isGpsLoading = false;
  String? _mensagemErro;
  Position? _posicaoAtual;

  ChamadosViewModel({ChamadoRepository? chamadoRepository})
      : _chamadoRepository = chamadoRepository ?? ChamadoRepository();

  List<ChamadoModel> get chamados => _chamados;
  bool get isLoading => _isLoading;
  bool get isGpsLoading => _isGpsLoading;
  String? get mensagemErro => _mensagemErro;
  Position? get posicaoAtual => _posicaoAtual;
  int get totalAbertos => _chamados.length;

  /// Carrega os chamados locais do SQLite e aplica ordenação por GPS se disponível (RF06, RF07)
  Future<void> carregarChamadosLocais({bool buscarGps = true}) async {
    _isLoading = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      final lista = await _chamadoRepository.getChamadosLocais();
      _chamados = lista;

      if (buscarGps) {
        await atualizarGpsEOrdenar(notificarCarregamento: false);
      }
    } catch (e) {
      _mensagemErro = 'Erro ao carregar chamados locais: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sincroniza a carga de chamados da API REST para o SQLite e recarrega a tela (RF04)
  Future<bool> sincronizarComApi() async {
    _isLoading = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      await _chamadoRepository.sincronizarComApi();
      await carregarChamadosLocais(buscarGps: true);
      return true;
    } catch (e) {
      _mensagemErro = 'Não foi possível sincronizar com a API (utilizando dados locais).';
      // Mesmo com erro de rede, tenta carregar o que já está salvo no banco local
      await carregarChamadosLocais(buscarGps: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Captura a posição via GPS e reordena dinamicamente por proximidade (RF07)
  Future<void> atualizarGpsEOrdenar({bool notificarCarregamento = true}) async {
    if (notificarCarregamento) {
      _isGpsLoading = true;
      notifyListeners();
    }

    try {
      final posicao = await LocationHelper.obterPosicaoAtual();
      if (posicao != null) {
        _posicaoAtual = posicao;
        _chamados = _chamadoRepository.ordenarPorProximidade(
          chamados: _chamados,
          latitudeTecnico: posicao.latitude,
          longitudeTecnico: posicao.longitude,
        );
      }
    } catch (e) {
      debugPrint('Aviso: GPS indisponível no momento: $e');
    } finally {
      _isGpsLoading = false;
      notifyListeners();
    }
  }

  /// Remove localmente o chamado que foi atendido
  void removerChamadoAtendido(int chamadoId) {
    _chamados.removeWhere((c) => c.id == chamadoId);
    notifyListeners();
  }
}
