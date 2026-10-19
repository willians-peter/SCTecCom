import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:projeto_telecom/data/models/atendimento_model.dart';
import 'package:projeto_telecom/data/models/chamado_model.dart';

/// Camada de persistência local SQLite embarcada (RF05)
class DatabaseHelper {
  static const String _databaseName = 'isp_telecom.db';
  static const int _databaseVersion = 1;

  static const String tabelaChamados = 'chamados';
  static const String tabelaAtendimentos = 'atendimentos';

  static DatabaseHelper? _instance;
  Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// Construtor para testes unitários com Database customizada
  DatabaseHelper.comDatabase(Database db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de chamados atribuídos ao técnico
    await db.execute('''
      CREATE TABLE $tabelaChamados (
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

    // Tabela de atendimentos/resoluções locais
    await db.execute('''
      CREATE TABLE $tabelaAtendimentos (
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
        FOREIGN KEY (chamado_id) REFERENCES $tabelaChamados (id)
      )
    ''');
  }

  // ==================== OPERAÇÕES DE CHAMADOS ====================

  /// Salva ou atualiza a lista de chamados recebidos da API (Carga Inicial / Sincronização)
  Future<void> salvarChamados(List<ChamadoModel> chamados) async {
    final db = await database;
    final batch = db.batch();

    for (final chamado in chamados) {
      batch.insert(
        tabelaChamados,
        chamado.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Busca todos os chamados com status ativo/aberto no SQLite local (RF06)
  Future<List<ChamadoModel>> getChamadosAtivos() async {
    final db = await database;
    final resultado = await db.query(
      tabelaChamados,
      where: 'status = ? OR status = ?',
      whereArgs: ['ativo', 'aberto'],
      orderBy: 'id ASC',
    );

    return resultado.map((map) => ChamadoModel.fromMap(map)).toList();
  }

  /// Busca um chamado pelo ID
  Future<ChamadoModel?> getChamadoPorId(int id) async {
    final db = await database;
    final resultado = await db.query(
      tabelaChamados,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isNotEmpty) {
      return ChamadoModel.fromMap(resultado.first);
    }
    return null;
  }

  /// Atualiza o status do chamado no SQLite local (RF12)
  Future<int> atualizarStatusChamado(int id, String novoStatus) async {
    final db = await database;
    return await db.update(
      tabelaChamados,
      {'status': novoStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== OPERAÇÕES DE ATENDIMENTOS ====================

  /// Registra o parecer técnico concluído no SQLite local com sincronizado = 0 (RF12)
  Future<int> inserirAtendimento(AtendimentoModel atendimento) async {
    final db = await database;
    return await db.transaction((txn) async {
      final idAtendimento = await txn.insert(
        tabelaAtendimentos,
        atendimento.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Atualiza o chamado correspondente para 'atendido'
      await txn.update(
        tabelaChamados,
        {'status': 'atendido'},
        where: 'id = ?',
        whereArgs: [atendimento.chamadoId],
      );

      return idAtendimento;
    });
  }

  /// Retorna os atendimentos pendentes de envio (sincronizado = 0) (RF13)
  Future<List<AtendimentoModel>> getAtendimentosPendentes() async {
    final db = await database;
    final resultado = await db.query(
      tabelaAtendimentos,
      where: 'sincronizado = ?',
      whereArgs: [0],
    );

    return resultado.map((map) => AtendimentoModel.fromMap(map)).toList();
  }

  /// Atualiza o atendimento local para sincronizado = 1 após retorno 201/200 da API (RF13)
  Future<int> marcarAtendimentoSincronizado({
    required int idLocal,
    int? remoteAtendimentoId,
    String? fotoUrlRemota,
  }) async {
    final db = await database;
    final values = <String, dynamic>{
      'sincronizado': 1,
    };
    if (remoteAtendimentoId != null) {
      values['remote_atendimento_id'] = remoteAtendimentoId;
    }
    if (fotoUrlRemota != null) {
      values['foto_url_remota'] = fotoUrlRemota;
    }

    return await db.update(
      tabelaAtendimentos,
      values,
      where: 'id = ?',
      whereArgs: [idLocal],
    );
  }

  /// Lista todos os atendimentos locais com informações do chamado acopladas (RF14)
  Future<List<AtendimentoModel>> getHistoricoAtendimentos() async {
    final db = await database;
    final sql = '''
      SELECT 
        a.id,
        a.chamado_id,
        a.categoria_tecnico,
        a.descricao_procedimento,
        a.data_resolucao,
        a.foto_caminho_local,
        a.foto_url_remota,
        a.sincronizado,
        a.remote_atendimento_id,
        a.registrado_em,
        c.codigo_cliente,
        c.nome_cliente,
        c.endereco_cliente
      FROM $tabelaAtendimentos a
      LEFT JOIN $tabelaChamados c ON a.chamado_id = c.id
      ORDER BY a.id DESC
    ''';

    final resultado = await db.rawQuery(sql);
    return resultado.map((map) => AtendimentoModel.fromMap(map)).toList();
  }

  /// Limpa todas as tabelas (usado no logout)
  Future<void> limparBanco() async {
    final db = await database;
    await db.delete(tabelaAtendimentos);
    await db.delete(tabelaChamados);
  }
}
