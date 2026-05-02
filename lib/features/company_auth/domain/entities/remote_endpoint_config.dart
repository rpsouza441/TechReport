enum RemoteEnvironment { supabase }

class RemoteEndpointConfig {
  const RemoteEndpointConfig({
    required this.id,
    required this.nome,
    required this.supabaseUrl,
    required this.supabasePublicKeyRef,
    required this.tipo,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nome;
  final String supabaseUrl;
  final String supabasePublicKeyRef;
  final String tipo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RemoteEndpointConfig copyWith({
    String? id,
    String? nome,
    String? supabaseUrl,
    String? supabasePublicKeyRef,
    String? tipo,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RemoteEndpointConfig(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabasePublicKeyRef: supabasePublicKeyRef ?? this.supabasePublicKeyRef,
      tipo: tipo ?? this.tipo,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is RemoteEndpointConfig &&
        other.id == id &&
        other.nome == nome &&
        other.supabaseUrl == supabaseUrl &&
        other.supabasePublicKeyRef == supabasePublicKeyRef &&
        other.tipo == tipo &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    nome,
    supabaseUrl,
    supabasePublicKeyRef,
    tipo,
    isActive,
    createdAt,
    updatedAt,
  );
}
