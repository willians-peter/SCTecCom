import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scteccom_app/data/models/chamado_model.dart';
import 'package:scteccom_app/view/home/widgets/chamado_card.dart';
import 'package:scteccom_app/view/home/widgets/stats_grid.dart';

void main() {
  final chamadoTeste = ChamadoModel(
    id: 1,
    codigoCliente: 'CLI-84920',
    nomeCliente: 'Mariana Silveira Ramos',
    categoriaInformada: 'Lentidão na navegação',
    descricaoProblema: 'Vídeos em alta resolução não carregam e teste bate 10% do plano.',
    enderecoCliente: 'Rua Fernando Machado, 450, Apto 204',
    bairro: 'Centro',
    cidade: 'Chapecó',
    latitude: -27.100412,
    longitude: -52.615234,
    status: 'ativo',
    criadoEm: '2026-09-28 14:20:00',
    distanciaKm: 3.2,
  );

  group('Widget Test - Componentes da Home (RF06, RF08, RNF01)', () {
    testWidgets('StatsGrid deve renderizar métricas em GridView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsGrid(
              chamados: [chamadoTeste],
              totalPendentes: 2,
              gpsAtivo: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatsGrid), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Ordens ativas'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Via GPS'), findsOneWidget);
      expect(find.text('3.2 km'), findsOneWidget);
      expect(find.text('Fila offline'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Fixado'), findsOneWidget);
    });

    testWidgets('ChamadoCard deve exibir código, cliente, problema, endereço e distância GPS', (tester) async {
      bool clicou = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamadoCard(
              chamado: chamadoTeste,
              onTap: () {
                clicou = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Valida dados exigidos no RF08
      expect(find.text('CLI-84920'), findsOneWidget);
      expect(find.text('Mariana Silveira Ramos'), findsOneWidget);
      expect(find.text('Lentidão na navegação'), findsOneWidget);
      expect(find.text('3.2 km'), findsOneWidget);
      expect(find.text('Rua Fernando Machado, 450, Apto 204 - Centro, Chapecó'), findsOneWidget);

      // Testa toque no card para navegação
      await tester.tap(find.byType(ChamadoCard));
      expect(clicou, isTrue);
    });
  });
}
