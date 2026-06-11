import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:techreport/app/theme/app_theme_repository.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/app/theme/app_theme_view_model.dart';
import 'package:techreport/features/local_auth/domain/usecases/update_tecnico_local.dart';
import 'package:techreport/features/company_admin/data/repositories/supabase_company_admin_repository.dart';
import 'package:techreport/features/company_admin/domain/usecases/cancel_tecnico_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/create_admin_empresa.dart';
import 'package:techreport/features/company_admin/domain/usecases/create_empresa_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/create_tecnico_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/get_admin_empresa.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_admin_convites.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_admin_empresas.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_admin_tecnicos.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_empresa_admin_convites.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_empresa_admins.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_admin_empresa.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_empresa_admin.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_tecnico_equipe.dart';
import 'package:techreport/features/local_auth/data/repositories/drift_sessao_local_repository.dart';
import 'package:techreport/features/local_auth/data/repositories/drift_tecnico_local_repository.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_service.dart';
import 'package:techreport/features/local_auth/data/services/local_data_export_share_service.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_backup.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_backup.dart';
import 'package:techreport/features/rat/data/repositories/drift_rat_repository.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/repositories/remote_rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/data/repositories/drift_assinatura_repository.dart';
import 'package:techreport/features/signature/data/repositories/supabase_remote_assinatura_repository.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/sync/data/repositories/drift_sync_queue_repository.dart';
import 'package:techreport/features/rat/data/repositories/supabase_remote_rat_repository.dart';
import 'package:techreport/features/sync/data/repositories/local_sync_checkpoint_repository.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/repositories/sync_checkpoint_repository.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:techreport/features/sync/domain/usecases/download_remote_rats.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';
import 'package:techreport/shared/infra/database/open_encrypted_database.dart';
import 'package:techreport/shared/infra/debug/local_database_debug_log.dart';
import 'package:techreport/shared/infra/security/local_pin_secret_store.dart';

import 'package:techreport/features/company_auth/data/repositories/local_remote_endpoint_repository.dart';
import 'package:techreport/features/company_auth/data/repositories/local_remote_session_repository.dart';
import 'package:techreport/features/company_auth/data/repositories/supabase_auth_repository.dart';
import 'package:techreport/features/company_auth/data/services/flutter_secure_token_store.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';

import 'package:techreport/features/company_auth/data/repositories/local_app_mode_repository.dart';
import 'package:techreport/features/company_auth/domain/usecases/bootstrap_company_session.dart';
import 'package:techreport/features/company_auth/domain/usecases/change_company_password.dart';
import 'package:techreport/features/company_auth/domain/usecases/select_app_mode.dart';
import 'package:techreport/features/company_auth/domain/usecases/sign_in_company.dart';
import 'package:techreport/features/company_auth/domain/usecases/sign_in_company_with_invite.dart';
import 'package:techreport/features/company_auth/domain/usecases/sign_out_company.dart';

import '../../features/local_auth/domain/repositories/sessao_local_repository.dart';
import '../../features/local_auth/domain/repositories/tecnico_local_repository.dart';
import '../../features/local_auth/domain/usecases/bootstrap_local_session.dart';
import '../../features/local_auth/domain/usecases/change_local_pin.dart';
import '../../features/local_auth/domain/usecases/complete_local_onboarding.dart';
import '../../features/local_auth/domain/usecases/lock_local_session.dart';
import '../../features/local_auth/domain/usecases/unlock_local_session.dart';
import '../../features/local_auth/presentation/view_models/app_session_view_model.dart';
import '../../shared/infra/database/tech_report_local_database.dart';

class AppScope {
  AppScope({
    required this.database,
    required this.assinaturaRepository,
    required this.applyLocalDataImport,
    required this.localDataImportParser,
    required this.localSignatureAssetStore,
    required this.localDataExportShareService,
    required this.previewLocalDataImport,
    required this.ratPdfShareService,
    required this.ratRepository,
    required this.sessaoLocalRepository,
    required this.shareRatLocally,
    required this.tecnicoLocalRepository,
    required this.updateTecnicoLocal,
    required this.appSessionViewModel,
    required this.remoteEndpointRepository,
    required this.supabaseClientFactory,
    required this.listAdminEmpresas,
    required this.createAdminEmpresa,
    required this.createEmpresaConvite,
    required this.updateAdminEmpresa,
    required this.listAdminTecnicos,
    required this.listAdminConvites,
    required this.createTecnicoConvite,
    required this.cancelTecnicoConvite,
    required this.updateTecnicoEquipe,
    required this.listEmpresaAdmins,
    required this.listEmpresaAdminConvites,
    required this.updateEmpresaAdmin,
    required this.signInCompanyWithInvite,
    required this.syncQueueRepository,
    required this.remoteRatRepository,
    required this.enqueueRatSync,
    required this.enqueueAssinaturaSync,
    required this.processSyncQueue,
    required this.secureTokenStore,
    required this.remoteSessionRepository,
    required this.authRepository,
    required this.appModeRepository,
    required this.selectAppMode,
    required this.bootstrapCompanySession,
    required this.changeCompanyPassword,
    required this.signInCompany,
    required this.signOutCompany,
    required this.syncCheckpointRepository,
    required this.downloadRemoteRats,
    required this.localBackupService,
    required this.localBackupParser,
    required this.previewLocalBackup,
    required this.applyLocalBackup,
    required this.appThemeViewModel,
    required this.companySessionNotifier,
    required this.getAdminEmpresa,
  });

  static Future<AppScope> create() async {
    LocalDatabaseDebugLog.info('appScope.create.start');
    try {
      LocalDatabaseDebugLog.info('appScope.database.build.start');
      final database = await buildEncryptedDatabase();
      LocalDatabaseDebugLog.info('appScope.database.build.done');
      LocalDatabaseDebugLog.info('appScope.repositories.create.start');

      final pinSecretRepository = LocalPinSecretStore();
      final tecnicoLocalRepository = DriftTecnicoLocalRepository(database);
      final updateTecnicoLocal = UpdateTecnicoLocal(tecnicoLocalRepository);
      final sessaoLocalRepository = DriftSessaoLocalRepository(database);
      final ratRepository = DriftRatRepository(database);
      final assinaturaRepository = DriftAssinaturaRepository(database);
      final localSignatureAssetStore = LocalSignatureAssetStore();
      final localDataExportShareService = LocalDataExportShareService(
        ratRepository: ratRepository,
        assinaturaRepository: assinaturaRepository,
        localSignatureAssetStore: localSignatureAssetStore,
      );
      final localDataImportParser = LocalDataImportParser();
      final previewLocalDataImport = PreviewLocalDataImport(
        ratRepository: ratRepository,
      );
      final applyLocalDataImport = ApplyLocalDataImport(
        ratRepository: ratRepository,
        assinaturaRepository: assinaturaRepository,
      );
      final localBackupParser = LocalBackupParser(
        legacyParser: localDataImportParser,
      );
      final localBackupService = LocalBackupService(
        ratRepository: ratRepository,
        assinaturaRepository: assinaturaRepository,
        localSignatureAssetStore: localSignatureAssetStore,
      );
      final previewLocalBackup = PreviewLocalBackup(parser: localBackupParser);
      final applyLocalBackup = ApplyLocalBackup(
        parser: localBackupParser,
        applyLocalDataImport: applyLocalDataImport,
      );
      final shareRatLocally = ShareRatLocally(
        ratRepository: ratRepository,
        assinaturaRepository: assinaturaRepository,
      );
      final ratPdfShareService = RatPdfShareService(
        assinaturaRepository: assinaturaRepository,
      );
      final remoteEndpointRepository = LocalRemoteEndpointRepository();
      final secureTokenStore = FlutterSecureTokenStore();

      final supabaseClientFactory = SupabaseClientFactory(
        endpointRepository: remoteEndpointRepository,
        tokenStore: secureTokenStore,
      );
      final companyAdminRepository = SupabaseCompanyAdminRepository(
        clientFactory: supabaseClientFactory,
      );

      final listAdminEmpresas = ListAdminEmpresas(companyAdminRepository);
      final createAdminEmpresa = CreateAdminEmpresa(companyAdminRepository);
      final createEmpresaConvite = CreateEmpresaConvite(companyAdminRepository);
      final updateAdminEmpresa = UpdateAdminEmpresa(companyAdminRepository);
      final listAdminTecnicos = ListAdminTecnicos(companyAdminRepository);
      final listAdminConvites = ListAdminConvites(companyAdminRepository);
      final createTecnicoConvite = CreateTecnicoConvite(companyAdminRepository);
      final cancelTecnicoConvite = CancelTecnicoConvite(companyAdminRepository);
      final updateTecnicoEquipe = UpdateTecnicoEquipe(companyAdminRepository);
      final listEmpresaAdmins = ListEmpresaAdmins(companyAdminRepository);
      final listEmpresaAdminConvites = ListEmpresaAdminConvites(
        companyAdminRepository,
      );
      final updateEmpresaAdmin = UpdateEmpresaAdmin(companyAdminRepository);
      final getAdminEmpresa = GetAdminEmpresa(companyAdminRepository);
      final syncQueueRepository = DriftSyncQueueRepository(database);
      final remoteRatRepository = SupabaseRemoteRatRepository(
        clientFactory: supabaseClientFactory,
      );
      final remoteAssinaturaRepository = SupabaseRemoteAssinaturaRepository(
        clientFactory: supabaseClientFactory,
      );
      final enqueueRatSync = EnqueueRatSync(
        queueRepository: syncQueueRepository,
      );
      final enqueueAssinaturaSync = EnqueueAssinaturaSync(
        queueRepository: syncQueueRepository,
      );
      final syncCheckpointRepository = LocalSyncCheckpointRepository();
      final downloadRemoteRats = DownloadRemoteRats(
        remoteRatRepository: remoteRatRepository,
        ratRepository: ratRepository,
        checkpointRepository: syncCheckpointRepository,
      );
      final processSyncQueue = ProcessSyncQueue(
        queueRepository: syncQueueRepository,
        remoteRatRepository: remoteRatRepository,
        ratRepository: ratRepository,
        assinaturaRepository: assinaturaRepository,
        remoteAssinaturaRepository: remoteAssinaturaRepository,
      );
      final remoteSessionRepository = LocalRemoteSessionRepository();
      final authRepository = SupabaseAuthRepository(
        clientFactory: supabaseClientFactory,
        tokenStore: secureTokenStore,
        remoteSessionRepository: remoteSessionRepository,
      );

      // Session reativo para atualizar o perfil sem precisar relogar.
      final companySessionNotifier = ValueNotifier<SessaoRemota?>(null);
      // Inicializa com a sessão salva.
      final initialSession = await remoteSessionRepository.getSession();
      companySessionNotifier.value = initialSession;
      final appModeRepository = LocalAppModeRepository();
      final selectAppMode = SelectAppMode(appModeRepository);

      final bootstrapCompanySession = BootstrapCompanySession(
        appModeRepository: appModeRepository,
        authRepository: authRepository,
      );
      final changeCompanyPassword = ChangeCompanyPassword(
        authRepository: authRepository,
      );
      final signInCompany = SignInCompany(
        authRepository: authRepository,
        remoteSessionRepository: remoteSessionRepository,
        appModeRepository: appModeRepository,
      );

      final signInCompanyWithInvite = SignInCompanyWithInvite(
        authRepository: authRepository,
        remoteSessionRepository: remoteSessionRepository,
        appModeRepository: appModeRepository,
      );

      final signOutCompany = SignOutCompany(
        authRepository: authRepository,
        remoteSessionRepository: remoteSessionRepository,
        appModeRepository: appModeRepository,
      );

      final appThemeRepository = AppThemeRepository();
      final appThemeViewModel = AppThemeViewModel(
        repository: appThemeRepository,
      );
      await appThemeViewModel.load();

      final scope = AppScope(
        database: database,
        assinaturaRepository: assinaturaRepository,
        applyLocalDataImport: applyLocalDataImport,
        localDataImportParser: localDataImportParser,
        localSignatureAssetStore: localSignatureAssetStore,
        localDataExportShareService: localDataExportShareService,
        previewLocalDataImport: previewLocalDataImport,
        ratPdfShareService: ratPdfShareService,
        sessaoLocalRepository: sessaoLocalRepository,
        shareRatLocally: shareRatLocally,
        tecnicoLocalRepository: tecnicoLocalRepository,
        updateTecnicoLocal: updateTecnicoLocal,
        ratRepository: ratRepository,
        appSessionViewModel: AppSessionViewModel(
          bootstrapLocalSession: BootstrapLocalSession(sessaoLocalRepository),
          changeLocalPin: ChangeLocalPin(
            pinSecretRepository: pinSecretRepository,
            sessaoLocalRepository: sessaoLocalRepository,
            tecnicoLocalRepository: tecnicoLocalRepository,
          ),
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
        listAdminEmpresas: listAdminEmpresas,
        createAdminEmpresa: createAdminEmpresa,
        createEmpresaConvite: createEmpresaConvite,
        updateAdminEmpresa: updateAdminEmpresa,
        listAdminTecnicos: listAdminTecnicos,
        listAdminConvites: listAdminConvites,
        createTecnicoConvite: createTecnicoConvite,
        cancelTecnicoConvite: cancelTecnicoConvite,
        updateTecnicoEquipe: updateTecnicoEquipe,
        listEmpresaAdmins: listEmpresaAdmins,
        listEmpresaAdminConvites: listEmpresaAdminConvites,
        updateEmpresaAdmin: updateEmpresaAdmin,
        signInCompanyWithInvite: signInCompanyWithInvite,
        syncQueueRepository: syncQueueRepository,
        syncCheckpointRepository: syncCheckpointRepository,
        downloadRemoteRats: downloadRemoteRats,
        remoteRatRepository: remoteRatRepository,
        enqueueRatSync: enqueueRatSync,
        enqueueAssinaturaSync: enqueueAssinaturaSync,
        processSyncQueue: processSyncQueue,
        secureTokenStore: secureTokenStore,
        remoteSessionRepository: remoteSessionRepository,
        authRepository: authRepository,
        appModeRepository: appModeRepository,
        selectAppMode: selectAppMode,
        bootstrapCompanySession: bootstrapCompanySession,
        changeCompanyPassword: changeCompanyPassword,
        signInCompany: signInCompany,
        signOutCompany: signOutCompany,
        localBackupService: localBackupService,
        localBackupParser: localBackupParser,
        previewLocalBackup: previewLocalBackup,
        applyLocalBackup: applyLocalBackup,
        appThemeViewModel: appThemeViewModel,
        companySessionNotifier: companySessionNotifier,
        getAdminEmpresa: getAdminEmpresa,
      );

      LocalDatabaseDebugLog.info('appScope.create.done');
      return scope;
    } catch (error, stackTrace) {
      LocalDatabaseDebugLog.error(
        'appScope.create.failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  final TechReportLocalDatabase database;
  final AssinaturaRepository assinaturaRepository;
  final ApplyLocalDataImport applyLocalDataImport;
  final LocalDataImportParser localDataImportParser;
  final LocalSignatureAssetStore localSignatureAssetStore;
  final LocalDataExportShareService localDataExportShareService;
  final PreviewLocalDataImport previewLocalDataImport;
  final RatPdfShareService ratPdfShareService;
  final SessaoLocalRepository sessaoLocalRepository;
  final ShareRatLocally shareRatLocally;
  final TecnicoLocalRepository tecnicoLocalRepository;
  final UpdateTecnicoLocal updateTecnicoLocal;
  final RatRepository ratRepository;
  final AppSessionViewModel appSessionViewModel;
  final LocalRemoteEndpointRepository remoteEndpointRepository;
  final SupabaseClientFactory supabaseClientFactory;
  final ListAdminEmpresas listAdminEmpresas;
  final CreateAdminEmpresa createAdminEmpresa;
  final CreateEmpresaConvite createEmpresaConvite;
  final UpdateAdminEmpresa updateAdminEmpresa;
  final ListAdminTecnicos listAdminTecnicos;
  final ListAdminConvites listAdminConvites;
  final CreateTecnicoConvite createTecnicoConvite;
  final CancelTecnicoConvite cancelTecnicoConvite;
  final UpdateTecnicoEquipe updateTecnicoEquipe;
  final ListEmpresaAdmins listEmpresaAdmins;
  final ListEmpresaAdminConvites listEmpresaAdminConvites;
  final UpdateEmpresaAdmin updateEmpresaAdmin;
  final SignInCompanyWithInvite signInCompanyWithInvite;
  final SyncQueueRepository syncQueueRepository;
  final RemoteRatRepository remoteRatRepository;
  final EnqueueRatSync enqueueRatSync;
  final EnqueueAssinaturaSync enqueueAssinaturaSync;
  final ProcessSyncQueue processSyncQueue;
  final FlutterSecureTokenStore secureTokenStore;
  final LocalRemoteSessionRepository remoteSessionRepository;
  final SupabaseAuthRepository authRepository;
  final LocalAppModeRepository appModeRepository;
  final SelectAppMode selectAppMode;
  final BootstrapCompanySession bootstrapCompanySession;
  final ChangeCompanyPassword changeCompanyPassword;
  final SignInCompany signInCompany;
  final SignOutCompany signOutCompany;
  final SyncCheckpointRepository syncCheckpointRepository;
  final DownloadRemoteRats downloadRemoteRats;
  final LocalBackupService localBackupService;
  final LocalBackupParser localBackupParser;
  final PreviewLocalBackup previewLocalBackup;
  final ApplyLocalBackup applyLocalBackup;
  final AppThemeViewModel appThemeViewModel;
  final ValueNotifier<SessaoRemota?> companySessionNotifier;
  final GetAdminEmpresa getAdminEmpresa;

  Future<void> dispose() async {
    companySessionNotifier.dispose();
    await database.close();
  }
}
