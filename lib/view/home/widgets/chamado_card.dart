// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../../data/models/chamado_model.dart';
import '../../../utils/location_helper.dart';

/// Card de exibição da Ordem de Serviço com cálculo de distância (RF08)
class ChamadoCard extends StatelessWidget {
  final ChamadoModel chamado;
  final VoidCallback onTap;

  const ChamadoCard({
    super.key,
    required this.chamado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distanciaTexto = LocationHelper.formatarDistancia(chamado.distanciaKm);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topo do Card: Código do Cliente e Badge de Distância GPS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      chamado.codigoCliente,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.teal.shade300, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car, size: 14, color: Colors.teal.shade800),
                        const SizedBox(width: 4),
                        Text(
                          distanciaTexto,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Nome do Cliente
              Text(
                chamado.nomeCliente,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),

              // Categoria Informada
              Row(
                children: [
                  Icon(Icons.label_outline, size: 15, color: Colors.blueGrey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      chamado.categoriaInformada,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Resumo do Problema
              Text(
                chamado.descricaoProblema,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),

              const Divider(height: 1, thickness: 0.6),
              const SizedBox(height: 8),

              // Endereço Completo
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      chamado.enderecoCompleto,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
