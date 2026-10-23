// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/chamado_model.dart';
import '../../utils/constants.dart';
import '../../viewModel/atendimento_view_model.dart';
import '../../viewModel/sync_view_model.dart';

/// Tela 04: Atendimento Técnico e Parecer de Conclusão Offline (RF09, RF10, RF11, RF12)
class AtendimentoScreen extends StatefulWidget {
  final ChamadoModel chamado;

  const AtendimentoScreen({super.key, required this.chamado});

  @override
  State<AtendimentoScreen> createState() => _AtendimentoScreenState();
}

class _AtendimentoScreenState extends State<AtendimentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _procedimentoController = TextEditingController();

  // Itens de formulário adicionais para enriquecer a experiência e cumprir requisitos técnicos
  bool _sinalHomologado = true;
  double _nivelSinalDbm = -19.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AtendimentoViewModel>(
        context,
        listen: false,
      ).resetFormulario();
    });
  }

  @override
  void dispose() {
    _procedimentoController.dispose();
    super.dispose();
  }

  Future<void> _salvarAtendimento() async {
    final atendimentoVm = Provider.of<AtendimentoViewModel>(
      context,
      listen: false,
    );

    // 1. Validação estrita com GlobalKey<FormState> (RF10)
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, preencha todos os campos obrigatórios corretamente.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (atendimentoVm.categoriaSelecionada == null ||
        atendimentoVm.categoriaSelecionada!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma categoria técnica para o parecer.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Adiciona informação complementar de sinal caso o técnico tenha ajustado
    final textoCompleto =
        '${_procedimentoController.text.trim()} [Sinal medido: ${_nivelSinalDbm.toStringAsFixed(1)} dBm | Homologado: ${_sinalHomologado ? "Sim" : "Não"}]';

    // 2. Gravação offline no SQLite com flag sincronizado = 0 (RF12)
    final sucesso = await atendimentoVm.finalizarAtendimentoOffline(
      chamado: widget.chamado,
      descricaoProcedimento: textoCompleto,
    );

    if (!mounted) return;

    if (sucesso) {
      // Atualiza o contador de pendências no SyncViewModel
      Provider.of<SyncViewModel>(
        context,
        listen: false,
      ).atualizarContagemPendentes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Atendimento gravado com sucesso no dispositivo! (Pendente de sincronização)',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Retorna true para a Home remover o chamado da listagem
      Navigator.pop(context, true);
    } else {
      final erro =
          atendimentoVm.mensagemErro ??
          'Erro desconhecido ao salvar atendimento.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final atendimentoVm = Provider.of<AtendimentoViewModel>(context);
    final chamado = widget.chamado;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        title: Text('Atendimento #${chamado.id}'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabeçalho com dados da OS (RF09)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003366).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              chamado.codigoCliente,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Text(
                              'Status: ${chamado.status.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        chamado.nomeCliente,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.place,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              chamado.enderecoCompleto,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Text(
                        'Problema Relatado:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        chamado.descricaoProblema,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Formulário do Parecer Técnico
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parecer Técnico de Campo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Categoria Técnica (DropdownButtonFormField - RF09, RF10)
                      DropdownButtonFormField<String>(
                        isExpanded: true, // ajuste largura total estouro na renderização
                        value: atendimentoVm.categoriaSelecionada,
                        decoration: InputDecoration(
                          labelText: 'Categoria Técnica Constatada *',
                          prefixIcon: const Icon(Icons.build_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: AppConstants.categoriasTecnicas.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (novo) => atendimentoVm.setCategoria(novo),
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return 'Campo obrigatório. Selecione a categoria.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Descrição do Procedimento Multilinhas (RF09, RF10 - min 10 chars)
                      TextFormField(
                        controller: _procedimentoController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Descrição do Procedimento Realizado *',
                          hintText: 'Relate detalhadamente o conserto ou manutenção feita...',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(Icons.description_outlined),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Informe a descrição do procedimento.';
                          }
                          if (valor.trim().length <
                              AppConstants.minDescricaoChars) {
                            return 'A descrição deve ter no mínimo 10 caracteres válidos.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Item de Formulário: SwitchListTile (demonstrando requisito 4.5)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Sinal Óptico Homologado',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Conexão testada no Power Meter com níveis aceitáveis',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _sinalHomologado,
                        activeColor: const Color(0xFF003366),
                        onChanged: (val) {
                          setState(() {
                            _sinalHomologado = val;
                          });
                        },
                      ),
                      const SizedBox(height: 8),

                      // Item de Formulário: Slider de Potência Óptica (-dBm) (requisito 4.5)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Atenuação Óptica Medida:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${_nivelSinalDbm.toStringAsFixed(1)} dBm',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003366),
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _nivelSinalDbm,
                            min: -30.0,
                            max: -10.0,
                            divisions: 40,
                            label: '${_nivelSinalDbm.toStringAsFixed(1)} dBm',
                            activeColor: const Color(0xFF003366),
                            onChanged: (val) {
                              setState(() {
                                _nivelSinalDbm = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Data e Hora de Conclusão (RF09)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Data de Conclusão: ${atendimentoVm.dataResolucaoFormatada}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Anexo de Foto do Comprovante (RF11)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.photo_camera,
                            size: 20,
                            color: Color(0xFF003366),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Foto Comprobatória do Serviço',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003366),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Fotografe a conectorização, ONU ou reparo (salva localmente e compactada até 5MB).',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),

                      // Pré-visualização da Foto
                      if (atendimentoVm.fotoComprovante != null) ...[
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                atendimentoVm.fotoComprovante!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.red.shade700,
                                radius: 18,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () => atendimentoVm.removerFoto(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Botões de Câmera e Galeria
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Tirar Foto'),
                              onPressed: () => atendimentoVm.capturarFoto(
                                ImageSource.camera,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galeria'),
                              onPressed: () => atendimentoVm.capturarFoto(
                                ImageSource.gallery,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão de Finalização Offline (RF12)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: atendimentoVm.isSalvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    atendimentoVm.isSalvando
                        ? 'GRAVANDO NO BANCO LOCAL...'
                        : 'FINALIZAR ATENDIMENTO (OFFLINE)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: atendimentoVm.isSalvando
                      ? null
                      : _salvarAtendimento,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
