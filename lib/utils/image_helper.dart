import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Helper para manipulação, compressão e armazenamento local de fotos (RF11)
class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Captura foto da câmera ou seleciona da galeria
  static Future<File?> selecionarImagem(ImageSource source) async {
    final XFile? xFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Redimensiona e comprime a foto para respeitar os limites da API (máximo 5MB)
  /// e salva no diretório persistente de documentos do aplicativo.
  static Future<File> otimizarESalvarLocalmente({
    required File arquivoOriginal,
    required int chamadoId,
  }) async {
    final bytes = await arquivoOriginal.readAsBytes();
    final img.Image? decodedImage = img.decodeImage(bytes);

    final appDir = await getApplicationDocumentsDirectory();
    final pastaFotos = Directory(p.join(appDir.path, 'atendimentos_fotos'));
    if (!pastaFotos.existsSync()) {
      pastaFotos.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nomeArquivo = 'atendimento_${chamadoId}_$timestamp.jpg';
    final caminhoDestino = p.join(pastaFotos.path, nomeArquivo);

    if (decodedImage == null) {
      // Fallback: se não conseguir decodificar, copia o arquivo diretamente
      return await arquivoOriginal.copy(caminhoDestino);
    }

    // Redimensiona caso a largura seja muito grande
    img.Image imagemRedimensionada = decodedImage;
    if (decodedImage.width > 1280) {
      imagemRedimensionada = img.copyResize(decodedImage, width: 1280);
    }

    // Comprime como JPEG com qualidade 80%
    final jpgBytes = img.encodeJpg(imagemRedimensionada, quality: 80);

    final novoArquivo = File(caminhoDestino);
    await novoArquivo.writeAsBytes(jpgBytes);
    return novoArquivo;
  }
}
