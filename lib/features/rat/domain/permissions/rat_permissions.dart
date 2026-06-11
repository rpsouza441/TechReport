import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';

/// Regras centralizadas de acesso a RATs.
///
/// Toda verificação de permissão passa por aqui — a UI, o ViewModel e
/// eventual lógica de domain/repository consultam esta classe.
class RatPermissions {
  const RatPermissions();

  /// Retorna true se a sessão atual pode visualizar a RAT.
  ///
  /// Modo local: sempre true (sem contexto de empresa).
  /// Técnico empresa: só propria RAT.
  /// Gerente/admin empresa: qualquer RAT da empresa.
  bool canView(Rat rat, SessaoRemota? session) {
    if (session == null || !session.hasCompanyContext) {
      return true;
    }

    if (rat.empresaId != session.empresaId) {
      return false;
    }

    if (session.isAdminEmpresa || session.isGerente) {
      return true;
    }

    return rat.tecnicoId == session.tecnicoId;
  }

  /// Retorna true se a sessão atual pode editar a RAT.
  ///
  /// Técnico empresa: só propria RAT.
  /// Gerente/admin empresa: qualquer RAT da empresa (campos operacionais).
  bool canEdit(Rat rat, SessaoRemota? session) {
    if (session == null || !session.hasCompanyContext) {
      return true;
    }

    if (rat.empresaId != session.empresaId) {
      return false;
    }

    if (session.isAdminEmpresa || session.isGerente) {
      return true;
    }

    return rat.tecnicoId == session.tecnicoId;
  }

  /// Retorna true se a sessão atual pode excluir a RAT.
  ///
  /// Técnico empresa: só propria RAT.
  /// Admin empresa: qualquer RAT da empresa.
  /// Gerente: NÃO pode excluir.
  bool canDelete(Rat rat, SessaoRemota? session) {
    if (session == null || !session.hasCompanyContext) {
      return true;
    }

    if (rat.empresaId != session.empresaId) {
      return false;
    }

    if (session.isAdminEmpresa) {
      return true;
    }

    return rat.tecnicoId == session.tecnicoId;
  }

  /// Retorna true se a sessão atual é dona da RAT
  /// (tecnicoId da RAT == tecnicoId da sessão).
  bool isOwner(Rat rat, SessaoRemota? session) {
    if (session == null || !session.hasCompanyContext) {
      return false;
    }
    return rat.tecnicoId == session.tecnicoId;
  }

  /// Retorna true se a sessão atual é gerente ou admin empresa
  /// com acesso à RAT (mesma empresa).
  bool isManagerOrAdmin(Rat rat, SessaoRemota? session) {
    if (session == null || !session.hasCompanyContext) {
      return false;
    }
    if (rat.empresaId != session.empresaId) {
      return false;
    }
    return session.isAdminEmpresa || session.isGerente;
  }

  /// Retorna true se a sessão atual pode arquivar a RAT.
  /// Apenas admin empresa pode arquivar.
  bool canArchive(Rat rat, SessaoRemota? session) {
    if (session == null || !session.hasCompanyContext) {
      return false;
    }
    if (rat.empresaId != session.empresaId) {
      return false;
    }
    return session.isAdminEmpresa;
  }
}