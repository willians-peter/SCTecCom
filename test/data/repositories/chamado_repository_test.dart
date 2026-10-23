import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scteccom_app/data/datasources/local/database_helper.dart';
import 'package:scteccom_app/data/datasources/remote/api_datasource.dart';
import 'package:scteccom_app/data/datasources/remote/secure_storage_datasource.dart';
import 'package:scteccom_app/data/models/chamado_model.dart';
import 'package:scteccom_app/data/repositories/chamado_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockApiDatasource extends Mock implements ApiDatasource {}
class MockSecureStorageDatasource extends Mock implements SecureStorageDatasource {}

void main() {
  late MockDatabaseHelper mockDatabaseHelper;
  late MockApiDatasource mockApiDatasource;
  late MockSecureStorageDatasource mockSecureStorage;
  late ChamadoRepository chamadoRepository;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockApiDatasource = MockApiDatasource();
    mockSecureStorage = MockSecureStorageDatasource();
    chamadoRepository = ChamadoRepository(
      databaseHelper: mockDatabaseHelper,
      apiDatasource: mockApiDatasource,
      secureStorage: mockSecureStorage,
    );
  });

  group('ChamadoRepository - Carga, Persistência e Ordenação por Proximidade (RF04, RF07)', () {
    final chamadoLonge = ChamadoModel(
      id: 1,
      codigoCliente: 'CLI-01',
      nomeCliente: 'Cliente Distante',
      categoriaInformada: 'Lentidão',
      descricaoProblema: 'Problema A',
      enderecoCliente: 'Rua A',
      bairro: 'Centro',
      cidade: 'Florianópolis',
      latitude: -27.6500, // Mais distante
      longitude: -48.6000,
      status: 'ativo',
      criadoEm: '2026-10-10 10:00:00',
    );

    final chamadoPerto = ChamadoModel(
      id: 2,
      codigoCliente: 'CLI-02',
      nomeCliente: 'Cliente Próximo',
      categoriaInformada: 'Sem Sinal',
      descricaoProblema: 'Problema B',
      enderecoCliente: 'Rua B',
      bairro: 'Centro',
      cidade: 'Florianópolis',
      latitude: -27.5950, // Mais próximo da origem (-27.5948)
      longitude: -48.5480,
      status: 'ativo',
      criadoEm: '2026-10-10 10:30:00',
    );

    test('sincronizarComApi deve buscar da API e gravar no SQLite', () async {
      when(() => mockSecureStorage.getToken())
          .thenAnswer((_) async => 'token_123');
      when(() => mockApiDatasource.getChamadosAtivos('token_123'))
          .thenAnswer((_) async => [chamadoLonge, chamadoPerto]);
      when(() => mockDatabaseHelper.salvarChamados([chamadoLonge, chamadoPerto]))
          .thenAnswer((_) async {});

      final resultado = await chamadoRepository.sincronizarComApi();

      expect(resultado.length, equals(2));
      verify(() => mockDatabaseHelper.salvarChamados([chamadoLonge, chamadoPerto])).called(1);
    });

    test('ordenarPorProximidade deve ordenar do mais perto ao mais longe (RF07)', () {
      // Coordenadas do técnico (próximo de chamadoPerto)
      const latTecnico = -27.5948;
      const lonTecnico = -48.5478;

      final ordenados = chamadoRepository.ordenarPorProximidade(
        chamados: [chamadoLonge, chamadoPerto],
        latitudeTecnico: latTecnico,
        longitudeTecnico: lonTecnico,
      );

      // O primeiro da lista deve ser o mais próximo (chamadoPerto - ID 2)
      expect(ordenados.first.id, equals(2));
      expect(ordenados.last.id, equals(1));
      expect(ordenados.first.distanciaKm, isNotNull);
      expect(ordenados.first.distanciaKm!, lessThan(ordenados.last.distanciaKm!));
    });

    test('métodos avançados (where, every, reduce) devem funcionar corretamente', () {
      final lista = [chamadoLonge, chamadoPerto];

      // where
      final filtrados = chamadoRepository.filtrarPorCategoria(lista, 'Sem Sinal');
      expect(filtrados.length, equals(1));
      expect(filtrados.first.id, equals(2));

      // every
      expect(chamadoRepository.todosTemCoordenadasValidas(lista), isTrue);

      // reduce para achar o mais próximo
      final listaComDistancia = chamadoRepository.ordenarPorProximidade(
        chamados: lista,
        latitudeTecnico: -27.5948,
        longitudeTecnico: -48.5478,
      );
      final maisProximo = chamadoRepository.encontrarMaisProximo(listaComDistancia);
      expect(maisProximo?.id, equals(2));
    });
  });
}
