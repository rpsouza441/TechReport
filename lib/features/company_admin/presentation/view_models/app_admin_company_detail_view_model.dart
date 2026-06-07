import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/usecases/cancel_tecnico_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/create_empresa_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_empresa_admin_convites.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_empresa_admins.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_admin_empresa.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_empresa_admin.dart';

class AppAdminCompanyDetailViewModel extends ChangeNotifier {
  AppAdminCompanyDetailViewModel({
    required AdminEmpresaResumo empresa,
    required ListEmpresaAdmins listEmpresaAdmins,
    required ListEmpresaAdminConvites listEmpresaAdminConvites,
    required CreateEmpresaConvite createEmpresaConvite,
    required CancelTecnicoConvite cancelTecnicoConvite,
    required UpdateEmpresaAdmin updateEmpresaAdmin,
    required UpdateAdminEmpresa updateAdminEmpresa,
  })  : _empresa = empresa,
        _listEmpresaAdmins = listEmpresaAdmins,
        _listEmpresaAdminConvites = listEmpresaAdminConvites,
        _createEmpresaConvite = createEmpresaConvite,
        _cancelTecnicoConvite = cancelTecnicoConvite,
        _updateEmpresaAdmin = updateEmpresaAdmin,
        _updateAdminEmpresa = updateAdminEmpresa;

  final ListEmpresaAdmins _listEmpresaAdmins;
  final ListEmpresaAdminConvites _listEmpresaAdminConvites;
  final CreateEmpresaConvite _createEmpresaConvite;
  final CancelTecnicoConvite _cancelTecnicoConvite;
  final UpdateEmpresaAdmin _updateEmpresaAdmin;
  final UpdateAdminEmpresa _updateAdminEmpresa;

  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  AdminEmpresaResumo _empresa;
  List<AdminTecnicoResumo> admins = [];
  List<AdminConviteResumo> convites = [];

  AdminEmpresaResumo get empresa => _empresa;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _listEmpresaAdmins(empresaId: _empresa.id),
        _listEmpresaAdminConvites(empresaId: _empresa.id),
      ]);
      admins = results[0] as List<AdminTecnicoResumo>;
      convites = results[1] as List<AdminConviteResumo>;
    } catch (error) {
      errorMessage = _friendlyError(error);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<CreateTecnicoConviteResult?> inviteAdmin({
    required String nome,
    required String email,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _createEmpresaConvite(
        empresaId: _empresa.id,
        email: email,
        nome: nome,
        papel: AdminTecnicoPapel.adminEmpresa,
      );
      isSubmitting = false;
      notifyListeners();
      await load();
      return result;
    } catch (error) {
      errorMessage = 'Nao foi possivel criar o convite.';
      isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelConvite(String conviteId) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _cancelTecnicoConvite(conviteId: conviteId);
      await load();
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = _friendlyError(error);
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setEmpresaAtiva({required bool ativo}) async {
    final previous = _empresa;
    _empresa = AdminEmpresaResumo(
      id: _empresa.id,
      nome: _empresa.nome,
      ativo: ativo,
    );
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _updateAdminEmpresa(empresaId: _empresa.id, ativo: ativo);
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (error) {
      _empresa = previous;
      errorMessage = _friendlyError(error);
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setAdminAtivo({
    required AdminTecnicoResumo admin,
    required bool ativo,
  }) async {
    final previous = List<AdminTecnicoResumo>.from(admins);
    admins = [
      for (final a in admins)
        a.id == admin.id
            ? AdminTecnicoResumo(
                id: a.id,
                empresaId: a.empresaId,
                nome: a.nome,
                email: a.email,
                papel: a.papel,
                ativo: ativo,
                mustChangePassword: a.mustChangePassword,
              )
            : a,
    ];
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _updateEmpresaAdmin(tecnicoId: admin.id, ativo: ativo);
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (error) {
      admins = previous;
      errorMessage = _friendlyError(error);
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setMustChangePassword({
    required AdminTecnicoResumo admin,
    required bool mustChangePassword,
  }) async {
    final previous = List<AdminTecnicoResumo>.from(admins);
    admins = [
      for (final a in admins)
        a.id == admin.id
            ? AdminTecnicoResumo(
                id: a.id,
                empresaId: a.empresaId,
                nome: a.nome,
                email: a.email,
                papel: a.papel,
                ativo: a.ativo,
                mustChangePassword: mustChangePassword,
              )
            : a,
    ];
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _updateEmpresaAdmin(
        tecnicoId: admin.id,
        mustChangePassword: mustChangePassword,
      );
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (error) {
      admins = previous;
      errorMessage = _friendlyError(error);
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    const prefix = 'PostgrestException(message: ';
    if (message.contains(prefix)) {
      final start = message.indexOf(prefix) + prefix.length;
      final end = message.indexOf(',', start);
      if (end > start) {
        return message.substring(start, end);
      }
    }
    if (message.contains('StateError')) {
      return message.replaceFirst('Bad state: ', '');
    }
    return message.replaceFirst('Exception: ', '');
  }
}