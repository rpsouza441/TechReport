import 'package:techreport/features/local_auth/data/repositories/drift_sessao_local_repository.dart';
import 'package:techreport/features/local_auth/data/repositories/drift_tecnico_local_repository.dart';
import 'package:techreport/features/rat/data/repositories/drift_rat_repository.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/repositories/remote_rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/data/repositories/drift_assinatura_repository.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/sync/data/repositories/drift_sync_queue_repository.dart';
import 'package:techreport/features/rat/data/repositories/supabase_remote_rat_repository.dart';
import 'package:techreport/features/sync/data/repositories/local_sync_checkpoint_repository.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/repositories/sync_checkpoint_repository.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:techreport/features/sync/domain/usecases/download_remote_rats.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';
import 'package:techreport/shared/infra/security/local_pin_secret_store.dart';

import 'package:techreport/features/company_auth/data/repositories/local_remote_endpoint_repository.dart';
import 'package:techreport/features/company_auth/data/repositories/local_remote_session_repository.dart';
import 'package:techreport/features/company_auth/data/repositories/supabase_auth_repository.dart';
import 'package:techreport/features/company_auth/data/services/flutter_secure_token_store.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';

import 'package:techreport/features/company_auth/data/repositories/local_app_mode_repository.dart';
import 'package:techreport/features/company_auth/domain/usecases/bootstrap_company_session.dart';
import 'package:techreport/features/company_auth/domain/usecases/select_app_mode.dart';
import 'package:techreport/features/company_auth/domain/usecases/sign_in_company.dart';
import 'package:techreport/features/company_auth/domain/usecases/sign_out_company.dart';

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
    required this.syncQueueRepository,
    required this.remoteRatRepository,
    required this.enqueueRatSync,
    required this.processSyncQueue,
    required this.secureTokenStore,
    required this.remoteSessionRepository,
    required this.authRepository,
    required this.appModeRepository,
    required this.selectAppMode,
    required this.bootstrapCompanySession,
    required this.signInCompany,
    required this.signOutCompany,
    required this.syncCheckpointRepository,
    required this.downloadRemoteRats,
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
    final secureTokenStore = FlutterSecureTokenStore();

    final supabaseClientFactory = SupabaseClientFactory(
      endpointRepository: remoteEndpointRepository,
      tokenStore: secureTokenStore,
    );
    final syncQueueRepository = DriftSyncQueueRepository(database);
    final remoteRatRepository = SupabaseRemoteRatRepository(
      clientFactory: supabaseClientFactory,
    );
    final enqueueRatSync = EnqueueRatSync(queueRepository: syncQueueRepository);
    final syncCheckpointRepository = LocalSyncCheckpointRepository();
    final downloadRemoteRats = DownloadRemoteRats(
      remoteRatRepository: remoteRatRepository,
      ratRepository: ratRepository,
      checkpointRepository: syncCheckpointRepository,
    );
    final processSyncQueue = ProcessSyncQueue(
      queueRepository: syncQueueRepository,
      remoteRatRepository: remoteRatRepository,
    );
    final remoteSessionRepository = LocalRemoteSessionRepository();
    final authRepository = SupabaseAuthRepository(
      clientFactory: supabaseClientFactory,
      tokenStore: secureTokenStore,
      remoteSessionRepository: remoteSessionRepository,
    );
    final appModeRepository = LocalAppModeRepository();
    final selectAppMode = SelectAppMode(appModeRepository);

    final bootstrapCompanySession = BootstrapCompanySession(
      appModeRepository: appModeRepository,
      authRepository: authRepository,
    );
    final signInCompany = SignInCompany(
      authRepository: authRepository,
      remoteSessionRepository: remoteSessionRepository,
      appModeRepository: appModeRepository,
    );

    final signOutCompany = SignOutCompany(
      authRepository: authRepository,
      remoteSessionRepository: remoteSessionRepository,
      appModeRepository: appModeRepository,
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
      syncQueueRepository: syncQueueRepository,
      syncCheckpointRepository: syncCheckpointRepository,
      downloadRemoteRats: downloadRemoteRats,
      remoteRatRepository: remoteRatRepository,
      enqueueRatSync: enqueueRatSync,
      processSyncQueue: processSyncQueue,
      secureTokenStore: secureTokenStore,
      remoteSessionRepository: remoteSessionRepository,
      authRepository: authRepository,
      appModeRepository: appModeRepository,
      selectAppMode: selectAppMode,
      bootstrapCompanySession: bootstrapCompanySession,
      signInCompany: signInCompany,
      signOutCompany: signOutCompany,
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
  final SyncQueueRepository syncQueueRepository;
  final RemoteRatRepository remoteRatRepository;
  final EnqueueRatSync enqueueRatSync;
  final ProcessSyncQueue processSyncQueue;
  final FlutterSecureTokenStore secureTokenStore;
  final LocalRemoteSessionRepository remoteSessionRepository;
  final SupabaseAuthRepository authRepository;
  final LocalAppModeRepository appModeRepository;
  final SelectAppMode selectAppMode;
  final BootstrapCompanySession bootstrapCompanySession;
  final SignInCompany signInCompany;
  final SignOutCompany signOutCompany;
  final SyncCheckpointRepository syncCheckpointRepository;
  final DownloadRemoteRats downloadRemoteRats;

  Future<void> dispose() async {
    await database.close();
  }
}
