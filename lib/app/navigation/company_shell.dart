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

enum CompanyArea { rats, profile, adminEmpresa, appAdmin }

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
          IconButton(
            onPressed: widget.onSignOut,
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
        return CompanyHomeScreen(session: widget.session);
      case CompanyArea.adminEmpresa:
        return AdminEmpresaArea(
          viewModel: AdminEmpresaViewModel(
            empresaId: widget.session.empresaId!,
            listTecnicos: widget.scope.listAdminTecnicos,
          ),
        );
      case CompanyArea.appAdmin:
        return AppAdminArea(
          viewModel: AppAdminViewModel(
            listEmpresas: widget.scope.listAdminEmpresas,
          ),
        );
    }
  }

  Widget _buildRatsArea() {
    final viewModel = _ratListViewModel;
    if (viewModel == null) {
      return const Center(child: Text('Sessao sem empresa vinculada.'));
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
      onSignOut: widget.onSignOut,
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
    final tecnicoId = session.tecnicoId!;

    if (session.isGerente || session.isAdminEmpresa) {
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

    try {
      await widget.scope.processSyncQueue.call(
        empresaId: empresaId,
        usuarioId: widget.session.usuarioId,
        retryFailed: true,
      );
      await widget.scope.downloadRemoteRats.call(empresaId: empresaId);
      await _ratListViewModel?.load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel sincronizar.')),
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
}
