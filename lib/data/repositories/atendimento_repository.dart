import 'dart:io';
import 'package:projeto_telecom/data/datasources/local/database_helper.dart';
import 'package:projeto_telecom/data/datasources/remote/api_datasource.dart';
import 'package:projeto_telecom/data/datasources/remote/secure_storage_datasource.dart';
import 'package:projeto_telecom/data/models/atendimento_model.dart';

/// Repositório de Atendimentos Técnicos e Sincronização em Nuvem (RF12, RF13, RF14, RF15)
class AtendimentoRepository {
  final DatabaseHelper _databaseHelper;
  final ApiDatasource _apiDatasource;
  final SecureStorageDatasource _secureStorage;

  AtendimentoRepository({
    DatabaseHelper? databaseHelper,
    ApiDatasource? apiDatasource,
    SecureStorageDatasource? secureStorage,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _apiDatasource = apiDatasource ?? ApiDatasource(),
        _secureStorage = secureStorage ?? SecureStorageDatasource();

  /// Grava o atendimento localmente no SQLite com sincronizado = 0 (RF12)
  Future<int> registrarAtendimentoOffline(AtendimentoModel atendimento) async {
    return await _databaseHelper.inserirAtendimento(atendimento);
  }

  /// Recupera atendimentos pendentes de sincronização
  Future<List<AtendimentoModel>> getPendentes() async {
    return await _databaseHelper.getAtendimentosPendentes();
  }

  /// Sincroniza todos os atendimentos pendentes com a API REST em formato Multipart (RF13)
  /// Retorna o número de atendimentos sincronizados com sucesso nesta rodada
  Future<int> sincronizarAtendimentosPendentes() async {
    final token = await _secureStorage.getToken();
    if (token == null || token.isEmpty) return 0;

    final pendentes = await _databaseHelper.getAtendimentosPendentes();
    if (pendentes.isEmpty) return 0;

    int totalSincronizados = 0;

    for (final item in pendentes) {
      try {
        File? fotoArquivo;
        if (item.fotoCaminhoLocal != null && item.fotoCaminhoLocal!.isNotEmpty) {
          final f = File(item.fotoCaminhoLocal!);
          if (f.existsSync()) {
            fotoArquivo = f;
          }
        }

        final respostaApi = await _apiDatasource.registrarAtendimento(
          token: token,
          chamadoId: item.chamadoId,
          categoriaTecnico: item.categoriaTecnico,
          descricaoProcedimento: item.descricaoProcedimento,
          dataResolucao: item.dataResolucao,
          fotoArquivo: fotoArquivo,
        );

        final remoteId = respostaApi['atendimento_id'] as int?;
        final fotoUrl = respostaApi['foto_url'] as String?;

        if (item.id != null) {
          await _databaseHelper.marcarAtendimentoSincronizado(
            idLocal: item.id!,
            remoteAtendimentoId: remoteId,
            fotoUrlRemota: fotoUrl,
          );
        }

        totalSincronizados++;
      } catch (e) {
        // Se falhar para um atendimento específico, continua tentando os outros
        continue;
      }
    }

    return totalSincronizados;
  }

  /// Carrega o histórico de atendimentos combinando dados locais e da API (RF14)
  Future<List<AtendimentoModel>> getHistoricoCompleto() async {
    // 1. Sempre carrega os atendimentos do SQLite local (garante funcionamento offline)
    final historicoLocal = await _databaseHelper.getHistoricoAtendimentos();

    // 2. Se houver conexão e token, tenta complementar com o histórico remoto
    try {
      final token = await _secureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        final historicoRemoto = await _apiDatasource.getHistorico(token);

        // Mapeia chamados locais para evitar duplicidades
        final Map<int, AtendimentoModel> mapa = {};

        // Adiciona remotos primeiro
        for (final item in historicoRemoto) {
          mapa[item.chamadoId] = item;
        }

        // Sobrescreve com locais (que têm caminhos de arquivos locais mais recentes)
        for (final item in historicoLocal) {
          mapa[item.chamadoId] = item;
        }

        return mapa.values.toList();
      }
    } catch (_) {
      // Falha de rede: retorna o histórico local silenciosamente
    }

    return historicoLocal;
  }

  /// Filtro em tempo real por ID do chamado ou Código do cliente (RF15)
  List<AtendimentoModel> filtrarHistorico(List<AtendimentoModel> lista, String query) {
    if (query.trim().isEmpty) return lista;

    final q = query.trim().toLowerCase();
    return lista.where((item) {
      final idChamadoStr = item.chamadoId.toString();
      final codigoCliente = item.codigoCliente?.toLowerCase() ?? '';
      final nomeCliente = item.nomeCliente?.toLowerCase() ?? '';

      return idChamadoStr.contains(q) ||
          codigoCliente.contains(q) ||
          nomeCliente.contains(q);
    }).toList();
  }
}
