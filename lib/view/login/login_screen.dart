// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewModel/auth_view_model.dart';
import '../../viewModel/chamados_view_model.dart';
import '../../viewModel/sync_view_model.dart';

/// Tela 02: Login Seguro com HMAC-SHA256 e Carga Inicial no SQLite (RF03, RF04)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'joaogarcia.dl@gmail.com');
  final _senhaController = TextEditingController();
  bool _senhaOculta = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _efetuarLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final chamadosVm = Provider.of<ChamadosViewModel>(context, listen: false);
    final syncVm = Provider.of<SyncViewModel>(context, listen: false);

    final sucesso = await authVm.login(
      email: _emailController.text,
      senhaPlana: _senhaController.text,
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autenticado com sucesso! Carregando ordens de serviço...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Carga inicial dos chamados da API para o SQLite (RF04)
      await chamadosVm.sincronizarComApi();
      await syncVm.atualizarContagemPendentes();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final erro = authVm.mensagemErro ?? 'Falha ao conectar com o servidor.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo do Aplicativo
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'ISP Telecom Conecta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Autenticação de Técnico de Campo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Card com os campos de login
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Acesso Institucional',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF003366),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Campo de E-mail
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'E-mail institucional',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (valor) {
                              if (valor == null || valor.trim().isEmpty) {
                                return 'Informe o e-mail.';
                              }
                              if (!valor.contains('@') || !valor.contains('.')) {
                                return 'E-mail em formato inválido.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo de Senha
                          TextFormField(
                            controller: _senhaController,
                            obscureText: _senhaOculta,
                            decoration: InputDecoration(
                              labelText: 'Senha de acesso',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _senhaOculta ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _senhaOculta = !_senhaOculta;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (valor) {
                              if (valor == null || valor.isEmpty) {
                                return 'Informe a senha.';
                              }
                              if (valor.length < 4) {
                                return 'A senha deve conter no mínimo 4 caracteres.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Alerta sobre a segurança HMAC
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.security, color: Colors.blue.shade800, size: 18),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Senha protegida localmente com HMAC-SHA256.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF003366),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Botão de Login
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004587),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              onPressed: authVm.status == AuthStatus.carregando
                                  ? null
                                  : _efetuarLogin,
                              child: authVm.status == AuthStatus.carregando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'ENTRAR NO SISTEMA',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'SENAI - Curso de Desenvolvimento Android com Flutter\nProf. Rafael Aguiar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
