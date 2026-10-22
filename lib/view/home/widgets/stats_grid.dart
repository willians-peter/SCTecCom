// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../../data/models/chamado_model.dart';
import '../../../utils/location_helper.dart';

/// Componente de Métricas com GridView (RF08 e Requisitos Técnicos de GridView)
class StatsGrid extends StatelessWidget {
  final List<ChamadoModel> chamados;
  final int totalPendentes;
  final bool gpsAtivo;

  const StatsGrid({
    super.key,
    required this.chamados,
    required this.totalPendentes,
    required this.gpsAtivo,
  });

  @override
  Widget build(BuildContext context) {
    // Calcula o chamado mais próximo se houver distâncias calculadas
    final chamadosComDistancia = chamados.where((c) => c.distanciaKm != null).toList();
    final double? menorDistancia = chamadosComDistancia.isNotEmpty
        ? chamadosComDistancia.first.distanciaKm
        : null;

    final cards = [
      _StatItem(
        titulo: 'Abertos',
        valor: '${chamados.length}',
        subtitulo: 'Ordens ativas',
        icone: Icons.assignment_outlined,
        cor: const Color(0xFF004587),
      ),
      _StatItem(
        titulo: 'Mais Próximo',
        valor: menorDistancia != null ? LocationHelper.formatarDistancia(menorDistancia) : '-- km',
        subtitulo: menorDistancia != null ? 'Via GPS' : 'Aguardando GPS',
        icone: Icons.near_me_outlined,
        cor: Colors.teal.shade700,
      ),
      _StatItem(
        titulo: 'Pendentes',
        valor: '$totalPendentes',
        subtitulo: totalPendentes > 0 ? 'Fila offline' : 'Tudo em dia',
        icone: totalPendentes > 0 ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
        cor: totalPendentes > 0 ? Colors.deepOrange.shade700 : Colors.green.shade700,
      ),
      _StatItem(
        titulo: 'GPS Campo',
        valor: gpsAtivo ? 'Fixado' : 'Buscando',
        subtitulo: gpsAtivo ? 'Alta precisão' : 'Localização',
        icone: gpsAtivo ? Icons.location_on : Icons.location_searching,
        cor: gpsAtivo ? Colors.indigo.shade700 : Colors.grey.shade700,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final item = cards[index];
        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: item.cor.withOpacity(0.12),
                  child: Icon(item.icone, color: item.cor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.valor,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: item.cor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.subtitulo,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icone;
  final Color cor;

  _StatItem({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icone,
    required this.cor,
  });
}
