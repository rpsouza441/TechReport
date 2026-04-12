class TecnicoLocal {
  const TecnicoLocal({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.empresaNome,
    required this.assinaturaPadraoRef,
    required this.pinConfigured,
    required this.biometriaHabilitada,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String? empresaNome;
  final String? assinaturaPadraoRef;
  final bool pinConfigured;
  final bool biometriaHabilitada;
  final DateTime createdAt;
  final DateTime updatedAt;

  TecnicoLocal copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    String? empresaNome,
    String? assinaturaPadraoRef,
    bool? pinConfigured,
    bool? biometriaHabilitada,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TecnicoLocal(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      empresaNome: empresaNome ?? this.empresaNome,
      assinaturaPadraoRef: assinaturaPadraoRef ?? this.assinaturaPadraoRef,
      pinConfigured: pinConfigured ?? this.pinConfigured,
      biometriaHabilitada: biometriaHabilitada ?? this.biometriaHabilitada,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
