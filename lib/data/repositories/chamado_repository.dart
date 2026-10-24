import 'package:scteccom_app/utils/location_helper.dart';
import '../datasources/local/database_helper.dart';
import '../datasources/remote/api_datasource.dart';
import '../datasources/remote/secure_storage_datasource.dart';
import '../models/chamado_model.dart';

/// Repositório de Chamados / Ordens de Serviço (RF04, RF05, RF06, RF07)
class ChamadoRepository {
  final DatabaseHelper _databaseHelper;
  final ApiDatasource _apiDatasource;
  final SecureStorageDatasource _secureStorage;

  ChamadoRepository({
    DatabaseHelper? databaseHelper,
    ApiDatasource? apiDatasource,
    SecureStorageDatasource? secureStorage,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _apiDatasource = apiDatasource ?? ApiDatasource(),
        _secureStorage = secureStorage ?? SecureStorageDatasource();

  /// Sincroniza e faz carga inicial dos chamados da API para o SQLite (RF04)
  Future<List<ChamadoModel>> sincronizarComApi() async {
    final token = await _secureStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Não autenticado. Token não encontrado.');
    }

    // 1. Busca os chamados ativos do técnico na nuvem
    final chamadosRemotos = await _apiDatasource.getChamadosAtivos(token);

    // 2. Salva todos no SQLite local
    await _databaseHelper.salvarChamados(chamadosRemotos);

    return chamadosRemotos;
  }

  /// Carrega os chamados ativos diretamente do banco SQLite local (RF05, RF06)
  Future<List<ChamadoModel>> getChamadosLocais() async {
    return await _databaseHelper.getChamadosAtivos();
  }

  /// Busca um chamado específico por ID
  Future<ChamadoModel?> getChamadoPorId(int id) async {
    return await _databaseHelper.getChamadoPorId(id);
  }

  /// Atualiza o status do chamado localmente
  Future<void> atualizarStatus(int id, String novoStatus) async {
    await _databaseHelper.atualizarStatusChamado(id, novoStatus);
  }

  /// Calcula a distância geográfica e ordena a lista de chamados por proximidade (RF07)
  /// Demonstra o uso de métodos funcionais avançados do Dart (map, where)
  List<ChamadoModel> ordenarPorProximidade({
    required List<ChamadoModel> chamados,
    required double latitudeTecnico,
    required double longitudeTecnico,
  }) {
    // 1. Mapeia cada chamado calculando a distância pelo GPS
    final chamadosComDistancia = chamados.map((chamado) {
      // Ignora chamados sem coordenadas válidas atribuindo distância nula
      if (chamado.latitude == 0.0 && chamado.longitude == 0.0) {
        return chamado.copyWith(distanciaKm: null);
      }

      final distancia = LocationHelper.calcularDistanciaKm(
        latOrigem: latitudeTecnico,
        lonOrigem: longitudeTecnico,
        latDestino: chamado.latitude,
        lonDestino: chamado.longitude,
      );

      return chamado.copyWith(distanciaKm: distancia);
    }).toList();

    // 2. Ordena de forma crescente pela distância (do mais perto ao mais longe)
    chamadosComDistancia.sort((a, b) {
      if (a.distanciaKm == null) return 1;
      if (b.distanciaKm == null) return -1;
      return a.distanciaKm!.compareTo(b.distanciaKm!);
    });

    return chamadosComDistancia;
  }

  /// Demonstra métodos avançados do Dart (where, every, firstWhere)
  List<ChamadoModel> filtrarPorCategoria(List<ChamadoModel> lista, String categoria) {
    return lista.where((c) => c.categoriaInformada.toLowerCase().contains(categoria.toLowerCase())).toList();
  }

  bool todosTemCoordenadasValidas(List<ChamadoModel> lista) {
    return lista.every((c) => c.latitude != 0.0 && c.longitude != 0.0);
  }

  ChamadoModel? encontrarMaisProximo(List<ChamadoModel> lista) {
    if (lista.isEmpty) return null;
    final comDistancia = lista.where((c) => c.distanciaKm != null).toList();
    if (comDistancia.isEmpty) return lista.first;

    return comDistancia.reduce((atual, proximo) =>
        (atual.distanciaKm! < proximo.distanciaKm!) ? atual : proximo);
  }
}
