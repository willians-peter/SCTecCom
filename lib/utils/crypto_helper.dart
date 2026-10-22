import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'constants.dart';

/// Utilitário de Criptografia para Autenticação Segura (RF03)
///
/// Assina a senha digitada pelo técnico em campo com o algoritmo HMAC-SHA256
/// utilizando a Chave Secreta Compartilhada da Turma antes da transmissão pela rede.
class CryptoHelper {
  /// Gera a assinatura hexadecimal HMAC-SHA256 da senha plana fornecida.
  static String gerarHmacSha256(String senhaPlana, {String? secretKey}) {
    final key = secretKey ?? AppConstants.hmacSecretKey;
    final keyBytes = utf8.encode(key);
    final passwordBytes = utf8.encode(senhaPlana);

    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(passwordBytes);

    return digest.toString(); // Hexadecimal de 64 caracteres
  }
}
