import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewModel/historico_view_model.dart';

/// Tela 05: Histórico de Atendimentos com Busca em Tempo Real e Badges (RF14, RF15)
class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoricoViewModel>(context, listen: false).carregarHistorico();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historicoVm = Provider.of<HistoricoViewModel>(context);
    final itens = historicoVm.itens;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        title: const Text('Histórico de Atendimentos'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Barra de Pesquisa em Tempo Real por ID do chamado ou Código do cliente (RF15)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por ID da OS ou Código do Cliente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          historicoVm.atualizarFiltro('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (texto) {
                historicoVm.atualizarFiltro(texto);
              },
            ),
          ),

          // Totalizador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${itens.length} atendimento(s) encontrado(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (historicoVm.filtroTexto.isNotEmpty)
                  Text(
                    'Filtrando por "${historicoVm.filtroTexto}"',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF003366),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // Listagem Lazy Loading com ListView.builder (RF14)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => historicoVm.carregarHistorico(),
              child: historicoVm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : itens.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_toggle_off,
                                      size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    historicoVm.filtroTexto.isNotEmpty
                                        ? 'Nenhum atendimento corresponde ao filtro.'
                                        : 'Nenhum atendimento finalizado ainda.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: itens.length,
                          itemBuilder: (context, index) {
                            final item = itens[index];
                            final sincronizado = item.sincronizado;

                            return Card(
                              elevation: 1.5,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // Abre a visualização detalhada (RF16)
                                  historicoVm.selecionarAtendimento(item);
                                  Navigator.pushNamed(
                                    context,
                                    '/historico_detalhe',
                                    arguments: item,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Topo: Chamado ID e Badge de Sincronização (RF14)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'OS #${item.chamadoId} ${item.codigoCliente != null ? "• ${item.codigoCliente}" : ""}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF003366),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: sincronizado
                                                  ? Colors.green.shade50
                                                  : Colors.amber.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: sincronizado
                                                    ? Colors.green.shade400
                                                    : Colors.amber.shade700,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  sincronizado
                                                      ? Icons.cloud_done
                                                      : Icons.cloud_upload_outlined,
                                                  size: 13,
                                                  color: sincronizado
                                                      ? Colors.green.shade800
                                                      : Colors.amber.shade900,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  sincronizado
                                                      ? 'Sincronizado'
                                                      : 'Pendente de Envio',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: sincronizado
                                                      ? Colors.green.shade900
                                                      : Colors.amber.shade900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Nome do Cliente
                                      if (item.nomeCliente != null && item.nomeCliente!.isNotEmpty)
                                        Text(
                                          item.nomeCliente!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      const SizedBox(height: 4),

                                      // Categoria Técnica
                                      Row(
                                        children: [
                                          Icon(Icons.build_circle_outlined,
                                              size: 14, color: Colors.blueGrey.shade600),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item.categoriaTecnico,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.blueGrey.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // Resumo do Procedimento
                                      Text(
                                        item.descricaoProcedimento,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Data
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            item.dataResolucao,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
