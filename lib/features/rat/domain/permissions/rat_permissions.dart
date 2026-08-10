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
    return _canAccess(rat, session);
  }

  /// Retorna true se a sessão atual pode editar a RAT.
  ///
  /// Técnico empresa: só propria RAT.
  /// Gerente/admin empresa: qualquer RAT da empresa (campos operacionais).
  bool canEdit(Rat rat, SessaoRemota? session) {
    return _canAccess(rat, session);
  }

  /// Retorna true se a sessão atual pode excluir a RAT.
  ///
  /// Técnico empresa: só propria RAT.
  /// Gerente/admin empresa: qualquer RAT da empresa.
  bool canDelete(Rat rat, SessaoRemota? session) {
    return _canAccess(rat, session);
  }

  /// Retorna true se a sessao atual pode restaurar a RAT da lixeira.
  bool canRestore(Rat rat, SessaoRemota? session) {
    return _canAccess(rat, session);
  }

  /// Retorna true se a sessao atual pode consultar a auditoria da RAT.
  bool canViewAudit(Rat rat, SessaoRemota? session) {
    return _canAccess(rat, session);
  }

  /// Retorna true se a sessão atual é dona da RAT
  /// (tecnicoId da RAT == tecnicoId da sessão).
  bool isOwner(Rat rat, SessaoRemota? session) {
    if (!_isValidCompanySession(session) ||
        rat.empresaId != session!.empresaId) {
      return false;
    }
    return rat.tecnicoId == session.tecnicoId;
  }

  /// Retorna true se a sessão atual é gerente ou admin empresa
  /// com acesso à RAT (mesma empresa).
  bool isManagerOrAdmin(Rat rat, SessaoRemota? session) {
    if (!_isValidCompanySession(session) ||
        rat.empresaId != session!.empresaId) {
      return false;
    }
    return session.isAdminEmpresa || session.isGerente;
  }

  /// Retorna true se a sessão atual pode arquivar a RAT.
  /// Apenas admin empresa pode arquivar.
  bool canArchive(Rat rat, SessaoRemota? session) {
    if (!_isValidCompanySession(session) ||
        rat.empresaId != session!.empresaId) {
      return false;
    }
    return session.isAdminEmpresa;
  }

  /// Retorna true se a sessao atual pode reabrir uma RAT para correcao.
  ///
  /// Gerente/admin empresa ou o tecnico proprietario, sempre na mesma empresa,
  /// podem reabrir RATs finalizadas ou enviadas. RAT arquivada e RAT ja
  /// reaberta nao reabrem.
  bool canReopenForCorrection(Rat rat, SessaoRemota? session) {
    final isOwnerTechnician =
        session != null &&
        session.hasCompanyContext &&
        session.isTecnico &&
        rat.empresaId == session.empresaId &&
        rat.tecnicoId == session.tecnicoId;

    if (!isManagerOrAdmin(rat, session) && !isOwnerTechnician) {
      return false;
    }
    if (rat.isArquivado || rat.isDraft || rat.isReabertaParaCorrecao) {
      return false;
    }

    return rat.isFinalizado || rat.isEnviado;
  }

  bool _canAccess(Rat rat, SessaoRemota? session) {
    if (session == null) {
      return true;
    }

    if (!_isValidCompanySession(session) ||
        rat.empresaId != session.empresaId) {
      return false;
    }

    if (session.isAdminEmpresa || session.isGerente) {
      return true;
    }

    return session.isTecnico && rat.tecnicoId == session.tecnicoId;
  }

  bool _isValidCompanySession(SessaoRemota? session) {
    return session != null &&
        session.hasCompanyContext &&
        !session.isAppAdmin &&
        (session.isTecnico || session.isGerente || session.isAdminEmpresa);
  }
}
