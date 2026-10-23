import 'package:flutter_test/flutter_test.dart';
import 'package:scteccom_app/data/datasources/local/database_helper.dart';
import 'package:scteccom_app/data/models/atendimento_model.dart';
import 'package:scteccom_app/data/models/chamado_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DatabaseHelper dbHelper;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${DatabaseHelper.tabelaChamados} (
            id INTEGER PRIMARY KEY,
            codigo_cliente TEXT NOT NULL,
            nome_cliente TEXT NOT NULL,
            categoria_informada TEXT NOT NULL,
            descricao_problema TEXT NOT NULL,
            endereco_cliente TEXT NOT NULL,
            bairro TEXT,
            cidade TEXT,
            latitude REAL,
            longitude REAL,
            status TEXT NOT NULL,
            criado_em TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE ${DatabaseHelper.tabelaAtendimentos} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chamado_id INTEGER NOT NULL,
            categoria_tecnico TEXT NOT NULL,
            descricao_procedimento TEXT NOT NULL,
            data_resolucao TEXT NOT NULL,
            foto_caminho_local TEXT,
            foto_url_remota TEXT,
            sincronizado INTEGER NOT NULL DEFAULT 0,
            remote_atendimento_id INTEGER,
            registrado_em TEXT,
            FOREIGN KEY (chamado_id) REFERENCES ${DatabaseHelper.tabelaChamados} (id)
          )
        ''');
      },
    );

    dbHelper = DatabaseHelper.comDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DatabaseHelper - Persistência Local SQLite (RF05, RF06, RF12, RF14)', () {
    test('deve salvar e listar chamados ativos com status "ativo" e "aberto"', () async {
      final chamados = [
        ChamadoModel(
          id: 1,
          codigoCliente: 'CLI-001',
          nomeCliente: 'Ana Silva',
          categoriaInformada: 'Lentidão',
          descricaoProblema: 'Sem velocidade',
          enderecoCliente: 'Rua das Flores, 123',
          bairro: 'Centro',
          cidade: 'Florianópolis',
          latitude: -27.595,
          longitude: -48.548,
          status: 'ativo',
          criadoEm: '2026-10-10 10:00:00',
        ),
        ChamadoModel(
          id: 2,
          codigoCliente: 'CLI-002',
          nomeCliente: 'Bruno Lima',
          categoriaInformada: 'Queda de Conexão',
          descricaoProblema: 'Fibra partida',
          enderecoCliente: 'Rua Principal, 456',
          bairro: 'Trindade',
          cidade: 'Florianópolis',
          latitude: -27.600,
          longitude: -48.520,
          status: 'aberto',
          criadoEm: '2026-10-10 10:30:00',
        ),
      ];

      await dbHelper.salvarChamados(chamados);

      final ativos = await dbHelper.getChamadosAtivos();
      expect(ativos.length, equals(2));
      expect(ativos.first.id, equals(1));
      expect(ativos.last.id, equals(2));
    });

    test('deve registrar atendimento offline, marcar chamado como "atendido" e gravar sincronizado = 0 (RF12)', () async {
      final chamado = ChamadoModel(
        id: 5,
        codigoCliente: 'CLI-005',
        nomeCliente: 'Carla Dias',
        categoriaInformada: 'Sem Sinal',
        descricaoProblema: 'Luz vermelha piscando',
        enderecoCliente: 'Av. Brasil, 789',
        bairro: 'Itacorubi',
        cidade: 'Florianópolis',
        latitude: -27.580,
        longitude: -48.500,
        status: 'ativo',
        criadoEm: '2026-10-10 11:00:00',
      );
      await dbHelper.salvarChamados([chamado]);

      final atendimento = AtendimentoModel(
        chamadoId: 5,
        categoriaTecnico: 'Conector Fast APC Danificado',
        descricaoProcedimento: 'Refeita conectorização com sucesso.',
        dataResolucao: '2026-10-10 12:00:00',
        fotoCaminhoLocal: '/app/docs/foto5.jpg',
        sincronizado: false,
      );

      final idGerado = await dbHelper.inserirAtendimento(atendimento);
      expect(idGerado, greaterThan(0));

      // 1. O chamado não deve mais aparecer na lista de ativos da Home
      final ativos = await dbHelper.getChamadosAtivos();
      expect(ativos.any((c) => c.id == 5), isFalse);

      // 2. O status do chamado deve estar como "atendido"
      final chamadoAtualizado = await dbHelper.getChamadoPorId(5);
      expect(chamadoAtualizado?.status, equals('atendido'));

      // 3. O atendimento deve constar na fila de pendentes (sincronizado = 0)
      final pendentes = await dbHelper.getAtendimentosPendentes();
      expect(pendentes.length, equals(1));
      expect(pendentes.first.chamadoId, equals(5));
      expect(pendentes.first.sincronizado, isFalse);
    });

    test('deve atualizar atendimento para sincronizado = 1 com ID e URL remotos (RF13)', () async {
      final atendimento = AtendimentoModel(
        chamadoId: 10,
        categoriaTecnico: 'Troca de Roteador',
        descricaoProcedimento: 'Instalado roteador dual band Gigabit.',
        dataResolucao: '2026-10-10 14:00:00',
        sincronizado: false,
      );

      final idLocal = await db.insert(
        DatabaseHelper.tabelaAtendimentos,
        atendimento.toMap(),
      );

      // Marca como sincronizado após sucesso na API
      await dbHelper.marcarAtendimentoSincronizado(
        idLocal: idLocal,
        remoteAtendimentoId: 88,
        fotoUrlRemota: 'https://api.exemplo.com/uploads/foto88.jpg',
      );

      final pendentes = await dbHelper.getAtendimentosPendentes();
      expect(pendentes, isEmpty);

      final historico = await dbHelper.getHistoricoAtendimentos();
      expect(historico.first.sincronizado, isTrue);
      expect(historico.first.remoteAtendimentoId, equals(88));
      expect(historico.first.fotoUrlRemota, equals('https://api.exemplo.com/uploads/foto88.jpg'));
    });
  });
}
