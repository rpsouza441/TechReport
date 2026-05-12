enum RatListScopeType { local, companyTechnician, companyManager }

class RatListScope {
  const RatListScope.local()
    : type = RatListScopeType.local,
      empresaId = null,
      tecnicoId = null;

  const RatListScope.companyTechnician({
    required this.empresaId,
    required this.tecnicoId,
  }) : type = RatListScopeType.companyTechnician;

  const RatListScope.companyManager({required this.empresaId})
    : type = RatListScopeType.companyManager,
      tecnicoId = null;

  final RatListScopeType type;
  final String? empresaId;
  final String? tecnicoId;
}
