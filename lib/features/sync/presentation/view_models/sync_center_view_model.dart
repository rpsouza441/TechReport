import 'package:flutter/foundation.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';

class SyncCenterViewModel extends ChangeNotifier {
  SyncCenterViewModel({
    required SyncQueueRepository queueRepository,
    required ProcessSyncQueue processSyncQueue,
    required String empresaId,
    required String usuarioId,
  }) : _queueRepository = queueRepository,
       _processSyncQueue = processSyncQueue,
       _empresaId = empresaId,
       _usuarioId = usuarioId;

  final SyncQueueRepository _queueRepository;
  final ProcessSyncQueue _processSyncQueue;
  final String _empresaId;
  final String _usuarioId;

  List<SyncItem> _items = [];
  bool _isLoading = false;
  bool _isRetrying = false;
  String? _retryError;

  List<SyncItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isRetrying => _isRetrying;
  String? get retryError => _retryError;

  List<SyncItem> get pending => _items
      .where(
        (i) =>
            i.status == SyncItemStatus.pending ||
            i.status == SyncItemStatus.processing,
      )
      .toList();

  List<SyncItem> get failed =>
      _items.where((i) => i.status == SyncItemStatus.failed).toList();

  List<SyncItem> get synced {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final syncedItems = _items
        .where(
          (i) =>
              i.status == SyncItemStatus.synced &&
              i.updatedAt.isAfter(sevenDaysAgo),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return syncedItems.take(50).toList();
  }

  bool get hasActionable => pending.isNotEmpty || failed.isNotEmpty;

  Future<void> load() async {
    _isLoading = true;
    _retryError = null;
    notifyListeners();

    _items = await _queueRepository.listForSession(
      empresaId: _empresaId,
      usuarioId: _usuarioId,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> retryFailed() async {
    _isRetrying = true;
    _retryError = null;
    notifyListeners();

    try {
      await _processSyncQueue(
        empresaId: _empresaId,
        usuarioId: _usuarioId,
        retryFailed: true,
      );
    } catch (_) {
      _retryError = 'Falha ao tentar novamente. Verifique a conexão.';
    }

    await load();
    _isRetrying = false;
    notifyListeners();
  }
}
