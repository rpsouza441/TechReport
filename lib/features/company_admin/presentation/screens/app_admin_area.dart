import 'package:flutter/material.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/presentation/view_models/app_admin_view_model.dart';

class AppAdminArea extends StatefulWidget {
  const AppAdminArea({super.key, required this.viewModel});

  final AppAdminViewModel viewModel;

  @override
  State<AppAdminArea> createState() => _AppAdminAreaState();
}

class _AppAdminAreaState extends State<AppAdminArea> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: widget.viewModel.load,
          child: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.viewModel.isLoading && widget.viewModel.empresas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = widget.viewModel.errorMessage;
    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            errorMessage,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      );
    }

    if (widget.viewModel.empresas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [Text('Nenhuma empresa encontrada.')],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.viewModel.empresas.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final empresa = widget.viewModel.empresas[index];
        return _EmpresaTile(empresa: empresa);
      },
    );
  }
}

class _EmpresaTile extends StatelessWidget {
  const _EmpresaTile({required this.empresa});

  final AdminEmpresaResumo empresa;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        empresa.ativo
            ? Icons.business_outlined
            : Icons.business_center_outlined,
      ),
      title: Text(empresa.nome),
      subtitle: Text(empresa.ativo ? 'Ativa' : 'Inativa'),
    );
  }
}
