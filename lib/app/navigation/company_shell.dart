import 'package:flutter/material.dart';
import 'package:techreport/app/di/app_scope.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/presentation/screens/admin_empresa_area.dart';
import 'package:techreport/features/company_admin/presentation/screens/app_admin_area.dart';
import 'package:techreport/features/company_admin/presentation/view_models/admin_empresa_view_model.dart';
import 'package:techreport/features/company_admin/presentation/view_models/app_admin_view_model.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/presentation/screens/company_home_screen.dart';
import 'package:techreport/features/rat/presentation/screens/rat_list_screen.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_view_model.dart';
import 'package:techreport/features/sync/presentation/screens/sync_center_screen.dart';
import 'package:techreport/features/sync/presentation/view_models/sync_center_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_mode_title.dart';
import 'package:techreport/shared/presentation/widgets/hierarchical_background.dart';

enum CompanyArea { rats, profile, adminEmpresa, appAdmin }

enum LogoutPendingDecision { syncBeforeExit, exitAnyway, cancel }

String _companyAreaLabel(CompanyArea area) {
  switch (area) {
    case CompanyArea.rats:
      return 'RATs';
    case CompanyArea.profile:
      return 'Meu perfil';
    case CompanyArea.adminEmpresa:
      return 'Equipe';
    case CompanyArea.appAdmin:
      return 'Admin';
  }
}

IconData _companyAreaIcon(CompanyArea area) {
  switch (area) {
    case CompanyArea.rats:
      return Icons.assignment_outlined;
    case CompanyArea.profile:
      return Icons.person_outline;
    case CompanyArea.adminEmpresa:
      return Icons.groups_outlined;
    case CompanyArea.appAdmin:
      return Icons.admin_panel_settings_outlined;
  }
}

class CompanyShell extends StatefulWidget {
  const CompanyShell({
    super.key,
    required this.scope,
    required this.sessionNotifier,
    required this.onSignOut,
  });

  final AppScope scope;
  final ValueNotifier<SessaoRemota?> sessionNotifier;
  final Future<void> Function() onSignOut;

  @override
  State<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends State<CompanyShell> {
  SessaoRemota? get session => widget.sessionNotifier.value;

  late CompanyArea _selectedArea;
  RatListViewModel? _ratListViewModel;
  AdminEmpresaViewModel? _adminEmpresaViewModel;
  AppAdminViewModel? _appAdminViewModel;
  bool _isSyncing = false;
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    final currentSession = session;
    if (currentSession == null) {
      await widget.onSignOut();
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      final empresaId = currentSession.empresaId;

      if (empresaId == null || !currentSession.hasCompanyContext) {
        await widget.onSignOut();
        return;
      }
      final pendingCount = await widget.scope.syncQueueRepository.countPending(
        empresaId: empresaId,
        usuarioId: currentSession.usuarioId,
      );

      if (pendingCount == 0) {
        final confirmed = await _showExitConfirmation();
        if (confirmed != true) {
          if (mounted) setState(() { _isSigningOut = false; });
          return;
        }
        await widget.onSignOut();
        return;
      }

      final decision = await _showLogoutPendingDialog(pendingCount);
      if (decision == null || decision == LogoutPendingDecision.cancel) {
        return;
      }

      if (decision == LogoutPendingDecision.exitAnyway) {
        await widget.onSignOut();
        return;
      }
      await _syncNow();
      final remainingCount = await widget.scope.syncQueueRepository
          .countPending(
            empresaId: empresaId,
            usuarioId: currentSession.usuarioId,
          );
      if (remainingCount == 0) {
        await widget.onSignOut();
        return;
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ainda há $remainingCount item(ns) aguardando sincronização.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  Future<bool?> _showExitConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da empresa?'),
        content: const Text(
          'Você precisará entrar novamente com e-mail e senha. '
          'O servidor configurado continuará salvo neste dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Future<LogoutPendingDecision?> _showLogoutPendingDialog(int count) {
    return showDialog<LogoutPendingDecision>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair com pendências?'),
          content: Text(
            'Você tem $count item(ns) aguardando sincronização. '
            'Sincronize antes de sair para reduzir risco de dados ficarem '
            'apenas neste aparelho.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(LogoutPendingDecision.cancel),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(LogoutPendingDecision.exitAnyway),
              child: const Text('Sair mesmo assim'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(LogoutPendingDecision.syncBeforeExit),
              child: const Text('Sincronizar antes'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    widget.sessionNotifier.addListener(_onSessionChanged);
    final currentSession = session;
    if (currentSession != null) {
      _selectedArea = _initialArea(currentSession);
      _ratListViewModel = _createRatListViewModel(currentSession);
      // Auto-retry: processa fila pendente ao iniciar
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncNow());
    } else {
      _selectedArea = CompanyArea.profile;
    }
  }

  @override
  void didUpdateWidget(covariant CompanyShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionNotifier != widget.sessionNotifier) {
      oldWidget.sessionNotifier.removeListener(_onSessionChanged);
      widget.sessionNotifier.addListener(_onSessionChanged);
    }
    _ratListViewModel?.dispose();
    _adminEmpresaViewModel?.dispose();
    _appAdminViewModel?.dispose();
    _ratListViewModel = null;
    _adminEmpresaViewModel = null;
    _appAdminViewModel = null;
    final currentSession = session;
    if (currentSession != null) {
      _ratListViewModel = _createRatListViewModel(currentSession);
      _selectedArea = _initialArea(currentSession);
    }
  }

  @override
  void dispose() {
    widget.sessionNotifier.removeListener(_onSessionChanged);
    _ratListViewModel?.dispose();
    _adminEmpresaViewModel?.dispose();
    _appAdminViewModel?.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentSession = session;
    if (currentSession == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final areas = _areasFor(currentSession);
    if (!areas.contains(_selectedArea)) {
      _selectedArea = areas.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const TechReportModeTitle(modeLabel: 'Modo Empresa'),
        bottom: _isSigningOut
            ? const PreferredSize(
                preferredSize: Size.zero,
                child: LinearProgressIndicator(),
              )
            : null,
        actions: [
          if (_selectedArea == CompanyArea.rats && _ratListViewModel != null)
            IconButton(
              onPressed: _isSyncing || _isSigningOut ? null : _syncNow,
              icon: _isSyncing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Sincronizar',
            ),
          if (currentSession.hasCompanyContext)
            Semantics(
              label: 'Acessar central de sincronização',
              button: true,
              child: IconButton(
                onPressed: _isSyncing || _isSigningOut ? null : _openSyncCenter,
                icon: const Icon(Icons.sync_alt_outlined),
                tooltip: 'Central de sincronização',
              ),
            ),
          IconButton(
            onPressed: _isSigningOut ? null : _signOut,
            icon: _isSigningOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: HierarchicalBackground(
        child: _buildArea(_selectedArea, currentSession),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: areas.indexOf(_selectedArea),
        onDestinationSelected: (index) {
          setState(() {
            _selectedArea = areas[index];
          });
        },
        destinations: [
          for (final area in areas)
            NavigationDestination(
              icon: Icon(_companyAreaIcon(area)),
              label: _companyAreaLabel(area),
            ),
        ],
      ),
    );
  }

  CompanyArea _initialArea(SessaoRemota session) {
    if (session.hasCompanyContext) {
      return CompanyArea.rats;
    }

    if (session.isAppAdmin) {
      return CompanyArea.appAdmin;
    }

    return CompanyArea.profile;
  }

  List<CompanyArea> _areasFor(SessaoRemota session) {
    return [
      if (session.hasCompanyContext) CompanyArea.rats,
      if (session.hasCompanyContext &&
          (session.isAdminEmpresa || session.isGerente))
        CompanyArea.adminEmpresa,
      if (session.isAppAdmin) CompanyArea.appAdmin,
      CompanyArea.profile,
    ];
  }

  Widget _buildArea(CompanyArea area, SessaoRemota currentSession) {
    switch (area) {
      case CompanyArea.rats:
        return _buildRatsArea(currentSession);
      case CompanyArea.profile:
        return CompanyHomeScreen(
          sessionNotifier: widget.sessionNotifier,
          scope: widget.scope,
          changePassword: widget.scope.changeCompanyPassword,
          onPasswordChanged: widget.onSignOut,
          themeViewModel: widget.scope.appThemeViewModel,
        );
      case CompanyArea.adminEmpresa:
        final empresaId = currentSession.empresaId!;
        if (_adminEmpresaViewModel?.empresaId != empresaId) {
          _adminEmpresaViewModel?.dispose();
          _adminEmpresaViewModel = AdminEmpresaViewModel(
            empresaId: empresaId,
            currentTecnicoId: currentSession.tecnicoId,
            currentPapel: _adminPapelFor(currentSession),
            listTecnicos: widget.scope.listAdminTecnicos,
            listConvites: widget.scope.listAdminConvites,
            createTecnicoConvite: widget.scope.createTecnicoConvite,
            cancelTecnicoConvite: widget.scope.cancelTecnicoConvite,
            updateTecnicoEquipe: widget.scope.updateTecnicoEquipe,
            getAdminEmpresa: widget.scope.getAdminEmpresa,
            updateAdminEmpresa: widget.scope.updateAdminEmpresa,
          );
        }
        return AdminEmpresaArea(
          viewModel: _adminEmpresaViewModel!,
        );
      case CompanyArea.appAdmin:
        if (_appAdminViewModel == null) {
          _appAdminViewModel = AppAdminViewModel(
            listEmpresas: widget.scope.listAdminEmpresas,
            createEmpresa: widget.scope.createAdminEmpresa,
            createEmpresaConvite: widget.scope.createEmpresaConvite,
            updateEmpresa: widget.scope.updateAdminEmpresa,
          );
        }
        return AppAdminArea(
          viewModel: _appAdminViewModel!,
          listEmpresaAdmins: widget.scope.listEmpresaAdmins,
          listEmpresaAdminConvites: widget.scope.listEmpresaAdminConvites,
          createEmpresaConvite: widget.scope.createEmpresaConvite,
          cancelTecnicoConvite: widget.scope.cancelTecnicoConvite,
          updateEmpresaAdmin: widget.scope.updateEmpresaAdmin,
          updateAdminEmpresa: widget.scope.updateAdminEmpresa,
        );
    }
  }

  AdminTecnicoPapel _adminPapelFor(SessaoRemota session) {
    return switch (session.papelEmpresa) {
      SessaoRemotaPapelEmpresa.adminEmpresa => AdminTecnicoPapel.adminEmpresa,
      SessaoRemotaPapelEmpresa.gerente => AdminTecnicoPapel.gerente,
      _ => AdminTecnicoPapel.tecnico,
    };
  }

  Widget _buildRatsArea(SessaoRemota currentSession) {
    final viewModel = _ratListViewModel;
    if (viewModel == null) {
      return const Center(child: Text('Sessão sem empresa vinculada.'));
    }

    return Scaffold(
      body: RatListScreen(
        viewModel: viewModel,
        assinaturaRepository: widget.scope.assinaturaRepository,
        localSignatureAssetStore: widget.scope.localSignatureAssetStore,
        ratPdfShareService: widget.scope.ratPdfShareService,
        ratRepository: widget.scope.ratRepository,
        shareRatLocally: widget.scope.shareRatLocally,
        remoteSession: currentSession,
        enqueueRatSync: widget.scope.enqueueRatSync,
        enqueueAssinaturaSync: widget.scope.enqueueAssinaturaSync,
        processSyncQueue: widget.scope.processSyncQueue,
        downloadRemoteRats: widget.scope.downloadRemoteRats,
        supabaseClientFactory: widget.scope.supabaseClientFactory,
        embedded: true,
      ),
    );
  }

  RatListViewModel? _createRatListViewModel(SessaoRemota session) {
    if (!session.hasCompanyContext) {
      return null;
    }

    return RatListViewModel(
      assinaturaRepository: widget.scope.assinaturaRepository,
      ratRepository: widget.scope.ratRepository,
      scope: _ratListScopeFor(session),
    );
  }

  RatListScope _ratListScopeFor(SessaoRemota session) {
    final empresaId = session.empresaId!;

    if (session.isGerente || session.isAdminEmpresa) {
      return RatListScope.companyManager(empresaId: empresaId);
    }

    final tecnicoId = session.tecnicoId;
    if (tecnicoId == null) {
      return RatListScope.companyManager(empresaId: empresaId);
    }

    return RatListScope.companyTechnician(
      empresaId: empresaId,
      tecnicoId: tecnicoId,
    );
  }

  Future<void> _syncNow() async {
    final currentSession = session;
    if (currentSession == null) return;

    final empresaId = currentSession.empresaId;
    if (empresaId == null || !currentSession.hasCompanyContext) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    final papel =
        currentSession.papelEmpresa?.name ??
        currentSession.papelGlobal?.name ??
        'unknown';

    try {
      await widget.scope.processSyncQueue.call(
        empresaId: empresaId,
        usuarioId: currentSession.usuarioId,
        retryFailed: true,
      );
      await widget.scope.downloadRemoteRats.call(
        empresaId: empresaId,
        usuarioId: currentSession.usuarioId,
        papel: papel,
      );
      await _ratListViewModel?.load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível sincronizar.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _openSyncCenter() {
    final currentSession = session;
    if (currentSession == null) return;

    final empresaId = currentSession.empresaId;
    if (empresaId == null) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SyncCenterScreen(
          viewModel: SyncCenterViewModel(
            queueRepository: widget.scope.syncQueueRepository,
            processSyncQueue: widget.scope.processSyncQueue,
            ratRepository: widget.scope.ratRepository,
            empresaId: empresaId,
            usuarioId: currentSession.usuarioId,
            onSyncComplete: () => _ratListViewModel?.load(),
          ),
        ),
      ),
    );
  }
}
