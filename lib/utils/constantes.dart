class AppConstants {
  // Configuração da API
  static const String apiBaseUrl = 'https://oquetemnomeucosmetico.com.br/api';
  static const String docsUrl = 'https://oquetemnomeucosmetico.com.br/docs/';
  
  // Chave Secreta Compartilhada da Turma para HMAC-SHA256
  static const String hmacSecretKey = r'ISP_TECH_SENAI_2026_xK9#mQ2$vL8!zP4';

  // Chaves do Storage Seguro
  static const String keyToken = 'auth_bearer_token';
  static const String keyUserEmail = 'auth_user_email';
  static const String keyUserName = 'auth_user_name';
  static const String keyUserId = 'auth_user_id';

  // Status de Chamados e Atendimentos
  static const String statusAtivo = 'ativo';
  static const String statusAberto = 'aberto';
  static const String statusAtendido = 'atendido';
  static const String statusResolvido = 'resolvido';

  // Categorias Técnicas Pré-definidas para o Dropdown
  static const List<String> categoriasTecnicas = [
    'Conector Fast APC Danificado',
    'Rompimento de Fibra Óptica (Drop)',
    'ONU / ONT Desconfigurada',
    'Troca de Roteador Wi-Fi',
    'Atenuação Excessiva no Sinal Óptico',
    'Fonte de Alimentação Queimada',
    'Problema Externo na CTO / Rede Distribuição',
    'Outro Procedimento Técnico',
  ];

  // Limites da Aplicação
  static const int minDescricaoChars = 10;
  static const int syncIntervalMinutes = 5;
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
}
