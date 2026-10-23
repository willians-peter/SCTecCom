import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scteccom_app/data/datasources/local/database_helper.dart';
import 'package:scteccom_app/data/datasources/remote/api_datasource.dart';
import 'package:scteccom_app/data/datasources/remote/secure_storage_datasource.dart';
import 'package:scteccom_app/data/models/atendimento_model.dart';
import 'package:scteccom_app/data/repositories/atendimento_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockApiDatasource extends Mock implements ApiDatasource {}
class MockSecureStorageDatasource extends Mock implements SecureStorageDatasource {}

void main() {
  late MockDatabaseHelper mockDatabaseHelper;
  late MockApiDatasource mockApiDatasource;
  late MockSecureStorageDatasource mockSecureStorage;
  late AtendimentoRepository atendimentoRepository;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockApiDatasource = MockApiDatasource();
    mockSecureStorage = MockSecureStorageDatasource();
    atendimentoRepository = AtendimentoRepository(
      databaseHelper: mockDatabaseHelper,
      apiDatasource: mockApiDatasource,
      secureStorage: mockSecureStorage,
    );
  });

  group('AtendimentoRepository - Gravação Offline e Sincronização (RF12, RF13, RF15)', () {
    test('registrarAtendimentoOffline deve inserir no banco local', () async {
      final atendimento = AtendimentoModel(
        chamadoId: 10,
        categoriaTecnico: 'Troca de Roteador',
        descricaoProcedimento: 'Roteador configurado e entregue.',
        dataResolucao: '2026-10-10 15:00:00',
        sincronizado: false,
      );

      when(() => mockDatabaseHelper.inserirAtendimento(atendimento))
          .thenAnswer((_) async => 1);

      final id = await atendimentoRepository.registrarAtendimentoOffline(atendimento);
      expect(id, equals(1));
      verify(() => mockDatabaseHelper.inserirAtendimento(atendimento)).called(1);
    });

    test('sincronizarAtendimentosPendentes deve enviar via API e marcar como sincronizado (RF13)', () async {
      final pendente = AtendimentoModel(
        id: 1,
        chamadoId: 20,
        categoriaTecnico: 'Conector Danificado',
        descricaoProcedimento: 'Novo conector APC instalado.',
        dataResolucao: '2026-10-10 16:00:00',
        sincronizado: false,
      );

      when(() => mockSecureStorage.getToken()).thenAnswer((_) async => 'token_xyz');
      when(() => mockDatabaseHelper.getAtendimentosPendentes())
          .thenAnswer((_) async => [pendente]);

      when(() => mockApiDatasource.registrarAtendimento(
            token: 'token_xyz',
            chamadoId: 20,
            categoriaTecnico: 'Conector Danificado',
            descricaoProcedimento: 'Novo conector APC instalado.',
            dataResolucao: '2026-10-10 16:00:00',
            fotoArquivo: null,
          )).thenAnswer((_) async => {
            'atendimento_id': 99,
            'foto_url': 'https://exemplo.com/foto99.jpg',
          });

      when(() => mockDatabaseHelper.marcarAtendimentoSincronizado(
            idLocal: 1,
            remoteAtendimentoId: 99,
            fotoUrlRemota: 'https://exemplo.com/foto99.jpg',
          )).thenAnswer((_) async => 1);

      final total = await atendimentoRepository.sincronizarAtendimentosPendentes();

      expect(total, equals(1));
      verify(() => mockDatabaseHelper.marcarAtendimentoSincronizado(
            idLocal: 1,
            remoteAtendimentoId: 99,
            fotoUrlRemota: 'https://exemplo.com/foto99.jpg',
          )).called(1);
    });

    test('filtrarHistorico deve filtrar em tempo real por ID ou código do cliente (RF15)', () {
      final lista = [
        AtendimentoModel(
          id: 1,
          chamadoId: 101,
          codigoCliente: 'CLI-555',
          nomeCliente: 'Lucas Silva',
          categoriaTecnico: 'Conector',
          descricaoProcedimento: 'Reparo A',
          dataResolucao: '2026-10-10',
          sincronizado: true,
        ),
        AtendimentoModel(
          id: 2,
          chamadoId: 202,
          codigoCliente: 'CLI-999',
          nomeCliente: 'Mariana Rios',
          categoriaTecnico: 'Roteador',
          descricaoProcedimento: 'Reparo B',
          dataResolucao: '2026-10-10',
          sincronizado: false,
        ),
      ];

      // Busca por ID do chamado '101'
      final buscaPorId = atendimentoRepository.filtrarHistorico(lista, '101');
      expect(buscaPorId.length, equals(1));
      expect(buscaPorId.first.chamadoId, equals(101));

      // Busca por Código do cliente 'CLI-999'
      final buscaPorCodigo = atendimentoRepository.filtrarHistorico(lista, 'CLI-999');
      expect(buscaPorCodigo.length, equals(1));
      expect(buscaPorCodigo.first.codigoCliente, equals('CLI-999'));

      // Busca vazia retorna todos
      final buscaVazia = atendimentoRepository.filtrarHistorico(lista, '');
      expect(buscaVazia.length, equals(2));
    });
  });
}
