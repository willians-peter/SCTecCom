import 'package:flutter_test/flutter_test.dart';
import 'package:scteccom_app/utils/constants.dart';
import 'package:scteccom_app/utils/crypto_helper.dart';

void main() {
  group('CryptoHelper - Assinatura HMAC-SHA256 (RF03)', () {
    test('deve gerar assinatura hexadecimal de 64 caracteres', () {
      const senhaPlana = 'senha123';
      final hash = CryptoHelper.gerarHmacSha256(senhaPlana);

      expect(hash, isNotEmpty);
      expect(hash.length, equals(64));
      // Garante que é um hexadecimal válido
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash), isTrue);
    });

    test('deve gerar hashes consistentes e determinísticos para a mesma entrada', () {
      const senhaPlana = 'telecom@senai2026';
      final hash1 = CryptoHelper.gerarHmacSha256(senhaPlana);
      final hash2 = CryptoHelper.gerarHmacSha256(senhaPlana);

      expect(hash1, equals(hash2));
    });

    test('deve gerar hashes diferentes para senhas diferentes', () {
      final hashA = CryptoHelper.gerarHmacSha256('senha_a');
      final hashB = CryptoHelper.gerarHmacSha256('senha_b');

      expect(hashA, isNot(equals(hashB)));
    });

    test('deve utilizar a chave secreta compartilhada da turma', () {
      expect(
        AppConstants.hmacSecretKey,
        equals(r'ISP_TECH_SENAI_2026_xK9#mQ2$vL8!zP4'),
      );
    });
  });
}
