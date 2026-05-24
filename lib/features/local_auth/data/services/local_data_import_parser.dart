import 'dart:convert';

class LocalDataImportParser {
  Map<String, dynamic> parse(String rawJson) {
    final decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Arquivo de importação inválido.');
    }

    if (decoded['schema'] != 'techreport.local_export.v1') {
      throw const FormatException('Versão de backup não suportada.');
    }

    final rats = decoded['rats'];
    final assinaturas = decoded['assinaturas'];

    if (rats is! List || assinaturas is! List) {
      throw const FormatException('Backup local incompleto.');
    }

    return decoded;
  }
}
