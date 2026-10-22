import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../utils/constants.dart'; // Aponta de forma relativa para a pasta utils externa
import 'package:scteccom_app/data/models/usuario_model.dart';

/// Datasource de persistência criptografada em flutter_secure_storage (RF02, RF04)
class SecureStorageDatasource {
  final FlutterSecureStorage _storage;

  SecureStorageDatasource({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Salva o Bearer Token retornado no login
  Future<void> salvarToken(String token) async {
    await _storage.write(key: AppConstants.keyToken, value: token);
  }

  /// Recupera o token de autenticação
  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.keyToken);
  }

  /// Salva os dados do usuário autenticado
  Future<void> salvarUsuario(UsuarioModel usuario) async {
    await _storage.write(
      key: AppConstants.keyUserId,
      value: usuario.id.toString(),
    );
    await _storage.write(
      key: AppConstants.keyUserName,
      value: usuario.nome,
    );
    await _storage.write(
      key: AppConstants.keyUserEmail,
      value: usuario.email,
    );
  }

  /// Recupera os dados do usuário do armazenamento seguro
  Future<UsuarioModel?> getUsuario() async {
    final idStr = await _storage.read(key: AppConstants.keyUserId);
    final nome = await _storage.read(key: AppConstants.keyUserName);
    final email = await _storage.read(key: AppConstants.keyUserEmail);

    if (idStr != null && nome != null && email != null) {
      final id = int.tryParse(idStr) ?? 0;
      return UsuarioModel(id: id, nome: nome, email: email);
    }
    return null;
  }

  /// Verifica se existe sessão válida salva (RF02)
  Future<bool> temSessaoAtiva() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }

  /// Limpa as credenciais salvas no dispositivo
  Future<void> limparSessao() async {
    await _storage.delete(key: AppConstants.keyToken);
    await _storage.delete(key: AppConstants.keyUserId);
    await _storage.delete(key: AppConstants.keyUserName);
    await _storage.delete(key: AppConstants.keyUserEmail);
  }
}
