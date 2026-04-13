import 'package:techreport/features/local_auth/data/repositories/drift_sessao_local_repository.dart';
import 'package:techreport/features/local_auth/data/repositories/drift_tecnico_local_repository.dart';
import 'package:techreport/features/rat/data/repositories/drift_rat_repository.dart';
import 'package:techreport/features/rat/data/repositories/rat_repository.dart';
import 'package:techreport/shared/infra/security/local_pin_secret_store.dart';

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
    required this.ratRepository,
    required this.sessaoLocalRepository,
    required this.tecnicoLocalRepository,
    required this.appSessionViewModel,
  });

  factory AppScope.create() {
    final database = TechReportLocalDatabase();
    final pinSecretRepository = LocalPinSecretStore();
    final tecnicoLocalRepository = DriftTecnicoLocalRepository(database);
    final sessaoLocalRepository = DriftSessaoLocalRepository(database);
    final ratRepository = DriftRatRepository(database);

    return AppScope(
      database: database,
      sessaoLocalRepository: sessaoLocalRepository,
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
    );
  }

  final TechReportLocalDatabase database;
  final SessaoLocalRepository sessaoLocalRepository;
  final TecnicoLocalRepository tecnicoLocalRepository;
  final RatRepository ratRepository;
  final AppSessionViewModel appSessionViewModel;

  Future<void> dispose() async {
    await database.close();
  }
}
