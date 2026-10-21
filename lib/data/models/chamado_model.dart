// ignore_for_file: prefer_initializing_formals
/// Modelo  para Chamados / Ordens de Serviço (RF01)
class ChamadoModel {
  final int _id;
  final String _codigoCliente;
  final String _nomeCliente;
  final String _categoriaInformada;
  final String _descricaoProblema;
  final String _enderecoCliente;
  final String _bairro;
  final String _cidade;
  final double _latitude;
  final double _longitude;
  final String _status;
  final String _criadoEm;
  final double? _distanciaKm;

  ChamadoModel({
    required int id,
    required String codigoCliente,
    required String nomeCliente,
    required String categoriaInformada,
    required String descricaoProblema,
    required String enderecoCliente,
    required String bairro,
    required String cidade,
    required double latitude,
    required double longitude,
    required String status,
    required String criadoEm,
    double? distanciaKm,
  })  : _id = id,
        _codigoCliente = codigoCliente,
        _nomeCliente = nomeCliente,
        _categoriaInformada = categoriaInformada,
        _descricaoProblema = descricaoProblema,
        _enderecoCliente = enderecoCliente,
        _bairro = bairro,
        _cidade = cidade,
        _latitude = latitude,
        _longitude = longitude,
        _status = status,
        _criadoEm = criadoEm,
        _distanciaKm = distanciaKm;

  // Getters para encapsulamento
  int get id => _id;
  String get codigoCliente => _codigoCliente;
  String get nomeCliente => _nomeCliente;
  String get categoriaInformada => _categoriaInformada;
  String get descricaoProblema => _descricaoProblema;
  String get enderecoCliente => _enderecoCliente;
  String get bairro => _bairro;
  String get cidade => _cidade;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get status => _status;
  String get criadoEm => _criadoEm;
  double? get distanciaKm => _distanciaKm;

  String get enderecoCompleto =>
      '$_enderecoCliente${_bairro.isNotEmpty ? ' - $_bairro' : ''}${_cidade.isNotEmpty ? ', $_cidade' : ''}';

  /// Cria uma cópia com campos atualizados - recalculando distância ou status
  ChamadoModel copyWith({
    int? id,
    String? codigoCliente,
    String? nomeCliente,
    String? categoriaInformada,
    String? descricaoProblema,
    String? enderecoCliente,
    String? bairro,
    String? cidade,
    double? latitude,
    double? longitude,
    String? status,
    String? criadoEm,
    double? distanciaKm,
  }) {
    return ChamadoModel(
      id: id ?? _id,
      codigoCliente: codigoCliente ?? _codigoCliente,
      nomeCliente: nomeCliente ?? _nomeCliente,
      categoriaInformada: categoriaInformada ?? _categoriaInformada,
      descricaoProblema: descricaoProblema ?? _descricaoProblema,
      enderecoCliente: enderecoCliente ?? _enderecoCliente,
      bairro: bairro ?? _bairro,
      cidade: cidade ?? _cidade,
      latitude: latitude ?? _latitude,
      longitude: longitude ?? _longitude,
      status: status ?? _status,
      criadoEm: criadoEm ?? _criadoEm,
      distanciaKm: distanciaKm ?? _distanciaKm,
    );
  }

  /// Constrói o modelo a partir do JSON da api
  factory ChamadoModel.fromJson(Map<String, dynamic> json) {
    return ChamadoModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      codigoCliente: (json['codigo_cliente'] ?? '').toString(),
      nomeCliente: (json['nome_cliente'] ?? '').toString(),
      categoriaInformada: (json['categoria_informada'] ?? '').toString(),
      descricaoProblema: (json['descricao_problema'] ?? '').toString(),
      enderecoCliente: (json['endereco_cliente'] ?? '').toString(),
      bairro: (json['bairro'] ?? '').toString(),
      cidade: (json['cidade'] ?? '').toString(),
      latitude: (json['latitude'] != null)
          ? double.tryParse(json['latitude'].toString()) ?? 0.0
          : 0.0,
      longitude: (json['longitude'] != null)
          ? double.tryParse(json['longitude'].toString()) ?? 0.0
          : 0.0,
      status: (json['status'] ?? 'ativo').toString(),
      criadoEm: (json['criado_em'] ?? '').toString(),
    );
  }

  /// Converte  JSON
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'codigo_cliente': _codigoCliente,
      'nome_cliente': _nomeCliente,
      'categoria_informada': _categoriaInformada,
      'descricao_problema': _descricaoProblema,
      'endereco_cliente': _enderecoCliente,
      'bairro': _bairro,
      'cidade': _cidade,
      'latitude': _latitude,
      'longitude': _longitude,
      'status': _status,
      'criado_em': _criadoEm,
    };
  }

  /// Mapeamento para inserção e atualização no SQLite local
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'codigo_cliente': _codigoCliente,
      'nome_cliente': _nomeCliente,
      'categoria_informada': _categoriaInformada,
      'descricao_problema': _descricaoProblema,
      'endereco_cliente': _enderecoCliente,
      'bairro': _bairro,
      'cidade': _cidade,
      'latitude': _latitude,
      'longitude': _longitude,
      'status': _status,
      'criado_em': _criadoEm,
    };
  }

  /// Reconstrução a partir de registro do sqlite local
  factory ChamadoModel.fromMap(Map<String, dynamic> map) {
    return ChamadoModel(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString()) ?? 0,
      codigoCliente: (map['codigo_cliente'] ?? '').toString(),
      nomeCliente: (map['nome_cliente'] ?? '').toString(),
      categoriaInformada: (map['categoria_informada'] ?? '').toString(),
      descricaoProblema: (map['descricao_problema'] ?? '').toString(),
      enderecoCliente: (map['endereco_cliente'] ?? '').toString(),
      bairro: (map['bairro'] ?? '').toString(),
      cidade: (map['cidade'] ?? '').toString(),
      latitude: (map['latitude'] != null)
          ? double.tryParse(map['latitude'].toString()) ?? 0.0
          : 0.0,
      longitude: (map['longitude'] != null)
          ? double.tryParse(map['longitude'].toString()) ?? 0.0
          : 0.0,
      status: (map['status'] ?? 'ativo').toString(),
      criadoEm: (map['criado_em'] ?? '').toString(),
    );
  }

  @override
  String toString() =>
      'ChamadoModel(id: $_id, codigo: $_codigoCliente, cliente: $_nomeCliente, status: $_status, dist: $_distanciaKm km)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChamadoModel && runtimeType == other.runtimeType && _id == other._id;

  @override
  int get hashCode => _id.hashCode;
}
