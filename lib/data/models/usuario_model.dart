
/// Modelo fortemente tipado para o Usuário Técnico autenticado (RF01)
class UsuarioModel {
  final int _id;
  final String _nome;
  final String _email;

  UsuarioModel({
    required int id,
    required String nome,
    required String email,
  })  : _id = id,
        _nome = nome,
        _email = email;

  // Getters para encapsulamento
  int get id => _id;
  String get nome => _nome;
  String get email => _email;

  /// Conversão a partir do JSON retornado pela API REST
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      nome: (json['nome'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }

  /// Conversão para JSON para envio ou serialização
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'nome': _nome,
      'email': _email,
    };
  }

  /// Mapeamento para persistência no SQLite (sqflite)
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'nome': _nome,
      'email': _email,
    };
  }

  /// Reconstrução a partir do banco de dados local SQLite
  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString()) ?? 0,
      nome: (map['nome'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
    );
  }

  @override
  String toString() => 'UsuarioModel(id: $_id, nome: $_nome, email: $_email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioModel &&
          runtimeType == other.runtimeType &&
          _id == other._id &&
          _email == other._email;

  @override
  int get hashCode => _id.hashCode ^ _email.hashCode;
}
