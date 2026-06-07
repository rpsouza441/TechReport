import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/usecases/create_admin_empresa.dart';
import 'package:techreport/features/company_admin/domain/usecases/create_empresa_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_admin_empresas.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_admin_empresa.dart';

class AppAdminViewModel extends ChangeNotifier {
  AppAdminViewModel({
    required ListAdminEmpresas listEmpresas,
    required CreateAdminEmpresa createEmpresa,
    required CreateEmpresaConvite createEmpresaConvite,
    required UpdateAdminEmpresa updateEmpresa,
  }) : _listEmpresas = listEmpresas,
       _createEmpresa = createEmpresa,
       _createEmpresaConvite = createEmpresaConvite,
       _updateEmpresa = updateEmpresa;

  final ListAdminEmpresas _listEmpresas;
  final CreateAdminEmpresa _createEmpresa;
  final CreateEmpresaConvite _createEmpresaConvite;
  final UpdateAdminEmpresa _updateEmpresa;

  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  List<AdminEmpresaResumo> empresas = [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      empresas = await _listEmpresas();
    } catch (_) {
      errorMessage = 'Não foi possível carregar empresas.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> createEmpresa({required String nome}) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _createEmpresa(nome: nome);
      await load();
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Nao foi possivel criar a empresa.';
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void syncEmpresa(AdminEmpresaResumo empresa) {
    empresas = [
      for (final item in empresas)
        item.id == empresa.id ? empresa : item,
    ];
    notifyListeners();
  }

  Future<bool> setEmpresaAtiva({
    required AdminEmpresaResumo empresa,
    required bool ativo,
  }) async {
    final previous = empresas;
    empresas = [
      for (final item in empresas)
        item.id == empresa.id
            ? AdminEmpresaResumo(id: item.id, nome: item.nome, ativo: ativo)
            : item,
    ];
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _updateEmpresa(empresaId: empresa.id, ativo: ativo);
      isSubmitting = false;
      notifyListeners();
      unawaited(load());
      return true;
    } catch (_) {
      empresas = previous;
      errorMessage = 'Nao foi possivel atualizar a empresa.';
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<CreateTecnicoConviteResult?> inviteAdminEmpresa({
    required AdminEmpresaResumo empresa,
    required String nome,
    required String email,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _createEmpresaConvite(
        empresaId: empresa.id,
        email: email,
        nome: nome,
        papel: AdminTecnicoPapel.adminEmpresa,
      );
      isSubmitting = false;
      notifyListeners();
      return result;
    } catch (_) {
      errorMessage = 'Nao foi possivel criar o convite.';
      isSubmitting = false;
      notifyListeners();
      return null;
    }
  }
}
