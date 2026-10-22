// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewModel/auth_view_model.dart';
import '../../viewModel/chamados_view_model.dart';

/// Tela 01: Splash Screen com Verificação de Sessão / Auto-login (RF02)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSessaoEIniciar();
  }

  Future<void> _verificarSessaoEIniciar() async {
    // Breve pausa para apresentação visual da marca
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final temSessao = await authVm.verificarSessao();

    if (!mounted) return;

    if (temSessao) {
      // Dispara o carregamento dos chamados locais
      final chamadosVm = Provider.of<ChamadosViewModel>(context, listen: false);
      chamadosVm.carregarChamadosLocais(buscarGps: true);

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagem da logo da aplicação (demonstra Image.asset)
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
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
              const SizedBox(height: 28),
              const Text(
                'ISP TELECOM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestão de Atendimentos em Campo',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verificando credenciais seguras...',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
