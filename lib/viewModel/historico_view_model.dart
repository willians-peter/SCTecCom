import 'package:flutter/foundation.dart';
import 'package:projeto_telecom/data/models/atendimento_model.dart';
import 'package:projeto_telecom/data/repositories/atendimento_repository.dart';

/// ViewModel para a Tela de Histórico de Atendimentos (RF14, RF15, RF16)
class HistoricoViewModel extends ChangeNotifier {
  final AtendimentoRepository _atendimentoRepository;

  List<AtendimentoModel> _historicoCompleto = [];
  List<AtendimentoModel> _historicoFiltrado = [];
  bool _isLoading = false;
  String _filtroTexto = '';
  String? _mensagemErro;
  AtendimentoModel? _atendimentoSelecionado;

  HistoricoViewModel({AtendimentoRepository? atendimentoRepository})
      : _atendimentoRepository = atendimentoRepository ?? AtendimentoRepository();

  List<AtendimentoModel> get itens => _historicoFiltrado;
  bool get isLoading => _isLoading;
  String get filtroTexto => _filtroTexto;
  String? get mensagemErro => _mensagemErro;
  AtendimentoModel? get atendimentoSelecionado => _atendimentoSelecionado;
  int get totalItens => _historicoFiltrado.length;

  /// Carrega todo o histórico de atendimentos (RF14)
  Future<void> carregarHistorico() async {
    _isLoading = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      _historicoCompleto = await _atendimentoRepository.getHistoricoCompleto();
      _aplicarFiltro();
    } catch (e) {
      _mensagemErro = 'Erro ao carregar histórico: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza o filtro de busca em tempo real por ID ou código de cliente (RF15)
  void atualizarFiltro(String query) {
    _filtroTexto = query;
    _aplicarFiltro();
    notifyListeners();
  }

  void _aplicarFiltro() {
    _historicoFiltrado = _atendimentoRepository.filtrarHistorico(
      _historicoCompleto,
      _filtroTexto,
    );
  }

  /// Define o atendimento em foco para exibição detalhada (RF16)
  void selecionarAtendimento(AtendimentoModel item) {
    _atendimentoSelecionado = item;
    notifyListeners();
  }
}
