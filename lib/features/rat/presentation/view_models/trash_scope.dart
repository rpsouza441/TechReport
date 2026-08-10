sealed class TrashScope {
  const TrashScope();

  const factory TrashScope.local() = LocalTrashScope;
  const factory TrashScope.companyTechnician({
    required String empresaId,
    required String tecnicoId,
  }) = CompanyTechnicianTrashScope;
  const factory TrashScope.companyManager({required String empresaId}) =
      CompanyManagerTrashScope;
}

final class LocalTrashScope extends TrashScope {
  const LocalTrashScope();
}

final class CompanyTechnicianTrashScope extends TrashScope {
  const CompanyTechnicianTrashScope({
    required this.empresaId,
    required this.tecnicoId,
  });

  final String empresaId;
  final String tecnicoId;
}

final class CompanyManagerTrashScope extends TrashScope {
  const CompanyManagerTrashScope({required this.empresaId});

  final String empresaId;
}
