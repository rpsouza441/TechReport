import 'package:techreport/features/local_auth/data/repositories/drift_sessao_local_repository.dart';
import 'package:techreport/features/local_auth/data/repositories/drift_tecnico_local_repository.dart';
import 'package:techreport/features/rat/data/repositories/drift_rat_repository.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/data/repositories/drift_assinatura_repository.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/shared/infra/security/local_pin_secret_store.dart';

import 'package:techreport/features/company_auth/data/repositories/local_remote_endpoint_repository.dart';
import 'package:techreport/features/company_auth/data/repositories/local_remote_session_repository.dart';
import 'package:techreport/features/company_auth/data/repositories/supabase_auth_repository.dart';
import 'package:techreport/features/company_auth/data/services/flutter_secure_token_store.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';

import '../../features/local_auth/domain/repositories/sessao_local_repository.dart';
import '../../features/local_auth/domain/repositories/tecnico_local_repository.dart';
import '../../features/local_auth/domain/usecases/bootstrap_local_session.dart';
import '../../features/local_auth/domain/usecases/complete_local_onboarding.dart';
import '../../features/local_auth/domain/usecases/lock_local_session.dart';
import '../../features/local_auth/domain/usecases/unlock_local_session.dart';
import '../../features/local_auth/presentation/view_models/app_session_view_model.dart';
import '../../shared/infra/database/tech_report_local_database.dart';

class AppScope {
  AppScope({
    required this.database,
    required this.assinaturaRepository,
    required this.localSignatureAssetStore,
    required this.ratPdfShareService,
    required this.ratRepository,
    required this.sessaoLocalRepository,
    required this.shareRatLocally,
    required this.tecnicoLocalRepository,
    required this.appSessionViewModel,
    required this.remoteEndpointRepository,
    required this.supabaseClientFactory,
    required this.secureTokenStore,
    required this.remoteSessionRepository,
    required this.authRepository,
  });

  factory AppScope.create() {
    final database = TechReportLocalDatabase();
    final pinSecretRepository = LocalPinSecretStore();
    final tecnicoLocalRepository = DriftTecnicoLocalRepository(database);
    final sessaoLocalRepository = DriftSessaoLocalRepository(database);
    final ratRepository = DriftRatRepository(database);
    final assinaturaRepository = DriftAssinaturaRepository(database);
    final localSignatureAssetStore = LocalSignatureAssetStore();
    final shareRatLocally = ShareRatLocally(
      ratRepository: ratRepository,
      assinaturaRepository: assinaturaRepository,
    );
    final ratPdfShareService = RatPdfShareService(
      localSignatureAssetStore: localSignatureAssetStore,
    );
    final remoteEndpointRepository = LocalRemoteEndpointRepository();

    final supabaseClientFactory = SupabaseClientFactory(
      endpointRepository: remoteEndpointRepository,
    );
    final secureTokenStore = FlutterSecureTokenStore();
    final remoteSessionRepository = LocalRemoteSessionRepository();
    final authRepository = SupabaseAuthRepository(
      clientFactory: supabaseClientFactory,
      tokenStore: secureTokenStore,
      remoteSessionRepository: remoteSessionRepository,
    );

    return AppScope(
      database: database,
      assinaturaRepository: assinaturaRepository,
      localSignatureAssetStore: localSignatureAssetStore,
      ratPdfShareService: ratPdfShareService,
      sessaoLocalRepository: sessaoLocalRepository,
      shareRatLocally: shareRatLocally,
      tecnicoLocalRepository: tecnicoLocalRepository,
      ratRepository: ratRepository,
      appSessionViewModel: AppSessionViewModel(
        bootstrapLocalSession: BootstrapLocalSession(sessaoLocalRepository),
        completeLocalOnboarding: CompleteLocalOnboarding(
          pinSecretRepository: pinSecretRepository,
          tecnicoLocalRepository: tecnicoLocalRepository,
          sessaoLocalRepository: sessaoLocalRepository,
        ),
        lockLocalSession: LockLocalSession(sessaoLocalRepository),
        unlockLocalSession: UnlockLocalSession(
          sessaoLocalRepository,
          pinSecretRepository: pinSecretRepository,
        ),
      ),
      remoteEndpointRepository: remoteEndpointRepository,
      supabaseClientFactory: supabaseClientFactory,
      secureTokenStore: secureTokenStore,
      remoteSessionRepository: remoteSessionRepository,
      authRepository: authRepository,
    );
  }

  final TechReportLocalDatabase database;
  final AssinaturaRepository assinaturaRepository;
  final LocalSignatureAssetStore localSignatureAssetStore;
  final RatPdfShareService ratPdfShareService;
  final SessaoLocalRepository sessaoLocalRepository;
  final ShareRatLocally shareRatLocally;
  final TecnicoLocalRepository tecnicoLocalRepository;
  final RatRepository ratRepository;
  final AppSessionViewModel appSessionViewModel;
  final LocalRemoteEndpointRepository remoteEndpointRepository;
  final SupabaseClientFactory supabaseClientFactory;
  final FlutterSecureTokenStore secureTokenStore;
  final LocalRemoteSessionRepository remoteSessionRepository;
  final SupabaseAuthRepository authRepository;

  Future<void> dispose() async {
    await database.close();
  }
}
