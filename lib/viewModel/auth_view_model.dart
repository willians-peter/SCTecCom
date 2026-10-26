import 'package:flutter/foundation.dart';
import 'package:scteccom_app/data/models/usuario_model.dart';
import 'package:scteccom_app/data/repositories/auth_repository.dart';

enum AuthStatus { inicial, carregando, autenticado, naoAutenticado, erro }

/// ViewModel responsável pelo fluxo de autenticação e sessão segura (RF02, RF03, RF04)
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.inicial;
  UsuarioModel? _usuario;
  String? _mensagemErro;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  AuthStatus get status => _status;
  UsuarioModel? get usuario => _usuario;
  String? get mensagemErro => _mensagemErro;
  bool get estaAutenticado => _status == AuthStatus.autenticado;

  /// Verifica se já existe um token de autenticação salvo (RF02 - Splash Screen)
  Future<bool> verificarSessao() async {
    _status = AuthStatus.carregando;
    notifyListeners();

    try {
      final temSessao = await _authRepository.verificarSessaoAtiva();
      if (temSessao) {
        _usuario = await _authRepository.getUsuarioLogado();
        _status = AuthStatus.autenticado;
        _mensagemErro = null;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.naoAutenticado;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.naoAutenticado;
      _mensagemErro = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Efetua login com assinatura HMAC-SHA256 da senha (RF03, RF04)
  Future<bool> login({
    required String email,
    required String senhaPlana,
  }) async {
    _status = AuthStatus.carregando;
    _mensagemErro = null;
    notifyListeners();

    try {
      _usuario = await _authRepository.login(
        email: email,
        senhaPlana: senhaPlana,
      );
      _status = AuthStatus.autenticado;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.erro;
      _mensagemErro = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Realiza logout do técnico
  Future<void> logout() async {
    await _authRepository.logout();
    _usuario = null;
    _status = AuthStatus.naoAutenticado;
    _mensagemErro = null;
    notifyListeners();
  }
}
