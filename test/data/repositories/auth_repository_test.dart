import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scteccom_app/data/datasources/remote/api_datasource.dart';
import 'package:scteccom_app/data/datasources/remote/secure_storage_datasource.dart';
import 'package:scteccom_app/data/models/usuario_model.dart';
import 'package:scteccom_app/data/repositories/auth_repository.dart';

class MockApiDatasource extends Mock implements ApiDatasource {}
class MockSecureStorageDatasource extends Mock implements SecureStorageDatasource {}

void main() {
  late MockApiDatasource mockApiDatasource;
  late MockSecureStorageDatasource mockSecureStorage;
  late AuthRepository authRepository;

  setUp(() {
    mockApiDatasource = MockApiDatasource();
    mockSecureStorage = MockSecureStorageDatasource();
    authRepository = AuthRepository(
      apiDatasource: mockApiDatasource,
      secureStorage: mockSecureStorage,
    );
  });

  group('AuthRepository - Autenticação e Sessão (RF02, RF03, RF04)', () {
    test('login deve assinar senha com HMAC-SHA256 e persistir token e usuário', () async {
      final usuarioEsperado = UsuarioModel(
        id: 1,
        nome: 'Técnico Silva',
        email: 'tecnico@senai.br',
      );

      when(() => mockApiDatasource.login(
            email: 'tecnico@senai.br',
            senhaHmac: any(named: 'senhaHmac'),
          )).thenAnswer((_) async => {
            'token': 'bearer_token_123',
            'usuario': usuarioEsperado,
          });

      when(() => mockSecureStorage.salvarToken('bearer_token_123'))
          .thenAnswer((_) async {});
      when(() => mockSecureStorage.salvarUsuario(usuarioEsperado))
          .thenAnswer((_) async {});

      final usuario = await authRepository.login(
        email: 'tecnico@senai.br',
        senhaPlana: '123456',
      );

      expect(usuario.id, equals(1));
      expect(usuario.email, equals('tecnico@senai.br'));

      verify(() => mockSecureStorage.salvarToken('bearer_token_123')).called(1);
      verify(() => mockSecureStorage.salvarUsuario(usuarioEsperado)).called(1);
    });

    test('verificarSessaoAtiva deve consultar o armazenamento seguro', () async {
      when(() => mockSecureStorage.temSessaoAtiva())
          .thenAnswer((_) async => true);

      final temSessao = await authRepository.verificarSessaoAtiva();
      expect(temSessao, isTrue);
      verify(() => mockSecureStorage.temSessaoAtiva()).called(1);
    });

    test('logout deve limpar credenciais no armazenamento seguro', () async {
      when(() => mockSecureStorage.limparSessao())
          .thenAnswer((_) async {});

      await authRepository.logout();
      verify(() => mockSecureStorage.limparSessao()).called(1);
    });
  });
}
