import 'package:flutter/foundation.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';

/// Holds all form field values and provides validation.
///
/// Single responsibility: form state management.
/// Extracted from RatFormViewModel to reduce coupling and improve testability.
class RatFormState extends ChangeNotifier {
  RatFormState({
    Rat? initialRat,
  })  : clienteNome = initialRat?.clienteNome ?? '',
        responsavelRecebimento = initialRat?.responsavelRecebimento ?? '',
        responsavelDocumento = initialRat?.responsavelDocumento ?? '',
        dataVisita = initialRat?.dataVisita,
        horarioInicioAtendimento =
            initialRat?.horarioInicioAtendimento ?? '',
        horarioTerminoAtendimento =
            initialRat?.horarioTerminoAtendimento ?? '',
        descricao = initialRat?.descricao ?? '',
        equipamentoMovimentoTipo =
            initialRat?.equipamentoMovimentoTipo ??
            EquipamentoMovimentoTipo.nenhum,
        equipamentoDescricao = initialRat?.equipamentoDescricao ?? '',
        equipamentoObservacao = initialRat?.equipamentoObservacao ?? '',
        status = initialRat?.status ?? RatStatus.draft,
        _isDirty = false;

  // Form field declarations
  String clienteNome;
  String responsavelRecebimento;
  String responsavelDocumento;
  DateTime? dataVisita;
  String horarioInicioAtendimento;
  String horarioTerminoAtendimento;
  String descricao;
  EquipamentoMovimentoTipo equipamentoMovimentoTipo;
  String equipamentoDescricao;
  String equipamentoObservacao;
  RatStatus status;

  bool _isDirty;

  bool get isDirty => _isDirty;

  // Setters that track dirty state and notify listeners
  void setClienteNome(String value) {
    if (clienteNome != value) {
      clienteNome = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  void setResponsavelRecebimento(String value) {
    if (responsavelRecebimento != value) {
      responsavelRecebimento = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  void setResponsavelDocumento(String value) {
    if (responsavelDocumento != value) {
      responsavelDocumento = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  void setDataVisita(DateTime? value) {
    if (dataVisita != value) {
      dataVisita = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  void setHorarioInicioAtendimento(String value) {
    if (horarioInicioAtendimento != value) {
      horarioInicioAtendimento = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  void setHorarioTerminoAtendimento(String value) {
    if (horarioTerminoAtendimento != value) {
      horarioTerminoAtendimento = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  void setDescricao(String value) {
    if (descricao != value) {
      descricao = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  void setEquipamentoMovimentoTipo(EquipamentoMovimentoTipo value) {
    if (equipamentoMovimentoTipo != value) {
      equipamentoMovimentoTipo = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  void setEquipamentoDescricao(String value) {
    if (equipamentoDescricao != value) {
      equipamentoDescricao = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  void setEquipamentoObservacao(String value) {
    if (equipamentoObservacao != value) {
      equipamentoObservacao = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  void setStatus(RatStatus value) {
    if (status != value) {
      status = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  /// Validates all form fields.
  ///
  /// Returns null if valid, or an error message string if invalid.
  String? validate() {
    if (clienteNome.trim().isEmpty) {
      return 'Informe o cliente.';
    }

    if (responsavelRecebimento.trim().isEmpty) {
      return 'Informe o responsavel pelo recebimento.';
    }

    if (dataVisita == null) {
      return 'Informe a data da visita.';
    }

    final normalizedStart = _normalizeHour(horarioInicioAtendimento);
    if (normalizedStart == null) {
      return 'Informe o horario de inicio no formato HH:mm.';
    }

    if (!_isHourInRange(horarioInicioAtendimento)) {
      return 'Horario de inicio invalido. Use 00:00 ate 23:59.';
    }

    final normalizedEnd = _normalizeHour(horarioTerminoAtendimento);
    if (normalizedEnd == null) {
      return 'Informe o horario de termino no formato HH:mm.';
    }

    if (!_isHourInRange(horarioTerminoAtendimento)) {
      return 'Horario de termino invalido. Use 00:00 ate 23:59.';
    }

    if (!_isEndAfterStart(normalizedStart, normalizedEnd)) {
      return 'Horario de termino precisa ser depois do inicio.';
    }

    if (descricao.trim().isEmpty) {
      return 'Informe a descricao.';
    }

    return null;
  }

  /// Resets dirty flag after successful save.
  void markClean() {
    _isDirty = false;
    notifyListeners();
  }

  /// Applies values from another RatFormState (e.g., after loading from DB).
  void applyFrom(RatFormState other) {
    clienteNome = other.clienteNome;
    responsavelRecebimento = other.responsavelRecebimento;
    responsavelDocumento = other.responsavelDocumento;
    dataVisita = other.dataVisita;
    horarioInicioAtendimento = other.horarioInicioAtendimento;
    horarioTerminoAtendimento = other.horarioTerminoAtendimento;
    descricao = other.descricao;
    equipamentoMovimentoTipo = other.equipamentoMovimentoTipo;
    equipamentoDescricao = other.equipamentoDescricao;
    equipamentoObservacao = other.equipamentoObservacao;
    status = other.status;
    _isDirty = false;
    notifyListeners();
  }

  // Helper methods for hour validation
  static String? _normalizeHour(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 4) {
      return null;
    }

    final hour = int.tryParse(digits.substring(0, 2));
    final minute = int.tryParse(digits.substring(2, 4));

    if (hour == null || minute == null) {
      return null;
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  static bool _isHourInRange(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 4) {
      return false;
    }

    final hour = int.tryParse(digits.substring(0, 2));
    final minute = int.tryParse(digits.substring(2, 4));

    if (hour == null || minute == null) {
      return false;
    }

    return hour <= 23 && minute <= 59;
  }

  static bool _isEndAfterStart(String start, String end) {
    return _minutesSinceMidnight(end) > _minutesSinceMidnight(start);
  }

  static int _minutesSinceMidnight(String value) {
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return hour * 60 + minute;
  }
}
