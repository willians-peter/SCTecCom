import 'package:geolocator/geolocator.dart';

/// Helper para geolocalização e cálculo de distâncias (RF07)
class LocationHelper {
  /// Obtém a posição atual do técnico com tratamento de permissões e serviço GPS
  static Future<Position?> obterPosicaoAtual() async {
    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      return null;
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        return null;
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Calcula a distância em quilômetros (km) entre duas coordenadas geográficas
  static double calcularDistanciaKm({
    required double latOrigem,
    required double lonOrigem,
    required double latDestino,
    required double lonDestino,
  }) {
    final distanciaMetros = Geolocator.distanceBetween(
      latOrigem,
      lonOrigem,
      latDestino,
      lonDestino,
    );
    return distanciaMetros / 1000.0;
  }

  /// Formata a distância para exibição amigável em km
  static String formatarDistancia(double? distanciaKm) {
    if (distanciaKm == null) return '-- km';
    if (distanciaKm < 1.0) {
      final metros = (distanciaKm * 1000).round();
      return '$metros m';
    }
    return '${distanciaKm.toStringAsFixed(1)} km';
  }
}
