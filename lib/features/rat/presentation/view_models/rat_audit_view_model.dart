import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:techreport/features/rat/domain/entities/rat_audit_event.dart';
import 'package:techreport/features/rat/domain/repositories/rat_audit_repository.dart';

enum RatAuditViewStatus {
  initial,
  loading,
  content,
  empty,
  offline,
  accessDenied,
  error,
}

enum RatAuditFailure { offline, accessDenied, load }

class RatAuditViewModel extends ChangeNotifier {
  RatAuditViewModel({
    required RatAuditRepository repository,
    required this.ratId,
    this.pageSize = 20,
  }) : _repository = repository;

  final RatAuditRepository _repository;
  final String ratId;
  final int pageSize;

  final List<RatAuditEvent> _events = [];
  RatAuditCursor? _cursor;
  RatAuditFailure? _failure;
  bool _hasLoaded = false;
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;

  UnmodifiableListView<RatAuditEvent> get events =>
      UnmodifiableListView(_events);
  RatAuditCursor? get cursor => _cursor;
  RatAuditFailure? get failure => _failure;
  bool get hasMore => _cursor != null;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;

  RatAuditViewStatus get status {
    if (!_hasLoaded && !_isLoadingInitial) return RatAuditViewStatus.initial;
    if (_isLoadingInitial) return RatAuditViewStatus.loading;
    if (_events.isNotEmpty) return RatAuditViewStatus.content;
    return switch (_failure) {
      RatAuditFailure.offline => RatAuditViewStatus.offline,
      RatAuditFailure.accessDenied => RatAuditViewStatus.accessDenied,
      RatAuditFailure.load => RatAuditViewStatus.error,
      null => RatAuditViewStatus.empty,
    };
  }

  Future<void> load() => _loadInitial(preserveOnGenericFailure: false);

  Future<void> refresh() => _loadInitial(preserveOnGenericFailure: true);

  Future<void> _loadInitial({required bool preserveOnGenericFailure}) async {
    if (_isLoadingInitial || _isLoadingMore) return;
    _isLoadingInitial = true;
    _failure = null;
    notifyListeners();

    try {
      final page = await _repository.listForRat(ratId: ratId, limit: pageSize);
      _events
        ..clear()
        ..addAll(page.events);
      _cursor = page.nextCursor;
    } on RatAuditOfflineException {
      _events.clear();
      _cursor = null;
      _failure = RatAuditFailure.offline;
    } on RatAuditAccessDeniedException {
      _events.clear();
      _cursor = null;
      _failure = RatAuditFailure.accessDenied;
    } on RatAuditException {
      if (!preserveOnGenericFailure) {
        _events.clear();
        _cursor = null;
      }
      _failure = RatAuditFailure.load;
    } catch (_) {
      if (!preserveOnGenericFailure) {
        _events.clear();
        _cursor = null;
      }
      _failure = RatAuditFailure.load;
    } finally {
      _hasLoaded = true;
      _isLoadingInitial = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final next = _cursor;
    if (next == null || _isLoadingInitial || _isLoadingMore) return;
    _isLoadingMore = true;
    _failure = null;
    notifyListeners();

    try {
      final page = await _repository.listForRat(
        ratId: ratId,
        cursor: next,
        limit: pageSize,
      );
      final knownIds = _events.map((event) => event.id).toSet();
      _events.addAll(page.events.where((event) => knownIds.add(event.id)));
      _cursor = page.nextCursor;
    } on RatAuditOfflineException {
      _failure = RatAuditFailure.offline;
    } on RatAuditAccessDeniedException {
      _events.clear();
      _cursor = null;
      _failure = RatAuditFailure.accessDenied;
    } catch (_) {
      _failure = RatAuditFailure.load;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
