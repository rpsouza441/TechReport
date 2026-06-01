import 'package:flutter/material.dart';
import 'package:techreport/app/di/app_scope.dart';
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
    required this.session,
    required this.onSignOut,
  });

  final AppScope scope;
  final SessaoRemota session;
  final Future<void> Function() onSignOut;

  @override
  State<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends State<CompanyShell> {
  late CompanyArea _selectedArea;
  RatListViewModel? _ratListViewModel;
  bool _isSyncing = false;

  Future<void> _signOut() async {
    final session = widget.session;
    final empresaId = session.empresaId;

    if (empresaId == null || !session.hasCompanyContext) {
      await widget.onSignOut();
      return;
    }
    final pendingCount = await widget.scope.syncQueueRepository.countPending(
      empresaId: empresaId,
      usuarioId: session.usuarioId,
    );

    if (pendingCount == 0) {
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
    final remainingCount = await widget.scope.syncQueueRepository.countPending(
      empresaId: empresaId,
      usuarioId: session.usuarioId,
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
    _selectedArea = _initialArea(widget.session);
    _ratListViewModel = _createRatListViewModel(widget.session);
  }

  @override
  void didUpdateWidget(covariant CompanyShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _ratListViewModel?.dispose();
      _ratListViewModel = _createRatListViewModel(widget.session);
      _selectedArea = _initialArea(widget.session);
    }
  }

  @override
  void dispose() {
    _ratListViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final areas = _areasFor(widget.session);
    if (!areas.contains(_selectedArea)) {
      _selectedArea = areas.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_companyAreaLabel(_selectedArea)),
        actions: [
          if (_selectedArea == CompanyArea.rats && _ratListViewModel != null)
            IconButton(
              onPressed: _isSyncing ? null : _syncNow,
              icon: _isSyncing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Sincronizar',
            ),
          if (widget.session.hasCompanyContext)
            IconButton(
              onPressed: _isSyncing ? null : _openSyncCenter,
              icon: const Icon(Icons.sync_alt_outlined),
              tooltip: 'Central de sincronização',
            ),
          IconButton(
            onPressed: _isSyncing ? null : _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _buildArea(_selectedArea),
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
      CompanyArea.profile,
      if (session.hasCompanyContext && session.isAdminEmpresa)
        CompanyArea.adminEmpresa,
      if (session.isAppAdmin) CompanyArea.appAdmin,
    ];
  }

  Widget _buildArea(CompanyArea area) {
    switch (area) {
      case CompanyArea.rats:
        return _buildRatsArea();
      case CompanyArea.profile:
        return CompanyHomeScreen(
          session: widget.session,
          changePassword: widget.scope.changeCompanyPassword,
          onPasswordChanged: widget.onSignOut,
        );
      case CompanyArea.adminEmpresa:
        return AdminEmpresaArea(
          viewModel: AdminEmpresaViewModel(
            empresaId: widget.session.empresaId!,
            currentTecnicoId: widget.session.tecnicoId,
            listTecnicos: widget.scope.listAdminTecnicos,
            listConvites: widget.scope.listAdminConvites,
            createTecnicoConvite: widget.scope.createTecnicoConvite,
            cancelTecnicoConvite: widget.scope.cancelTecnicoConvite,
            updateTecnicoEquipe: widget.scope.updateTecnicoEquipe,
          ),
        );
      case CompanyArea.appAdmin:
        return AppAdminArea(
          viewModel: AppAdminViewModel(
            listEmpresas: widget.scope.listAdminEmpresas,
            createEmpresa: widget.scope.createAdminEmpresa,
            createEmpresaConvite: widget.scope.createEmpresaConvite,
            updateEmpresa: widget.scope.updateAdminEmpresa,
          ),
        );
    }
  }

  Widget _buildRatsArea() {
    final viewModel = _ratListViewModel;
    if (viewModel == null) {
      return const Center(child: Text('Sessão sem empresa vinculada.'));
    }

    return RatListScreen(
      viewModel: viewModel,
      assinaturaRepository: widget.scope.assinaturaRepository,
      localSignatureAssetStore: widget.scope.localSignatureAssetStore,
      ratPdfShareService: widget.scope.ratPdfShareService,
      ratRepository: widget.scope.ratRepository,
      shareRatLocally: widget.scope.shareRatLocally,
      remoteSession: widget.session,
      enqueueRatSync: widget.scope.enqueueRatSync,
      processSyncQueue: widget.scope.processSyncQueue,
      downloadRemoteRats: widget.scope.downloadRemoteRats,
      embedded: true,
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
    final empresaId = widget.session.empresaId;
    if (empresaId == null || !widget.session.hasCompanyContext) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    final papel =
        widget.session.papelEmpresa?.name ??
        widget.session.papelGlobal?.name ??
        'unknown';

    try {
      await widget.scope.processSyncQueue.call(
        empresaId: empresaId,
        usuarioId: widget.session.usuarioId,
        retryFailed: true,
      );
      await widget.scope.downloadRemoteRats.call(
        empresaId: empresaId,
        usuarioId: widget.session.usuarioId,
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
    final empresaId = widget.session.empresaId;
    if (empresaId == null) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SyncCenterScreen(
          viewModel: SyncCenterViewModel(
            queueRepository: widget.scope.syncQueueRepository,
            processSyncQueue: widget.scope.processSyncQueue,
            empresaId: empresaId,
            usuarioId: widget.session.usuarioId,
          ),
        ),
      ),
    );
  }
}
