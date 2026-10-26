import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:scteccom_app/utils/constants.dart';
import 'package:scteccom_app/data/models/atendimento_model.dart';
import 'package:scteccom_app/data/models/chamado_model.dart';
import 'package:scteccom_app/data/models/usuario_model.dart';

/// Datasource Remoto para comunicação com a API REST oficial (RF03, RF04, RF13, RF14)
class ApiDatasource {
  final http.Client _client;
  final String _baseUrl;

  ApiDatasource({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  /// Autentica o técnico com e-mail e hash HMAC-SHA256 (RF03)
  /// Retorna um Map com 'token' e o 'usuario' (UsuarioModel)
  Future<Map<String, dynamic>> login({
    required String email,
    required String senhaHmac,
  }) async {
    final url = Uri.parse('$_baseUrl/login');

    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'senha_hmac': senhaHmac,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['sucesso'] == true) {
      final dados = body['dados'] as Map<String, dynamic>;
      final token = dados['token'] as String;
      final usuario = UsuarioModel.fromJson(dados['usuario']);

      return {
        'token': token,
        'usuario': usuario,
      };
    } else {
      final mensagem = body['mensagem'] ?? 'Falha na autenticação';
      throw HttpException(mensagem.toString());
    }
  }

  /// Busca os chamados ativos atribuídos ao técnico na API (RF04)
  Future<List<ChamadoModel>> getChamadosAtivos(String token) async {
    final url = Uri.parse('$_baseUrl/chamados');

    final response = await _client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> listaDados = body['dados'] ?? [];
      return listaDados.map((item) => ChamadoModel.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw const HttpException('Sessão expirada. Faça login novamente.');
    } else {
      final body = jsonDecode(response.body);
      final mensagem = body['mensagem'] ?? 'Erro ao buscar chamados na API';
      throw HttpException(mensagem.toString());
    }
  }

  /// Envia o atendimento técnico concluído via Multipart/Form-Data (RF13)
  Future<Map<String, dynamic>> registrarAtendimento({
    required String token,
    required int chamadoId,
    required String categoriaTecnico,
    required String descricaoProcedimento,
    String? dataResolucao,
    File? fotoArquivo,
  }) async {
    final url = Uri.parse('$_baseUrl/atendimento');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['chamado_id'] = chamadoId.toString();
    request.fields['categoria_tecnico'] = categoriaTecnico;
    request.fields['descricao_procedimento'] = descricaoProcedimento;
    if (dataResolucao != null && dataResolucao.isNotEmpty) {
      request.fields['data_resolucao'] = dataResolucao;
    }

    if (fotoArquivo != null && fotoArquivo.existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto',
          fotoArquivo.path,
        ),
      );
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['dados'] as Map<String, dynamic>? ?? {};
    } else {
      try {
        final body = jsonDecode(response.body);
        final mensagem = body['mensagem'] ?? 'Erro ao registrar atendimento (${response.statusCode})';
        throw HttpException(mensagem.toString());
      } catch (e) {
        if (e is HttpException) rethrow;
        throw HttpException('Erro na requisição: ${response.statusCode}');
      }
    }
  }

  /// Busca o histórico de chamados resolvidos pelo técnico na API (RF14)
  Future<List<AtendimentoModel>> getHistorico(String token) async {
    final url = Uri.parse('$_baseUrl/historico');

    final response = await _client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> lista = body['dados'] ?? [];
      return lista.map((item) => AtendimentoModel.fromJson(item)).toList();
    } else {
      final body = jsonDecode(response.body);
      final mensagem = body['mensagem'] ?? 'Erro ao recuperar histórico';
      throw HttpException(mensagem.toString());
    }
  }
}
