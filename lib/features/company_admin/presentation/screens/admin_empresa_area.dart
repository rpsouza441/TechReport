import 'package:flutter/material.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/presentation/view_models/admin_empresa_view_model.dart';

class AdminEmpresaArea extends StatefulWidget {
  const AdminEmpresaArea({super.key, required this.viewModel});

  final AdminEmpresaViewModel viewModel;

  @override
  State<AdminEmpresaArea> createState() => _AdminEmpresaAreaState();
}

class _AdminEmpresaAreaState extends State<AdminEmpresaArea> {
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
    if (widget.viewModel.isLoading && widget.viewModel.tecnicos.isEmpty) {
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

    if (widget.viewModel.tecnicos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [Text('Nenhum tecnico encontrado.')],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.viewModel.tecnicos.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final tecnico = widget.viewModel.tecnicos[index];
        return _TecnicoTile(tecnico: tecnico);
      },
    );
  }
}

class _TecnicoTile extends StatelessWidget {
  const _TecnicoTile({required this.tecnico});

  final AdminTecnicoResumo tecnico;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        tecnico.ativo ? Icons.badge_outlined : Icons.person_off_outlined,
      ),
      title: Text(tecnico.nome),
      subtitle: Text('${tecnico.email} - ${_papelLabel(tecnico.papel)}'),
      trailing: Text(tecnico.ativo ? 'Ativo' : 'Inativo'),
    );
  }

  String _papelLabel(AdminTecnicoPapel papel) {
    switch (papel) {
      case AdminTecnicoPapel.adminEmpresa:
        return 'Admin empresa';
      case AdminTecnicoPapel.gerente:
        return 'Gerente';
      case AdminTecnicoPapel.tecnico:
        return 'Tecnico';
    }
  }
}
