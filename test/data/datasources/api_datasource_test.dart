import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:scteccom_app/data/datasources/remote/api_datasource.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late ApiDatasource apiDatasource;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(http.Request('POST', Uri.parse('https://example.com')));
  });

  setUp(() {
    mockClient = MockHttpClient();
    apiDatasource = ApiDatasource(client: mockClient);
  });

  group('ApiDatasource - Consumo da API REST (RF03, RF04, RF13, RF14)', () {
    test('login com sucesso deve retornar token e usuario (200 OK)', () async {
      final respostaJson = {
        'sucesso': true,
        'mensagem': 'Login efetuado com sucesso!',
        'dados': {
          'token': 'bearer_token_xyz_123',
          'usuario': {
            'id': 1,
            'nome': 'João Garcia',
            'email': 'joaogarcia.dl@gmail.com',
          }
        }
      };

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(respostaJson), 200));

      final resultado = await apiDatasource.login(
        email: 'joaogarcia.dl@gmail.com',
        senhaHmac: 'hash_hmac_sha256',
      );

      expect(resultado['token'], equals('bearer_token_xyz_123'));
      expect(resultado['usuario'].id, equals(1));
      expect(resultado['usuario'].nome, equals('João Garcia'));
    });

    test('login com falha de credenciais deve lançar HttpException (401)', () async {
      final respostaErro = {
        'sucesso': false,
        'mensagem': 'Credenciais inválidas. O hash HMAC-SHA256 da senha não confere.',
      };

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(respostaErro), 401));

      expect(
        () => apiDatasource.login(
          email: 'invalido@senai.br',
          senhaHmac: 'hash_errado',
        ),
        throwsA(isA<HttpException>()),
      );
    });

    test('getChamadosAtivos deve retornar lista de chamados (200 OK)', () async {
      final respostaJson = {
        'sucesso': true,
        'mensagem': 'Chamados ativos recuperados com sucesso.',
        'total': 1,
        'dados': [
          {
            'id': 10,
            'codigo_cliente': 'CLI-100',
            'nome_cliente': 'Marcos Lima',
            'categoria_informada': 'Rompimento de Fibra',
            'descricao_problema': 'Cabo rompido na fachada',
            'endereco_cliente': 'Rua Bocaiúva, 200',
            'bairro': 'Centro',
            'cidade': 'Florianópolis',
            'latitude': -27.590,
            'longitude': -48.550,
            'status': 'ativo',
            'criado_em': '2026-10-10 09:00:00',
          }
        ]
      };

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(respostaJson), 200));

      final lista = await apiDatasource.getChamadosAtivos('token_valido');

      expect(lista.length, equals(1));
      expect(lista.first.id, equals(10));
      expect(lista.first.codigoCliente, equals('CLI-100'));
    });
  });
}
