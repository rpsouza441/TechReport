import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/navigation/company_sync_runner.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';

void main() {
  group('companySyncErrorMessage()', () {
    test('classifica erros de rede', () {
      expect(
        companySyncErrorMessage(Exception('SocketException: network timeout')),
        'Verifique sua conexão com a internet.',
      );
    });

    test('classifica sessao expirada', () {
      expect(
        companySyncErrorMessage(Exception('401 unauthorized auth failed')),
        'Sessão expirada. Entre novamente.',
      );
    });

    test('classifica erro de servidor', () {
      expect(
        companySyncErrorMessage(Exception('500 internal server error')),
        'Servidor indisponível. Tente mais tarde.',
      );
    });

    test('classifica erro desconhecido como fallback', () {
      expect(
        companySyncErrorMessage(Exception('unexpected failure')),
        'Não foi possível sincronizar. Tente novamente.',
      );
    });
  });

  group('CompanySyncRunner', () {
    test('processa fila, baixa remotos e recarrega lista em ordem', () async {
      final calls = <String>[];

      final runner = CompanySyncRunner(
        processQueue:
            ({
              required empresaId,
              required usuarioId,
              required retryFailed,
            }) async {
              calls.add('process:$empresaId:$usuarioId:$retryFailed');
            },
        downloadRemoteRats:
            ({required empresaId, required usuarioId, required papel}) async {
              calls.add('download:$empresaId:$usuarioId:$papel');
            },
        reloadRatList: () async {
          calls.add('reload');
        },
      );

      final result = await runner.sync(_session());

      expect(result.status, CompanySyncStatus.success);
      expect(calls, [
        'process:emp-1:user-1:true',
        'download:emp-1:user-1:tecnico',
        'reload',
      ]);
      expect(runner.isRunning, isFalse);
    });

    test('retorna falha amigavel quando processamento da fila falha', () async {
      var downloaded = false;
      var reloaded = false;

      final runner = CompanySyncRunner(
        processQueue:
            ({
              required empresaId,
              required usuarioId,
              required retryFailed,
            }) async {
              throw Exception('SocketException: Network is unreachable');
            },
        downloadRemoteRats:
            ({required empresaId, required usuarioId, required papel}) async {
              downloaded = true;
            },
        reloadRatList: () async {
          reloaded = true;
        },
      );

      final result = await runner.sync(_session());

      expect(result.status, CompanySyncStatus.failure);
      expect(result.message, 'Verifique sua conexão com a internet.');
      expect(downloaded, isFalse);
      expect(reloaded, isFalse);
      expect(runner.isRunning, isFalse);
    });

    test('retorna falha amigavel quando download remoto falha', () async {
      var processed = false;
      var reloaded = false;

      final runner = CompanySyncRunner(
        processQueue:
            ({
              required empresaId,
              required usuarioId,
              required retryFailed,
            }) async {
              processed = true;
            },
        downloadRemoteRats:
            ({required empresaId, required usuarioId, required papel}) async {
              throw Exception('401 unauthorized');
            },
        reloadRatList: () async {
          reloaded = true;
        },
      );

      final result = await runner.sync(_session());

      expect(processed, isTrue);
      expect(result.status, CompanySyncStatus.failure);
      expect(result.message, 'Sessão expirada. Entre novamente.');
      expect(reloaded, isFalse);
      expect(runner.isRunning, isFalse);
    });

    test('ignora sessao sem contexto de empresa', () async {
      var called = false;

      final runner = CompanySyncRunner(
        processQueue:
            ({
              required empresaId,
              required usuarioId,
              required retryFailed,
            }) async {
              called = true;
            },
        downloadRemoteRats:
            ({required empresaId, required usuarioId, required papel}) async {},
        reloadRatList: () async {},
      );

      final result = await runner.sync(_session(empresaId: null));

      expect(result.status, CompanySyncStatus.skipped);
      expect(called, isFalse);
      expect(runner.isRunning, isFalse);
    });

    test('nao inicia segunda sincronizacao concorrente', () async {
      final completer = Completer<void>();
      var processCalls = 0;

      final runner = CompanySyncRunner(
        processQueue:
            ({
              required empresaId,
              required usuarioId,
              required retryFailed,
            }) async {
              processCalls++;
              await completer.future;
            },
        downloadRemoteRats:
            ({required empresaId, required usuarioId, required papel}) async {},
        reloadRatList: () async {},
      );

      final first = runner.sync(_session());
      await Future<void>.delayed(Duration.zero);

      final second = await runner.sync(_session());
      expect(second.status, CompanySyncStatus.skipped);
      expect(processCalls, 1);
      expect(runner.isRunning, isTrue);

      completer.complete();
      final firstResult = await first;

      expect(firstResult.status, CompanySyncStatus.success);
      expect(runner.isRunning, isFalse);
    });
  });
}

SessaoRemota _session({String? empresaId = 'emp-1'}) {
  final now = DateTime(2026, 6, 25, 12);
  return SessaoRemota(
    id: 'session-1',
    empresaId: empresaId,
    usuarioId: 'user-1',
    tecnicoId: empresaId == null ? null : 'tec-1',
    email: 'user@example.com',
    nome: 'Tecnico',
    mustChangePassword: false,
    papelGlobal: null,
    papelEmpresa: empresaId == null ? null : SessaoRemotaPapelEmpresa.tecnico,
    accessTokenRef: 'access',
    refreshTokenRef: 'refresh',
    endpointRef: 'endpoint',
    expiresAt: now.add(const Duration(days: 1)),
    lastValidatedAt: now,
    offlineAccessUntil: now.add(const Duration(days: 7)),
    createdAt: now,
    updatedAt: now,
  );
}
