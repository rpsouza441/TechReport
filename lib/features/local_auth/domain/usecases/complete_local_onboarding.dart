import '../entities/sessao_local.dart';
import '../entities/tecnico_local.dart';
import '../repositories/sessao_local_repository.dart';
import '../repositories/tecnico_local_repository.dart';
import '../repositories/pin_secret_repository.dart';

class CompleteLocalOnboardingInput {
  const CompleteLocalOnboardingInput({
    required this.nome,
    required this.email,
    this.telefone,
    this.empresaNome,
    required this.usePin,
    this.pin,
  });

  final String nome;
  final String email;
  final String? telefone;
  final String? empresaNome;
  final bool usePin;
  final String? pin;
}

class CompleteLocalOnboarding {
  CompleteLocalOnboarding({
    required TecnicoLocalRepository tecnicoLocalRepository,
    required SessaoLocalRepository sessaoLocalRepository,
    required PinSecretRepository pinSecretRepository,
  }) : _tecnicoLocalRepository = tecnicoLocalRepository,
       _sessaoLocalRepository = sessaoLocalRepository,
       _pinSecretRepository = pinSecretRepository;

  final TecnicoLocalRepository _tecnicoLocalRepository;
  final SessaoLocalRepository _sessaoLocalRepository;
  final PinSecretRepository _pinSecretRepository;

  Future<SessaoLocal> call(CompleteLocalOnboardingInput input) async {
    final now = DateTime.now();
    final tecnicoId = 'tec-local-001';

    final tecnico = TecnicoLocal(
      id: tecnicoId,
      nome: input.nome.trim(),
      email: input.email.trim(),
      telefone: _normalizeOptional(input.telefone),
      empresaNome: _normalizeOptional(input.empresaNome),
      assinaturaPadraoRef: null,
      pinConfigured: input.usePin,
      biometriaHabilitada: false,
      createdAt: now,
      updatedAt: now,
    );

    final session = SessaoLocal(
      id: 'sessao-local-001',
      tecnicoLocalId: tecnico.id,
      status: SessaoLocalStatus.unlocked,
      pinConfigured: input.usePin,
      biometriaDisponivel: false,
      biometriaHabilitada: false,
      onboardingConcluido: true,
      lastUnlockedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    if (input.usePin && input.pin != null) {
      await _pinSecretRepository.savePin(input.pin!.trim());
    }

    await _tecnicoLocalRepository.save(tecnico);
    await _sessaoLocalRepository.saveSession(session);
    return session;
  }

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
