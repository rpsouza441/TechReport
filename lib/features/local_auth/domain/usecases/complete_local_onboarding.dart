import '../entities/sessao_local.dart';
import '../entities/tecnico_local.dart';
import '../repositories/sessao_local_repository.dart';
import '../repositories/tecnico_local_repository.dart';

class CompleteLocalOnboardingInput {
  const CompleteLocalOnboardingInput({
    required this.nome,
    required this.email,
    this.telefone,
    this.empresaNome,
  });

  final String nome;
  final String email;
  final String? telefone;
  final String? empresaNome;
}

class CompleteLocalOnboarding {
  CompleteLocalOnboarding({
    required TecnicoLocalRepository tecnicoLocalRepository,
    required SessaoLocalRepository sessaoLocalRepository,
  }) : _tecnicoLocalRepository = tecnicoLocalRepository,
       _sessaoLocalRepository = sessaoLocalRepository;

  final TecnicoLocalRepository _tecnicoLocalRepository;
  final SessaoLocalRepository _sessaoLocalRepository;

  Future<SessaoLocal> call(CompleteLocalOnboardingInput input) async {
    final now = DateTime.now();
    const tecnicoId = 'tec-local-001';
    final tecnico = TecnicoLocal(
      id: tecnicoId,
      nome: input.nome.trim(),
      email: input.email.trim(),
      telefone: _normalizeOptional(input.telefone),
      empresaNome: _normalizeOptional(input.empresaNome),
      assinaturaPadraoRef: null,
      pinConfigured: false,
      biometriaHabilitada: false,
      createdAt: now,
      updatedAt: now,
    );
    final session = SessaoLocal(
      id: 'sessao-local-001',
      tecnicoLocalId: tecnico.id,
      status: SessaoLocalStatus.unlocked,
      pinConfigured: false,
      biometriaDisponivel: false,
      biometriaHabilitada: false,
      onboardingConcluido: true,
      lastUnlockedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    await _tecnicoLocalRepository.save(tecnico);
    await _sessaoLocalRepository.saveSession(session);
    return session;
  }

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
