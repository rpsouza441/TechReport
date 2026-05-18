enum AdminTecnicoPapel { adminEmpresa, gerente, tecnico }

class AdminTecnicoResumo {
  const AdminTecnicoResumo({
    required this.id,
    required this.empresaId,
    required this.nome,
    required this.email,
    required this.papel,
    required this.ativo,
  });

  final String id;
  final String empresaId;
  final String nome;
  final String email;
  final AdminTecnicoPapel papel;
  final bool ativo;
}
