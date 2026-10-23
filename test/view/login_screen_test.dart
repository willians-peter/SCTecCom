import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scteccom_app/view/login/login_screen.dart';
import 'package:scteccom_app/viewModel/auth_view_model.dart';
import 'package:scteccom_app/viewModel/chamados_view_model.dart';
import 'package:scteccom_app/viewModel/sync_view_model.dart';

void main() {
  Widget criarTelaParaTeste() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
        ChangeNotifierProvider<ChamadosViewModel>(
          create: (_) => ChamadosViewModel(),
        ),
        ChangeNotifierProvider<SyncViewModel>(create: (_) => SyncViewModel()),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  group('Widget Test - Tela de Login (RF03, RNF01)', () {
    testWidgets('deve renderizar campos de e-mail, senha e botão de entrar', (
      tester,
    ) async {
      await tester.pumpWidget(criarTelaParaTeste());
      await tester.pumpAndSettle();

      // Verifica títulos e textos
      expect(find.text('ISP Telecom Conecta'), findsOneWidget);
      expect(find.text('Autenticação de Técnico de Campo'), findsOneWidget);
      expect(find.text('ENTRAR NO SISTEMA'), findsOneWidget);

      // Verifica campos de entrada
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('E-mail institucional'), findsOneWidget);
      expect(find.text('Senha de acesso'), findsOneWidget);
    });

    testWidgets('deve disparar validação ao tentar submeter campos inválidos', (
      tester,
    ) async {
      await tester.pumpWidget(criarTelaParaTeste());
      await tester.pumpAndSettle();

      // Limpa o e-mail preenchido por padrão
      final campoEmail = find.widgetWithText(
        TextFormField,
        'E-mail institucional',
      );
      await tester.enterText(campoEmail, '');
      await tester.pumpAndSettle();

      // Clica no botão Entrar
      final botaoEntrar = find.text('ENTRAR NO SISTEMA');
      await tester.tap(botaoEntrar);
      await tester.pumpAndSettle();

      // Verifica mensagens de validação
      expect(find.text('Informe o e-mail.'), findsOneWidget);
      expect(find.text('Informe a senha.'), findsOneWidget);
    });
  });
}
