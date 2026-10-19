
/// Modelo  para Atendimentos / Pareceres Técnicos (RF01)
class AtendimentoModel {
  final int? _id; // ID local autoincrement do SQLite
  final int _chamadoId;
  final String _categoriaTecnico;
  final String _descricaoProcedimento;
  final String _dataResolucao;
  final String? _fotoCaminhoLocal;
  final String? _fotoUrlRemota;
  final bool _sincronizado;
  final int? _remoteAtendimentoId;
  final String? _registradoEm;

  // Dados auxiliares do chamado para facilitar exibição no histórico
  final String? _codigoCliente;
  final String? _nomeCliente;
  final String? _enderecoCliente;

  AtendimentoModel({
    int? id,
    required int chamadoId,
    required String categoriaTecnico,
    required String descricaoProcedimento,
    required String dataResolucao,
    String? fotoCaminhoLocal,
    String? fotoUrlRemota,
    bool sincronizado = false,
    int? remoteAtendimentoId,
    String? registradoEm,
    String? codigoCliente,
    String? nomeCliente,
    String? enderecoCliente,
  })  : _id = id,
        _chamadoId = chamadoId,
        _categoriaTecnico = categoriaTecnico,
        _descricaoProcedimento = descricaoProcedimento,
        _dataResolucao = dataResolucao,
        _fotoCaminhoLocal = fotoCaminhoLocal,
        _fotoUrlRemota = fotoUrlRemota,
        _sincronizado = sincronizado,
        _remoteAtendimentoId = remoteAtendimentoId,
        _registradoEm = registradoEm,
        _codigoCliente = codigoCliente,
        _nomeCliente = nomeCliente,
        _enderecoCliente = enderecoCliente;

  // Getters para encapsulamento
  int? get id => _id;
  int get chamadoId => _chamadoId;
  String get categoriaTecnico => _categoriaTecnico;
  String get descricaoProcedimento => _descricaoProcedimento;
  String get dataResolucao => _dataResolucao;
  String? get fotoCaminhoLocal => _fotoCaminhoLocal;
  String? get fotoUrlRemota => _fotoUrlRemota;
  bool get sincronizado => _sincronizado;
  int? get remoteAtendimentoId => _remoteAtendimentoId;
  String? get registradoEm => _registradoEm;
  String? get codigoCliente => _codigoCliente;
  String? get nomeCliente => _nomeCliente;
  String? get enderecoCliente => _enderecoCliente;

  /// Cria uma cópia com campos atualizados (ex: após sincronizar com a API)
  AtendimentoModel copyWith({
    int? id,
    int? chamadoId,
    String? categoriaTecnico,
    String? descricaoProcedimento,
    String? dataResolucao,
    String? fotoCaminhoLocal,
    String? fotoUrlRemota,
    bool? sincronizado,
    int? remoteAtendimentoId,
    String? registradoEm,
    String? codigoCliente,
    String? nomeCliente,
    String? enderecoCliente,
  }) {
    return AtendimentoModel(
      id: id ?? _id,
      chamadoId: chamadoId ?? _chamadoId,
      categoriaTecnico: categoriaTecnico ?? _categoriaTecnico,
      descricaoProcedimento: descricaoProcedimento ?? _descricaoProcedimento,
      dataResolucao: dataResolucao ?? _dataResolucao,
      fotoCaminhoLocal: fotoCaminhoLocal ?? _fotoCaminhoLocal,
      fotoUrlRemota: fotoUrlRemota ?? _fotoUrlRemota,
      sincronizado: sincronizado ?? _sincronizado,
      remoteAtendimentoId: remoteAtendimentoId ?? _remoteAtendimentoId,
      registradoEm: registradoEm ?? _registradoEm,
      codigoCliente: codigoCliente ?? _codigoCliente,
      nomeCliente: nomeCliente ?? _nomeCliente,
      enderecoCliente: enderecoCliente ?? _enderecoCliente,
    );
  }

  /// Converte a partir do formato da API (/api/historico ou resposta de /api/atendimento)
  factory AtendimentoModel.fromJson(Map<String, dynamic> json) {
    // Pode vir assim como nó aninhado em /api/historico ou diretamente da resposta de criação
    final atendimentoData = json['atendimento'] is Map<String, dynamic>
        ? json['atendimento'] as Map<String, dynamic>
        : json;

    return AtendimentoModel(
      chamadoId: json['chamado_id'] is int
          ? json['chamado_id'] as int
          : (atendimentoData['chamado_id'] is int
              ? atendimentoData['chamado_id'] as int
              : int.tryParse(json['chamado_id']?.toString() ?? '') ?? 0),
      categoriaTecnico: (atendimentoData['categoria_tecnico'] ?? '').toString(),
      descricaoProcedimento: (atendimentoData['descricao_procedimento'] ?? '').toString(),
      dataResolucao: (atendimentoData['data_resolucao'] ?? '').toString(),
      fotoUrlRemota: atendimentoData['foto_url']?.toString(),
      sincronizado: true,
      remoteAtendimentoId: atendimentoData['id'] is int
          ? atendimentoData['id'] as int
          : (atendimentoData['atendimento_id'] is int
              ? atendimentoData['atendimento_id'] as int
              : int.tryParse(atendimentoData['id']?.toString() ?? '')),
      registradoEm: (atendimentoData['registrado_em'] ?? '').toString(),
      codigoCliente: json['codigo_cliente']?.toString(),
      nomeCliente: json['nome_cliente']?.toString(),
      enderecoCliente: json['endereco_cliente']?.toString(),
    );
  }

  /// Converte para JSON para envio ou exportação
  Map<String, dynamic> toJson() {
    return {
      'chamado_id': _chamadoId,
      'categoria_tecnico': _categoriaTecnico,
      'descricao_procedimento': _descricaoProcedimento,
      'data_resolucao': _dataResolucao,
      'foto_url': _fotoUrlRemota,
    };
  }

  /// Mapeamento para inserção no sqflite-local
  Map<String, dynamic> toMap() {
    return {
      if (_id != null) 'id': _id,
      'chamado_id': _chamadoId,
      'categoria_tecnico': _categoriaTecnico,
      'descricao_procedimento': _descricaoProcedimento,
      'data_resolucao': _dataResolucao,
      'foto_caminho_local': _fotoCaminhoLocal,
      'foto_url_remota': _fotoUrlRemota,
      'sincronizado': _sincronizado ? 1 : 0,
      'remote_atendimento_id': _remoteAtendimentoId,
      'registrado_em': _registradoEm,
    };
  }

  /// Reconstrução a partir do banco de dados local SQLite
  factory AtendimentoModel.fromMap(Map<String, dynamic> map) {
    return AtendimentoModel(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString()),
      chamadoId: map['chamado_id'] is int
          ? map['chamado_id'] as int
          : int.tryParse(map['chamado_id'].toString()) ?? 0,
      categoriaTecnico: (map['categoria_tecnico'] ?? '').toString(),
      descricaoProcedimento: (map['descricao_procedimento'] ?? '').toString(),
      dataResolucao: (map['data_resolucao'] ?? '').toString(),
      fotoCaminhoLocal: map['foto_caminho_local']?.toString(),
      fotoUrlRemota: map['foto_url_remota']?.toString(),
      sincronizado: (map['sincronizado'] == 1 || map['sincronizado'] == true),
      remoteAtendimentoId: map['remote_atendimento_id'] is int
          ? map['remote_atendimento_id'] as int
          : int.tryParse(map['remote_atendimento_id']?.toString() ?? ''),
      registradoEm: map['registrado_em']?.toString(),
      codigoCliente: map['codigo_cliente']?.toString(),
      nomeCliente: map['nome_cliente']?.toString(),
      enderecoCliente: map['endereco_cliente']?.toString(),
    );
  }

  @override
  String toString() =>
      'AtendimentoModel(id: $_id, chamadoId: $_chamadoId, sinc: $_sincronizado, foto: $_fotoCaminhoLocal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtendimentoModel &&
          runtimeType == other.runtimeType &&
          _chamadoId == other._chamadoId &&
          _id == other._id;

  @override
  int get hashCode => (_id ?? 0).hashCode ^ _chamadoId.hashCode;
}
