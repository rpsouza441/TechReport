import 'package:flutter/material.dart';

class RatDateRangeField extends StatelessWidget {
  const RatDateRangeField({
    required this.dateFrom,
    required this.dateTo,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final void Function({DateTime? from, DateTime? to}) onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasRange = dateFrom != null || dateTo != null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Período',
        isDense: true,
        suffixIcon: hasRange
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
                padding: EdgeInsets.zero,
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label:
                  'Data de inicio: ${dateFrom != null ? _fmt(dateFrom!) : 'nao definida'}',
              button: true,
              child: InkWell(
                onTap: () => _pickDate(context, isFrom: true),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    dateFrom != null ? _fmt(dateFrom!) : 'De',
                    style: TextStyle(
                      color: dateFrom != null
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text('—'),
          const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              label:
                  'Data de fim: ${dateTo != null ? _fmt(dateTo!) : 'nao definida'}',
              button: true,
              child: InkWell(
                onTap: () => _pickDate(context, isFrom: false),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    dateTo != null ? _fmt(dateTo!) : 'Ate',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: dateTo != null
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final initial =
        isFrom ? (dateFrom ?? DateTime.now()) : (dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;

    if (isFrom) {
      final effectiveTo = dateTo;
      if (effectiveTo != null && picked.isAfter(effectiveTo)) {
        onChanged(from: effectiveTo, to: picked);
      } else {
        onChanged(from: picked, to: effectiveTo);
      }
    } else {
      final effectiveFrom = dateFrom;
      if (effectiveFrom != null && picked.isBefore(effectiveFrom)) {
        onChanged(from: picked, to: effectiveFrom);
      } else {
        onChanged(from: effectiveFrom, to: picked);
      }
    }
  }
}
