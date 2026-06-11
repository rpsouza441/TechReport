import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/shared/presentation/widgets/metric_slate_text_field.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';

class RatReopenReasonScreen extends StatefulWidget {
  const RatReopenReasonScreen({super.key});

  @override
  State<RatReopenReasonScreen> createState() => _RatReopenReasonScreenState();
}

class _RatReopenReasonScreenState extends State<RatReopenReasonScreen> {
  final _reasonController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final motivo = _reasonController.text.trim();
    if (motivo.length < 5) {
      setState(() {
        _errorMessage = 'Informe pelo menos 5 caracteres.';
      });
      return;
    }

    Navigator.of(context).pop(motivo);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Reabrir RAT')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            MetricSlateSpacing.lg,
            MetricSlateSpacing.lg,
            MetricSlateSpacing.lg,
            MetricSlateSpacing.lg + bottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TechReportFormHeader(
                icon: Icons.lock_open_outlined,
                title: 'Reabrir para correção',
                subtitle:
                    'A assinatura atual deixará de valer e será necessário coletar uma nova.',
              ),
              const SizedBox(height: MetricSlateSpacing.lg),
              MetricSlateTextField(
                controller: _reasonController,
                label: 'Motivo da reabertura *',
                maxLines: 4,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: MetricSlateSpacing.xs),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: MetricSlateSpacing.xl),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_outlined),
                label: const Text('Confirmar reabertura'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
