import 'package:flutter_test/flutter_test.dart';
import 'package:scteccom_app/data/models/atendimento_model.dart';
import 'package:scteccom_app/data/models/chamado_model.dart';
import 'package:scteccom_app/data/models/usuario_model.dart';

void main() {
  group('Modelos Fortemente Tipados e Mapeamento Local/Remoto (RF01)', () {
    test('UsuarioModel - conversão JSON e SQLite com encapsulamento', () {
      final json = {
        'id': 1,
        'nome': 'João Garcia',
        'email': 'joao@senai.br',
      };

      final usuario = UsuarioModel.fromJson(json);

      expect(usuario.id, equals(1));
      expect(usuario.nome, equals('João Garcia'));
      expect(usuario.email, equals('joao@senai.br'));

      final jsonGerado = usuario.toJson();
      expect(jsonGerado['id'], equals(1));
      expect(jsonGerado['nome'], equals('João Garcia'));

      final map = usuario.toMap();
      final usuarioDoBanco = UsuarioModel.fromMap(map);
      expect(usuarioDoBanco, equals(usuario));
      expect(usuarioDoBanco.hashCode, equals(usuario.hashCode));
    });

    test('ChamadoModel - fromJson, toMap, fromMap, copyWith e enderecoCompleto', () {
      final json = {
        'id': 10,
        'codigo_cliente': 'CLI-1234',
        'nome_cliente': 'Carlos Souza',
        'categoria_informada': 'Sem Conexão',
        'descricao_problema': 'LOS piscando vermelho na ONU',
        'endereco_cliente': 'Av. Beira Mar, 1000',
        'bairro': 'Centro',
        'cidade': 'Florianópolis',
        'latitude': -27.5954,
        'longitude': -48.5480,
        'status': 'ativo',
        'criado_em': '2026-10-10 10:00:00',
      };

      final chamado = ChamadoModel.fromJson(json);

      expect(chamado.id, equals(10));
      expect(chamado.codigoCliente, equals('CLI-1234'));
      expect(chamado.latitude, equals(-27.5954));
      expect(
        chamado.enderecoCompleto,
        equals('Av. Beira Mar, 1000 - Centro, Florianópolis'),
      );

      // Testa toMap e fromMap para SQLite
      final map = chamado.toMap();
      final doBanco = ChamadoModel.fromMap(map);
      expect(doBanco.id, equals(chamado.id));
      expect(doBanco.nomeCliente, equals('Carlos Souza'));

      // Testa copyWith
      final comDistancia = chamado.copyWith(distanciaKm: 4.5, status: 'atendido');
      expect(comDistancia.distanciaKm, equals(4.5));
      expect(comDistancia.status, equals('atendido'));
      expect(comDistancia.id, equals(chamado.id));
    });

    test('AtendimentoModel - fromJson, toMap, fromMap e copyWith', () {
      final atendimento = AtendimentoModel(
        id: 1,
        chamadoId: 10,
        categoriaTecnico: 'Conector Fast APC Danificado',
        descricaoProcedimento: 'Troca de conector e teste de atenuação em -19.5 dBm',
        dataResolucao: '2026-10-10 11:30:00',
        fotoCaminhoLocal: '/storage/fotos/atend_10.jpg',
        sincronizado: false,
        codigoCliente: 'CLI-1234',
        nomeCliente: 'Carlos Souza',
      );

      expect(atendimento.id, equals(1));
      expect(atendimento.chamadoId, equals(10));
      expect(atendimento.sincronizado, isFalse);
      expect(atendimento.fotoCaminhoLocal, equals('/storage/fotos/atend_10.jpg'));

      // Teste de mapeamento SQLite (toMap / fromMap)
      final map = atendimento.toMap();
      expect(map['sincronizado'], equals(0)); // SQLite INTEGER (0 ou 1)

      final doBanco = AtendimentoModel.fromMap(map);
      expect(doBanco.sincronizado, isFalse);
      expect(doBanco.categoriaTecnico, equals('Conector Fast APC Danificado'));

      // Teste de copyWith marcando como sincronizado
      final sincronizado = atendimento.copyWith(
        sincronizado: true,
        fotoUrlRemota: 'https://exemplo.com/foto.jpg',
        remoteAtendimentoId: 99,
      );
      expect(sincronizado.sincronizado, isTrue);
      expect(sincronizado.remoteAtendimentoId, equals(99));
    });
  });
}
