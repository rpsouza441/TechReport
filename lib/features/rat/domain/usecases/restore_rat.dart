import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/permissions/rat_permissions.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';

class RestoreRatNotFoundException implements Exception {
  const RestoreRatNotFoundException(this.ratId);

  final String ratId;
}

class RestoreRatAccessDeniedException implements Exception {
  const RestoreRatAccessDeniedException(this.ratId);

  final String ratId;
}

class RestoreRat {
  const RestoreRat({
    required RatRepository ratRepository,
    required RatPermissions permissions,
  }) : _ratRepository = ratRepository,
       _permissions = permissions;

  final RatRepository _ratRepository;
  final RatPermissions _permissions;

  Future<Rat> call({
    required String ratId,
    required SessaoRemota? session,
  }) async {
    final rat = await _ratRepository.getById(ratId);
    if (rat == null) {
      throw RestoreRatNotFoundException(ratId);
    }

    final isLocalRestore = session == null;
    final ownerMatchesMode = isLocalRestore
        ? rat.ownerType == RatOwnerType.localTecnico
        : rat.ownerType == RatOwnerType.companyTecnico;
    if (!ownerMatchesMode || !_permissions.canRestore(rat, session)) {
      throw RestoreRatAccessDeniedException(ratId);
    }

    final syncStatus = isLocalRestore
        ? RatSyncStatus.localOnly
        : RatSyncStatus.pendingSync;
    await _ratRepository.restore(id: rat.id, syncStatus: syncStatus);

    return rat.copyWith(deletedAt: null, syncStatus: syncStatus);
  }
}
