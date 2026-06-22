import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/permissions/rat_permissions.dart';

void main() {
  const permissions = RatPermissions();

  group('canReopenForCorrection', () {
    test('permite tecnico proprietario em RAT finalizada', () {
      expect(
        permissions.canReopenForCorrection(
          _rat(status: RatStatus.finalizado),
          _session(),
        ),
        isTrue,
      );
    });

    test('permite tecnico proprietario em RAT enviada', () {
      expect(
        permissions.canReopenForCorrection(
          _rat(status: RatStatus.enviado),
          _session(),
        ),
        isTrue,
      );
    });

    test('recusa tecnico que nao e proprietario', () {
      expect(
        permissions.canReopenForCorrection(
          _rat(status: RatStatus.finalizado, tecnicoId: 'outro-tecnico'),
          _session(),
        ),
        isFalse,
      );
    });

    test('recusa tecnico de outra empresa', () {
      expect(
        permissions.canReopenForCorrection(
          _rat(status: RatStatus.finalizado, empresaId: 'outra-empresa'),
          _session(),
        ),
        isFalse,
      );
    });

    test('mantem permissao de gerente e admin da mesma empresa', () {
      final rat = _rat(
        status: RatStatus.finalizado,
        tecnicoId: 'outro-tecnico',
      );

      expect(
        permissions.canReopenForCorrection(
          rat,
          _session(papel: SessaoRemotaPapelEmpresa.gerente),
        ),
        isTrue,
      );
      expect(
        permissions.canReopenForCorrection(
          rat,
          _session(papel: SessaoRemotaPapelEmpresa.adminEmpresa),
        ),
        isTrue,
      );
    });

    test('recusa todos os papeis quando a empresa e diferente', () {
      final rat = _rat(
        status: RatStatus.finalizado,
        empresaId: 'outra-empresa',
      );

      for (final papel in SessaoRemotaPapelEmpresa.values) {
        expect(
          permissions.canReopenForCorrection(rat, _session(papel: papel)),
          isFalse,
          reason: 'papel $papel nao pode atravessar empresa',
        );
      }
    });

    test('recusa rascunho, arquivada e RAT ja reaberta', () {
      expect(
        permissions.canReopenForCorrection(
          _rat(status: RatStatus.draft),
          _session(),
        ),
        isFalse,
      );
      expect(
        permissions.canReopenForCorrection(
          _rat(status: RatStatus.arquivado),
          _session(),
        ),
        isFalse,
      );
      expect(
        permissions.canReopenForCorrection(
          _rat(
            status: RatStatus.finalizado,
            reabertaParaCorrecaoEm: DateTime(2026, 6, 20),
          ),
          _session(),
        ),
        isFalse,
      );
    });

    test('recusa sessao ausente ou sem contexto de empresa', () {
      final rat = _rat(status: RatStatus.finalizado);

      expect(permissions.canReopenForCorrection(rat, null), isFalse);
      expect(
        permissions.canReopenForCorrection(
          rat,
          _session(empresaId: null, tecnicoId: null),
        ),
        isFalse,
      );
    });
  });
}

Rat _rat({
  required RatStatus status,
  String empresaId = 'empresa-1',
  String tecnicoId = 'tecnico-1',
  DateTime? reabertaParaCorrecaoEm,
}) {
  final now = DateTime(2026, 6, 20);
  return Rat(
    id: 'rat-1',
    authorId: 'author-1',
    empresaId: empresaId,
    usuarioId: 'usuario-1',
    tecnicoId: tecnicoId,
    ownerType: RatOwnerType.companyTecnico,
    numero: '0001',
    clienteNome: 'Cliente',
    responsavelRecebimento: 'Responsavel',
    dataVisita: now,
    horarioInicioAtendimento: '0800',
    horarioTerminoAtendimento: '1000',
    descricao: 'Descricao',
    status: status,
    syncStatus: RatSyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    reabertaParaCorrecaoEm: reabertaParaCorrecaoEm,
  );
}

SessaoRemota _session({
  String? empresaId = 'empresa-1',
  String? tecnicoId = 'tecnico-1',
  SessaoRemotaPapelEmpresa papel = SessaoRemotaPapelEmpresa.tecnico,
}) {
  final now = DateTime(2026, 6, 20);
  return SessaoRemota(
    id: 'sessao-1',
    empresaId: empresaId,
    usuarioId: 'usuario-1',
    tecnicoId: tecnicoId,
    email: 'user@example.com',
    nome: 'Usuario',
    mustChangePassword: false,
    papelGlobal: null,
    papelEmpresa: papel,
    accessTokenRef: 'access-token',
    refreshTokenRef: 'refresh-token',
    endpointRef: 'https://api.example.com',
    expiresAt: now.add(const Duration(hours: 1)),
    lastValidatedAt: now,
    offlineAccessUntil: now.add(const Duration(days: 7)),
    createdAt: now,
    updatedAt: now,
  );
}
