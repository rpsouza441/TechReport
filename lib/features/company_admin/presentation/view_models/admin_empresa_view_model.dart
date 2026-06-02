import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/usecases/cancel_tecnico_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/create_tecnico_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_admin_convites.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_admin_tecnicos.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_tecnico_equipe.dart';

class AdminEmpresaViewModel extends ChangeNotifier {
  AdminEmpresaViewModel({
    required this.empresaId,
    required this.currentTecnicoId,
    required this.currentPapel,
    required ListAdminTecnicos listTecnicos,
    required ListAdminConvites listConvites,
    required CreateTecnicoConvite createTecnicoConvite,
    required CancelTecnicoConvite cancelTecnicoConvite,
    required UpdateTecnicoEquipe updateTecnicoEquipe,
  }) : _listTecnicos = listTecnicos,
       _listConvites = listConvites,
       _createTecnicoConvite = createTecnicoConvite,
       _cancelTecnicoConvite = cancelTecnicoConvite,
       _updateTecnicoEquipe = updateTecnicoEquipe;

  final String empresaId;
  final String? currentTecnicoId;
  final AdminTecnicoPapel currentPapel;
  final ListAdminTecnicos _listTecnicos;
  final ListAdminConvites _listConvites;
  final CreateTecnicoConvite _createTecnicoConvite;
  final CancelTecnicoConvite _cancelTecnicoConvite;
  final UpdateTecnicoEquipe _updateTecnicoEquipe;

  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  List<AdminTecnicoResumo> tecnicos = [];
  List<AdminConviteResumo> convites = [];

  bool get canInviteMembers =>
      currentPapel == AdminTecnicoPapel.adminEmpresa ||
      currentPapel == AdminTecnicoPapel.gerente;

  List<AdminTecnicoPapel> get allowedInvitePapeis {
    if (currentPapel == AdminTecnicoPapel.adminEmpresa) {
      return const [
        AdminTecnicoPapel.adminEmpresa,
        AdminTecnicoPapel.gerente,
        AdminTecnicoPapel.tecnico,
      ];
    }

    if (currentPapel == AdminTecnicoPapel.gerente) {
      return const [AdminTecnicoPapel.tecnico];
    }

    return const [];
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _listTecnicos(empresaId: empresaId),
        _listConvites(empresaId: empresaId),
      ]);
      tecnicos = results[0] as List<AdminTecnicoResumo>;
      convites = results[1] as List<AdminConviteResumo>;
    } catch (error) {
      errorMessage = _friendlyError(error);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<CreateTecnicoConviteResult> createConvite({
    required String email,
    required String nome,
    required AdminTecnicoPapel papel,
  }) async {
    if (!allowedInvitePapeis.contains(papel)) {
      throw StateError('Sem permissao para convidar este papel.');
    }

    return _createTecnicoConvite(email: email, nome: nome, papel: papel);
  }

  Future<CreateTecnicoConviteResult?> inviteMember({
    required String email,
    required String nome,
    required AdminTecnicoPapel papel,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await createConvite(
        email: email,
        nome: nome,
        papel: papel,
      );
      await load();
      isSubmitting = false;
      notifyListeners();
      return result;
    } catch (error) {
      errorMessage = _friendlyError(error);
      isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelInvite(String conviteId) async {
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

  Future<bool> setTecnicoAtivo({
    required AdminTecnicoResumo tecnico,
    required bool ativo,
  }) async {
    if (!canManageTecnico(tecnico)) {
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _updateTecnicoEquipe(tecnicoId: tecnico.id, ativo: ativo);
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

  Future<bool> setMustChangePassword({
    required AdminTecnicoResumo tecnico,
    required bool mustChangePassword,
  }) async {
    if (!canManageTecnico(tecnico)) {
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _updateTecnicoEquipe(
        tecnicoId: tecnico.id,
        mustChangePassword: mustChangePassword,
      );
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

  bool canManageTecnico(AdminTecnicoResumo tecnico) {
    if (tecnico.id == currentTecnicoId) {
      return false;
    }

    if (currentPapel == AdminTecnicoPapel.adminEmpresa) {
      return tecnico.papel != AdminTecnicoPapel.adminEmpresa;
    }

    if (currentPapel == AdminTecnicoPapel.gerente) {
      return tecnico.papel == AdminTecnicoPapel.tecnico;
    }

    return false;
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
