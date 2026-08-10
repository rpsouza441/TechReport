import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/services/rat_sync_coordinator.dart';
import 'package:techreport/features/rat/presentation/view_models/trash_scope.dart';

enum TrashRestoreResult { localCompleted, remoteCompleted, queued, failure }

class TrashViewModel extends ChangeNotifier {
  TrashViewModel({
    required RatRepository ratRepository,
    required RatSyncCoordinator syncCoordinator,
    required this.scope,
    required this.session,
    this.pageSize = 20,
  }) : _ratRepository = ratRepository,
       _syncCoordinator = syncCoordinator;

  final RatRepository _ratRepository;
  final RatSyncCoordinator _syncCoordinator;
  final TrashScope scope;
  final SessaoRemota? session;
  final int pageSize;

  final List<Rat> _rats = [];
  final Set<String> _restoringRatIds = {};
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  bool _isAccessDenied = false;
  String? _errorMessage;
  String? _feedbackMessage;

  UnmodifiableListView<Rat> get rats => UnmodifiableListView(_rats);
  UnmodifiableSetView<String> get restoringRatIds =>
      UnmodifiableSetView(_restoringRatIds);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get isAccessDenied => _isAccessDenied;
  String? get errorMessage => _errorMessage;
  String? get feedbackMessage => _feedbackMessage;

  Future<void> load() => _loadPage(replace: true, refreshing: false);

  Future<void> refresh() => _loadPage(replace: true, refreshing: true);

  Future<void> loadMore() async {
    if (!_hasMore || _isLoading || _isRefreshing || _isLoadingMore) return;
    await _loadPage(replace: false, refreshing: false);
  }

  Future<void> _loadPage({
    required bool replace,
    required bool refreshing,
  }) async {
    if (_isLoading || _isRefreshing || _isLoadingMore) return;
    if (!_scopeAllowed()) {
      _denyAccess();
      return;
    }

    if (refreshing) {
      _isRefreshing = true;
    } else if (replace) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _errorMessage = null;
    _feedbackMessage = null;
    notifyListeners();

    final last = replace || _rats.isEmpty ? null : _rats.last;
    try {
      final page = await _query(
        lastDeletedAt: last?.deletedAt,
        lastId: last?.id,
      );
      if (replace) _rats.clear();
      final ids = _rats.map((rat) => rat.id).toSet();
      _rats.addAll(page.where((rat) => ids.add(rat.id)));
      _hasMore = page.length >= pageSize;
      _isAccessDenied = false;
    } catch (_) {
      _errorMessage = scope is LocalTrashScope
          ? 'Não foi possível carregar a lixeira local. Tente novamente.'
          : 'Não foi possível carregar a lixeira. Tente novamente.';
      if (!refreshing && replace) _rats.clear();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<List<Rat>> _query({DateTime? lastDeletedAt, String? lastId}) {
    return switch (scope) {
      LocalTrashScope() => _ratRepository.listDeletedLocalCursor(
        limit: pageSize,
        lastDeletedAt: lastDeletedAt,
        lastId: lastId,
      ),
      CompanyTechnicianTrashScope(:final empresaId, :final tecnicoId) =>
        _ratRepository.listDeletedCompanyForTechnicianCursor(
          empresaId: empresaId,
          tecnicoId: tecnicoId,
          limit: pageSize,
          lastDeletedAt: lastDeletedAt,
          lastId: lastId,
        ),
      CompanyManagerTrashScope(:final empresaId) =>
        _ratRepository.listDeletedCompanyForManagerCursor(
          empresaId: empresaId,
          limit: pageSize,
          lastDeletedAt: lastDeletedAt,
          lastId: lastId,
        ),
    };
  }

  Future<TrashRestoreResult> restore(String ratId) async {
    if (_restoringRatIds.contains(ratId)) return TrashRestoreResult.failure;
    if (!_scopeAllowed()) {
      _denyAccess();
      return TrashRestoreResult.failure;
    }
    Rat? rat;
    for (final candidate in _rats) {
      if (candidate.id == ratId) {
        rat = candidate;
        break;
      }
    }
    if (rat == null) return TrashRestoreResult.failure;

    _restoringRatIds.add(ratId);
    _errorMessage = null;
    _feedbackMessage = null;
    notifyListeners();
    try {
      final result = await _syncCoordinator.restore(rat: rat, session: session);
      _rats.removeWhere((candidate) => candidate.id == ratId);
      final mapped = switch (result) {
        RatRestoreSyncResult.localCompleted =>
          TrashRestoreResult.localCompleted,
        RatRestoreSyncResult.remoteCompleted =>
          TrashRestoreResult.remoteCompleted,
        RatRestoreSyncResult.queued => TrashRestoreResult.queued,
      };
      _feedbackMessage = mapped == TrashRestoreResult.queued
          ? 'RAT restaurada neste dispositivo. A sincronização será feita quando houver conexão.'
          : 'RAT restaurada com o status e a assinatura preservados.';
      return mapped;
    } catch (_) {
      _errorMessage = 'Não foi possível restaurar a RAT. Tente novamente.';
      return TrashRestoreResult.failure;
    } finally {
      _restoringRatIds.remove(ratId);
      notifyListeners();
    }
  }

  bool _scopeAllowed() {
    return switch (scope) {
      LocalTrashScope() => session == null,
      CompanyTechnicianTrashScope(:final empresaId, :final tecnicoId) =>
        session != null &&
            session!.hasCompanyContext &&
            !session!.isAppAdmin &&
            session!.isTecnico &&
            session!.empresaId == empresaId &&
            session!.tecnicoId == tecnicoId,
      CompanyManagerTrashScope(:final empresaId) =>
        session != null &&
            session!.hasCompanyContext &&
            !session!.isAppAdmin &&
            (session!.isGerente || session!.isAdminEmpresa) &&
            session!.empresaId == empresaId,
    };
  }

  void _denyAccess() {
    _rats.clear();
    _hasMore = false;
    _isAccessDenied = true;
    _errorMessage = 'Você não tem permissão para acessar este conteúdo.';
    notifyListeners();
  }
}
