import '../../utils/crypto_helper.dart'; // Se o seu crypto_helper estiver na pasta lib/utils
import '../datasources/remote/api_datasource.dart';
import '../datasources/remote/secure_storage_datasource.dart';
import '../models/usuario_model.dart';

/// Repositório de Autenticação e Gestão de Sessão (RF02, RF03, RF04)
class AuthRepository {
  final ApiDatasource _apiDatasource;
  final SecureStorageDatasource _secureStorage;

  AuthRepository({
    ApiDatasource? apiDatasource,
    SecureStorageDatasource? secureStorage,
  })  : _apiDatasource = apiDatasource ?? ApiDatasource(),
        _secureStorage = secureStorage ?? SecureStorageDatasource();

  /// Realiza login criptografando a senha com HMAC-SHA256 e salvando a sessão (RF03, RF04)
  Future<UsuarioModel> login({
    required String email,
    required String senhaPlana,
  }) async {
    // 1. Gera o hash HMAC-SHA256 da senha plana utilizando a chave secreta da turma
    // a senha não é enviada em formato original e sim um codigo junto com a senha secreta da turma
    final senhaHmac = CryptoHelper.gerarHmacSha256(senhaPlana);

    // 2. Dispara a requisição para a API
    final resultado = await _apiDatasource.login(
      email: email.trim(),
      senhaHmac: senhaHmac,
    );

    final token = resultado['token'] as String;
    final usuario = resultado['usuario'] as UsuarioModel;

    // 3. Persiste com segurança no flutter_secure_storage
    await _secureStorage.salvarToken(token);
    await _secureStorage.salvarUsuario(usuario);

    return usuario;
  }

  /// Verifica se há um token de autenticação ativo salvo no dispositivo (RF02)
  Future<bool> verificarSessaoAtiva() async {
    return await _secureStorage.temSessaoAtiva();
  }

  /// Recupera o token de autenticação salvo
  Future<String?> getToken() async {
    return await _secureStorage.getToken();
  }

  /// Recupera os dados do usuário autenticado
  Future<UsuarioModel?> getUsuarioLogado() async {
    return await _secureStorage.getUsuario();
  }

  /// Realiza logout limpando os dados de autenticação
  /// apaga o token dos dados salvos localmente removendo a sessão.
  Future<void> logout() async {
    await _secureStorage.limparSessao();
  }
}
