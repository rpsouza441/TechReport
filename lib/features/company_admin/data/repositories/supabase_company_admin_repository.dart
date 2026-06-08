import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
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
  Future<AdminEmpresaResumo> getEmpresa(String empresaId) async {
    final client = await _requireClient();
    final row = await client
        .from('empresas')
        .select('id, nome, ativo')
        .eq('id', empresaId)
        .maybeSingle();

    if (row == null) {
      throw StateError('Empresa não encontrada.');
    }

    return _toEmpresa(row);
  }

  @override
  Future<void> createEmpresa({required String nome}) async {
    final client = await _requireClient();
    await client.from('empresas').insert({'nome': nome.trim()});
  }

  @override
  Future<void> updateEmpresa({
    required String empresaId,
    String? nome,
    bool? ativo,
  }) async {
    if (nome == null && ativo == null) {
      throw ArgumentError('updateEmpresa requer nome ou ativo.');
    }

    final client = await _requireClient();
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (nome != null) {
      final trimmed = nome.trim();
      if (trimmed.isEmpty) {
        throw ArgumentError('Nome da empresa não pode ser vazio.');
      }
      updates['nome'] = trimmed;
    }

    if (ativo != null) {
      updates['ativo'] = ativo;
    }

    await client.from('empresas').update(updates).eq('id', empresaId);
  }

  @override
  Future<List<AdminTecnicoResumo>> listTecnicos({
    required String empresaId,
  }) async {
    final client = await _requireClient();
    final rows = await client
        .from('tecnicos')
        .select(
          'id, empresa_id, nome, email, papel, ativo, must_change_password',
        )
        .eq('empresa_id', empresaId)
        .order('nome');

    return rows.map<AdminTecnicoResumo>(_toTecnico).toList();
  }

  @override
  Future<List<AdminConviteResumo>> listConvites({
    required String empresaId,
  }) async {
    final client = await _requireClient();
    final rows = await client
        .from('tecnico_convites')
        .select(
          'id, empresa_id, email, nome, papel, status, expires_at, created_at',
        )
        .eq('empresa_id', empresaId)
        .inFilter('status', ['pending', 'accepted', 'expired', 'cancelled'])
        .order('created_at', ascending: false);

    return rows.map<AdminConviteResumo>(_toConvite).toList();
  }

  @override
  Future<CreateTecnicoConviteResult> createConvite({
    required String email,
    required String nome,
    required AdminTecnicoPapel papel,
  }) async {
    final client = await _requireClient();
    final response = await client.rpc(
      'create_tecnico_convite',
      params: {
        'p_email': email.trim(),
        'p_nome': nome.trim(),
        'p_papel': _papelToRemote(papel),
      },
    );

    if (response is! Map<String, dynamic>) {
      throw StateError('Resposta inválida ao criar convite.');
    }

    return CreateTecnicoConviteResult(
      conviteId: response['convite_id'] as String,
      codigoConvite: response['codigo_convite'] as String,
      expiresAt: DateTime.parse(response['expires_at'] as String),
    );
  }

  @override
  Future<CreateTecnicoConviteResult> createEmpresaConvite({
    required String empresaId,
    required String email,
    required String nome,
    required AdminTecnicoPapel papel,
  }) async {
    final client = await _requireClient();
    final response = await client.rpc(
      'create_empresa_convite',
      params: {
        'p_empresa_id': empresaId,
        'p_email': email.trim(),
        'p_nome': nome.trim(),
        'p_papel': _papelToRemote(papel),
      },
    );

    if (response is! Map<String, dynamic>) {
      throw StateError('Resposta invalida ao criar convite.');
    }

    return CreateTecnicoConviteResult(
      conviteId: response['convite_id'] as String,
      codigoConvite: response['codigo_convite'] as String,
      expiresAt: DateTime.parse(response['expires_at'] as String),
    );
  }

  @override
  Future<void> cancelConvite({required String conviteId}) async {
    final client = await _requireClient();
    await client.rpc(
      'cancel_tecnico_convite',
      params: {'p_convite_id': conviteId},
    );
  }

  @override
  Future<void> acceptConvite({required String codigoConvite}) async {
    final client = await _requireClient();
    await client.rpc(
      'accept_tecnico_convite',
      params: {'p_codigo': codigoConvite.trim()},
    );
  }

  @override
  Future<void> updateTecnicoEquipe({
    required String tecnicoId,
    bool? ativo,
    bool? mustChangePassword,
  }) async {
    final client = await _requireClient();
    await client.rpc(
      'update_tecnico_equipe',
      params: {
        'p_tecnico_id': tecnicoId,
        'p_ativo': ativo,
        'p_must_change_password': mustChangePassword,
      },
    );
  }

  Future<SupabaseClient> _requireClient() async {
    final client = await _clientFactory.tryCreateAuthenticatedClient();
    if (client == null) {
      throw StateError('Sessão remota não restaurada.');
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
      mustChangePassword: row['must_change_password'] as bool? ?? false,
    );
  }

  AdminConviteResumo _toConvite(Map<String, dynamic> row) {
    return AdminConviteResumo(
      id: row['id'] as String,
      empresaId: row['empresa_id'] as String,
      email: row['email'] as String,
      nome: row['nome'] as String,
      papel: _toPapel(row['papel'] as String),
      status: _toConviteStatus(row['status'] as String),
      expiresAt: DateTime.parse(row['expires_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
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
        throw ArgumentError('Papel admin inválido: $value');
    }
  }

  String _papelToRemote(AdminTecnicoPapel papel) {
    return switch (papel) {
      AdminTecnicoPapel.adminEmpresa => 'admin_empresa',
      AdminTecnicoPapel.gerente => 'gerente',
      AdminTecnicoPapel.tecnico => 'tecnico',
    };
  }

  AdminConviteStatus _toConviteStatus(String value) {
    return switch (value) {
      'pending' => AdminConviteStatus.pending,
      'accepted' => AdminConviteStatus.accepted,
      'expired' => AdminConviteStatus.expired,
      'cancelled' => AdminConviteStatus.cancelled,
      _ => throw ArgumentError('Status de convite inválido: $value'),
    };
  }
}
