import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';

class SupabaseCompanyAdminRepository implements CompanyAdminRepository {
  const SupabaseCompanyAdminRepository({
    required SupabaseClientFactory clientFactory,
  }) : _clientFactory = clientFactory;

  final SupabaseClientFactory _clientFactory;

  @override
  Future<List<AdminEmpresaResumo>> listEmpresas() async {
    final client = await _requireClient();
    final rows = await client
        .from('empresas')
        .select('id, nome, ativo')
        .order('nome');

    return rows.map<AdminEmpresaResumo>(_toEmpresa).toList();
  }

  @override
  Future<List<AdminTecnicoResumo>> listTecnicos({
    required String empresaId,
  }) async {
    final client = await _requireClient();
    final rows = await client
        .from('tecnicos')
        .select('id, empresa_id, nome, email, papel, ativo')
        .eq('empresa_id', empresaId)
        .order('nome');

    return rows.map<AdminTecnicoResumo>(_toTecnico).toList();
  }

  Future<SupabaseClient> _requireClient() async {
    final client = await _clientFactory.tryCreateAuthenticatedClient();
    if (client == null) {
      throw StateError('Sessao remota nao restaurada.');
    }

    return client;
  }

  AdminEmpresaResumo _toEmpresa(Map<String, dynamic> row) {
    return AdminEmpresaResumo(
      id: row['id'] as String,
      nome: row['nome'] as String,
      ativo: row['ativo'] as bool,
    );
  }

  AdminTecnicoResumo _toTecnico(Map<String, dynamic> row) {
    return AdminTecnicoResumo(
      id: row['id'] as String,
      empresaId: row['empresa_id'] as String,
      nome: row['nome'] as String,
      email: row['email'] as String,
      papel: _toPapel(row['papel'] as String),
      ativo: row['ativo'] as bool,
    );
  }

  AdminTecnicoPapel _toPapel(String value) {
    switch (value) {
      case 'admin_empresa':
        return AdminTecnicoPapel.adminEmpresa;
      case 'gerente':
        return AdminTecnicoPapel.gerente;
      case 'tecnico':
        return AdminTecnicoPapel.tecnico;
      default:
        throw ArgumentError('Papel admin invalido: $value');
    }
  }
}
