import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewModel/sync_view_model.dart';

/// Barra indicadora de conectividade e sincronização offline (RF08, RF13)
class NetworkStatusBar extends StatelessWidget {
  const NetworkStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncViewModel>(
      builder: (context, syncVm, child) {
        final online = syncVm.temConexao;
        final pendentes = syncVm.totalPendentes;
        final sincronizando = syncVm.isSincronizando;

        // Se estiver online e sem pendências, exibe barra sutil ou oculta
        if (online && pendentes == 0 && !sincronizando) {
          return const SizedBox.shrink();
        }

        Color bgColor;
        IconData icon;
        String texto;

        if (sincronizando) {
          bgColor = Colors.blue.shade700;
          icon = Icons.sync;
          texto = 'Sincronizando pendências com o servidor...';
        } else if (!online) {
          bgColor = Colors.deepOrange.shade800;
          icon = Icons.wifi_off;
          texto = pendentes > 0
              ? 'Modo Offline: $pendentes atendimento(s) salvo(s) localmente'
              : 'Modo Offline: Operando com banco SQLite local';
        } else {
          bgColor = Colors.amber.shade800;
          icon = Icons.cloud_upload_outlined;
          texto = '$pendentes atendimento(s) pendente(s) para sincronização';
        }

        return Container(
          width: double.infinity,
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (sincronizando)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  texto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (online && pendentes > 0 && !sincronizando)
                InkWell(
                  onTap: () => syncVm.sincronizarPendentes(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'SUBIR AGORA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
