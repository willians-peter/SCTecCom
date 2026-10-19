import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/atendimento_model.dart';

/// Tela 05 (Detalhe): Visualização Detalhada do Atendimento com Foto (RF16)
class HistoricoDetalheScreen extends StatelessWidget {
  final AtendimentoModel atendimento;

  const HistoricoDetalheScreen({
    super.key,
    required this.atendimento,
  });

  @override
  Widget build(BuildContext context) {
    final item = atendimento;
    final bool temFotoLocal = item.fotoCaminhoLocal != null &&
        item.fotoCaminhoLocal!.isNotEmpty &&
        File(item.fotoCaminhoLocal!).existsSync();
    final bool temFotoRemota = item.fotoUrlRemota != null &&
        item.fotoUrlRemota!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        title: Text('Detalhes da OS #${item.chamadoId}'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status de Sincronização
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.sincronizado ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: item.sincronizado ? Colors.green.shade400 : Colors.amber.shade700,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.sincronizado ? Icons.check_circle : Icons.cloud_upload_outlined,
                    color: item.sincronizado ? Colors.green.shade800 : Colors.amber.shade900,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.sincronizado
                              ? 'Atendimento Sincronizado na Nuvem'
                              : 'Atendimento Pendente de Sincronização',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: item.sincronizado
                                ? Colors.green.shade900
                                : Colors.amber.shade900,
                          ),
                        ),
                        Text(
                          item.sincronizado
                              ? 'Os dados e a foto foram transmitidos via API com sucesso.'
                              : 'Armazenado no banco SQLite local. Será enviado automaticamente.',
                          style: TextStyle(
                            fontSize: 11,
                            color: item.sincronizado
                                ? Colors.green.shade800
                                : Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card com Informações do Chamado
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados do Cliente',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                    const Divider(height: 16),
                    _buildLinhaInfo('Código do Cliente', item.codigoCliente ?? 'N/A'),
                    const SizedBox(height: 6),
                    _buildLinhaInfo('Nome do Cliente', item.nomeCliente ?? 'N/A'),
                    const SizedBox(height: 6),
                    _buildLinhaInfo('Endereço', item.enderecoCliente ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card com o Parecer Técnico
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Parecer Técnico Registrado',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                    const Divider(height: 16),
                    _buildLinhaInfo('Categoria Técnica', item.categoriaTecnico),
                    const SizedBox(height: 12),
                    const Text(
                      'Procedimento Executado:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        item.descricaoProcedimento,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLinhaInfo('Data de Conclusão', item.dataResolucao),
                    if (item.registradoEm != null) ...[
                      const SizedBox(height: 6),
                      _buildLinhaInfo('Registrado no Dispositivo', item.registradoEm!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card com a Foto do Serviço (RF16)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.photo, color: Color(0xFF003366), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Comprovante Fotográfico',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Renderização de fotos: Image.file vs Image.network (RF16)
                    if (temFotoLocal) ...[
                      // 1. Carregada do armazenamento local do celular via Image.file
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(item.fotoCaminhoLocal!),
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Foto carregada do armazenamento interno do aparelho: ${item.fotoCaminhoLocal}',
                        style: const TextStyle(fontSize: 10, color: Colors.black45),
                      ),
                    ] else if (temFotoRemota) ...[
                      // 2. Carregada da nuvem via Image.network com loadingBuilder e errorBuilder (RF16)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          item.fotoUrlRemota!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 250,
                              color: Colors.grey.shade100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'Não foi possível carregar a imagem da nuvem.',
                                      style: TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'URL remota da foto: ${item.fotoUrlRemota}',
                        style: const TextStyle(fontSize: 10, color: Colors.black45),
                      ),
                    ] else ...[
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_outlined,
                                  size: 36, color: Colors.grey),
                              SizedBox(height: 6),
                              Text(
                                'Nenhuma foto anexada para este atendimento.',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaInfo(String rotulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
