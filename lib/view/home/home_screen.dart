import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewModel/auth_view_model.dart';
import '../../viewModel/chamados_view_model.dart';
import '../../viewModel/sync_view_model.dart';
import '../widgets/network_status_bar.dart';
import 'widgets/chamado_card.dart';
import 'widgets/stats_grid.dart';

/// Tela 03: Home com Listagem Offline, Lazy Loading e Ordenação por GPS (RF06, RF07, RF08)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosIniciais();
    });
  }

  Future<void> _carregarDadosIniciais() async {
    final chamadosVm = Provider.of<ChamadosViewModel>(context, listen: false);
    final syncVm = Provider.of<SyncViewModel>(context, listen: false);

    await chamadosVm.carregarChamadosLocais(buscarGps: true);
    await syncVm.atualizarContagemPendentes();
  }

  Future<void> _confirmarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar Sessão'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SAIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final authVm = Provider.of<AuthViewModel>(context, listen: false);
      await authVm.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);
    final chamadosVm = Provider.of<ChamadosViewModel>(context);
    final syncVm = Provider.of<SyncViewModel>(context);

    final usuarioNome = authVm.usuario?.nome ?? 'Técnico de Campo';
    final chamados = chamadosVm.chamados;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ordens de Serviço',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              usuarioNome,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Botão para atualizar localização GPS
          IconButton(
            tooltip: 'Atualizar GPS',
            icon: chamadosVm.isGpsLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location),
            onPressed: chamadosVm.isGpsLoading
                ? null
                : () => chamadosVm.atualizarGpsEOrdenar(),
          ),

          // Botão para ir ao Histórico de Atendimentos (RF14)
          IconButton(
            tooltip: 'Histórico de Atendimentos',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/historico');
            },
          ),

          // Logout
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _confirmarLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de status de rede e pendências offline (RF08, RF13)
          const NetworkStatusBar(),

          // Conteúdo principal com Lazy Loading (RF06)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Tenta puxar da nuvem e recarrega SQLite
                await chamadosVm.sincronizarComApi();
                await syncVm.atualizarContagemPendentes();
              },
              child: chamadosVm.isLoading && chamados.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: chamados.length + 1, // +1 para o topo com o GridView
                      itemBuilder: (context, index) {
                        // O primeiro item renderiza o GridView de métricas (satisfaz requisito GridView!)
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatsGrid(
                                chamados: chamados,
                                totalPendentes: syncVm.totalPendentes,
                                gpsAtivo: chamadosVm.posicaoAtual != null,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Chamados Ativos (${chamados.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003366),
                                    ),
                                  ),
                                  if (chamadosVm.posicaoAtual != null)
                                    const Row(
                                      children: [
                                        Icon(Icons.sort, size: 14, color: Colors.teal),
                                        SizedBox(width: 4),
                                        Text(
                                          'Ordenado por proximidade',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.teal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (chamados.isEmpty)
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.check_circle_outline,
                                              size: 48, color: Colors.green),
                                          SizedBox(height: 12),
                                          Text(
                                            'Nenhum chamado aberto no momento!',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Todos os atendimentos foram concluídos com sucesso.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }

                        // Lazy loading dos chamados com ListView.builder (RF06, RF08)
                        final chamado = chamados[index - 1];
                        return ChamadoCard(
                          chamado: chamado,
                          onTap: () async {
                            // Navega para a Tela de Atendimento
                            final resultado = await Navigator.pushNamed(
                              context,
                              '/atendimento',
                              arguments: chamado,
                            );

                            // Se o atendimento foi concluído com sucesso, recarrega a lista
                            if (resultado == true && mounted) {
                              chamadosVm.removerChamadoAtendido(chamado.id);
                              await syncVm.atualizarContagemPendentes();
                            }
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF003366),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/historico');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Ordens Ativas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
