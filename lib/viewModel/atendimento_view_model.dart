import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:scteccom_app/data/models/atendimento_model.dart';
import 'package:scteccom_app/data/models/chamado_model.dart';
import 'package:scteccom_app/data/repositories/atendimento_repository.dart';
import 'package:scteccom_app/utils/constants.dart';
import 'package:scteccom_app/utils/image_helper.dart';

/// ViewModel para a Tela de Atendimento Técnico e Parecer de Conclusão (RF09, RF10, RF11, RF12)
class AtendimentoViewModel extends ChangeNotifier {
  final AtendimentoRepository _atendimentoRepository;

  String? _categoriaSelecionada;
  File? _fotoComprovante;
  DateTime _dataResolucao = DateTime.now();
  bool _isSalvando = false;
  String? _mensagemErro;

  AtendimentoViewModel({AtendimentoRepository? atendimentoRepository})
      : _atendimentoRepository = atendimentoRepository ?? AtendimentoRepository();

  String? get categoriaSelecionada => _categoriaSelecionada;
  File? get fotoComprovante => _fotoComprovante;
  DateTime get dataResolucao => _dataResolucao;
  bool get isSalvando => _isSalvando;
  String? get mensagemErro => _mensagemErro;

  String get dataResolucaoFormatada =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(_dataResolucao);

  void setCategoria(String? categoria) {
    _categoriaSelecionada = categoria;
    notifyListeners();
  }

  void setDataResolucao(DateTime data) {
    _dataResolucao = data;
    notifyListeners();
  }

  /// Captura ou seleciona uma foto e a mantém para pré-visualização (RF11)
  Future<void> capturarFoto(ImageSource source) async {
    try {
      final arquivo = await ImageHelper.selecionarImagem(source);
      if (arquivo != null) {
        _fotoComprovante = arquivo;
        notifyListeners();
      }
    } catch (e) {
      _mensagemErro = 'Não foi possível capturar a foto: $e';
      notifyListeners();
    }
  }

  void removerFoto() {
    _fotoComprovante = null;
    notifyListeners();
  }

  /// Limpa todos os campos do formulário
  void resetFormulario() {
    _categoriaSelecionada = null;
    _fotoComprovante = null;
    _dataResolucao = DateTime.now();
    _isSalvando = false;
    _mensagemErro = null;
    notifyListeners();
  }

  /// Finaliza o atendimento gravando os dados offline no SQLite (RF12)
  Future<bool> finalizarAtendimentoOffline({
    required ChamadoModel chamado,
    required String descricaoProcedimento,
  }) async {
    // 1. Validação estrita (RF10)
    if (_categoriaSelecionada == null || _categoriaSelecionada!.trim().isEmpty) {
      _mensagemErro = 'Selecione a categoria técnica do parecer.';
      notifyListeners();
      return false;
    }

    if (descricaoProcedimento.trim().length < AppConstants.minDescricaoChars) {
      _mensagemErro = 'A descrição do procedimento deve conter no mínimo 10 caracteres válidos.';
      notifyListeners();
      return false;
    }

    _isSalvando = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      String? caminhoFotoLocal;

      // 2. Comprime e salva a foto localmente caso tenha sido anexada (RF11)
      if (_fotoComprovante != null) {
        final fotoSalva = await ImageHelper.otimizarESalvarLocalmente(
          arquivoOriginal: _fotoComprovante!,
          chamadoId: chamado.id,
        );
        caminhoFotoLocal = fotoSalva.path;
      }

      // 3. Monta o modelo com sincronizado = false
      final atendimento = AtendimentoModel(
        chamadoId: chamado.id,
        categoriaTecnico: _categoriaSelecionada!,
        descricaoProcedimento: descricaoProcedimento.trim(),
        dataResolucao: dataResolucaoFormatada,
        fotoCaminhoLocal: caminhoFotoLocal,
        sincronizado: false,
        registradoEm: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        codigoCliente: chamado.codigoCliente,
        nomeCliente: chamado.nomeCliente,
        enderecoCliente: chamado.enderecoCompleto,
      );

      // 4. Grava no SQLite local
      await _atendimentoRepository.registrarAtendimentoOffline(atendimento);

      resetFormulario();
      return true;
    } catch (e) {
      _mensagemErro = 'Erro ao salvar atendimento no banco local: $e';
      return false;
    } finally {
      _isSalvando = false;
      notifyListeners();
    }
  }
}
