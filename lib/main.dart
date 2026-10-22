import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/models/atendimento_model.dart';
import 'data/models/chamado_model.dart';
import 'view/atendimento/atendimento_screen.dart';
import 'view/historico/historico_detalhe_screen.dart';
import 'view/historico/historico_screen.dart';
import 'view/home/home_screen.dart';
import 'view/login/login_screen.dart';
import 'view/splash/splash_screen.dart';
import 'viewModel/atendimento_view_model.dart';
import 'viewModel/auth_view_model.dart';
import 'viewModel/chamados_view_model.dart';
import 'viewModel/historico_view_model.dart';
import 'viewModel/sync_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
        ChangeNotifierProvider<ChamadosViewModel>(
          create: (_) => ChamadosViewModel(),
        ),
        ChangeNotifierProvider<AtendimentoViewModel>(
          create: (_) => AtendimentoViewModel(),
        ),
        ChangeNotifierProvider<HistoricoViewModel>(
          create: (_) => HistoricoViewModel(),
        ),
        ChangeNotifierProvider<SyncViewModel>(create: (_) => SyncViewModel()),
      ],
      child: MaterialApp(
        title: 'SCTecCom',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF003366),
            primary: const Color(0xFF003366),
            secondary: Colors.teal,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF003366),
            foregroundColor: Colors.white,
            centerTitle: false,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/historico': (context) => const HistoricoScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/atendimento') {
            final chamado = settings.arguments as ChamadoModel;
            return MaterialPageRoute(
              builder: (context) => AtendimentoScreen(chamado: chamado),
            );
          }

          if (settings.name == '/historico_detalhe') {
            final atendimento = settings.arguments as AtendimentoModel;
            return MaterialPageRoute(
              builder: (context) =>
                  HistoricoDetalheScreen(atendimento: atendimento),
            );
          }

          return null;
        },
      ),
    );
  }
}
