import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scteccom_app/data/models/chamado_model.dart';
import 'package:scteccom_app/view/atendimento/atendimento_screen.dart';
import 'package:scteccom_app/viewModel/atendimento_view_model.dart';
import 'package:scteccom_app/viewModel/sync_view_model.dart';

void main() {
  final chamadoTeste = ChamadoModel(
    id: 101,
    codigoCliente: 'CLI-84920',
    nomeCliente: 'Mariana Silveira Ramos',
    categoriaInformada: 'Lentidão na navegação',
    descricaoProblema: 'Vídeos não carregam em alta resolução.',
    enderecoCliente: 'Rua Fernando Machado, 450',
    bairro: 'Centro',
    cidade: 'Florianópolis',
    latitude: -27.5950,
    longitude: -48.5480,
    status: 'ativo',
    criadoEm: '2026-10-10 10:00:00',
  );

  Widget criarTelaParaTeste() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AtendimentoViewModel>(
          create: (_) => AtendimentoViewModel(),
        ),
        ChangeNotifierProvider<SyncViewModel>(
          create: (_) => SyncViewModel(),
        ),
      ],
      child: MaterialApp(
        home: AtendimentoScreen(chamado: chamadoTeste),
      ),
    );
  }

  group('Widget Test - Tela de Atendimento (RF09, RF10, RNF01)', () {
    testWidgets('deve exibir dados da OS e campos do parecer técnico', (tester) async {
      await tester.pumpWidget(criarTelaParaTeste());
      await tester.pumpAndSettle();

      // 1. Cabeçalho com dados da OS (RF09)
      expect(find.text('Atendimento #101'), findsOneWidget);
      expect(find.text('CLI-84920'), findsOneWidget);
      expect(find.text('Mariana Silveira Ramos'), findsOneWidget);
      expect(find.text('Vídeos não carregam em alta resolução.'), findsOneWidget);

      // 2. Formulário com Dropdown, Text Multilinhas, Switch, Slider (RF09, Requisitos Técnicos)
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // 3. Botões de foto
      expect(find.text('Tirar Foto'), findsOneWidget);
      expect(find.text('Galeria'), findsOneWidget);

      // 4. Botão de finalizar
      expect(find.text('FINALIZAR ATENDIMENTO (OFFLINE)'), findsOneWidget);
    });

    testWidgets('deve validar obrigatoriedade de categoria e descrição mínima de 10 caracteres (RF10)', (tester) async {
      await tester.pumpWidget(criarTelaParaTeste());
      await tester.pumpAndSettle();

      // Clica em finalizar sem preencher nada
      final botaoSalvar = find.text('FINALIZAR ATENDIMENTO (OFFLINE)');
      await tester.ensureVisible(botaoSalvar);
      await tester.tap(botaoSalvar);
      await tester.pumpAndSettle();

      // Deve apresentar erro de validação
      expect(find.text('Campo obrigatório. Selecione a categoria.'), findsOneWidget);
      expect(find.text('Informe a descrição do procedimento.'), findsOneWidget);
    });
  });
}
