import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';

const ratNotInformedLabel = 'Não informado';

String ratStatusLabel(RatStatus status) {
  return switch (status) {
    RatStatus.draft => 'Rascunho',
    RatStatus.finalizado => 'Finalizado',
    RatStatus.enviado => 'Enviado',
    RatStatus.arquivado => 'Arquivado',
  };
}

TechReportStatusTone ratStatusTone(RatStatus status) {
  return switch (status) {
    RatStatus.draft => TechReportStatusTone.neutral,
    RatStatus.finalizado => TechReportStatusTone.info,
    RatStatus.enviado => TechReportStatusTone.success,
    RatStatus.arquivado => TechReportStatusTone.neutral,
  };
}

String equipamentoMovimentoLabel(EquipamentoMovimentoTipo tipo) {
  return switch (tipo) {
    EquipamentoMovimentoTipo.nenhum => 'Nenhuma movimentação',
    EquipamentoMovimentoTipo.retiradaParaReparo => 'Retirada para reparo',
    EquipamentoMovimentoTipo.entregaPosReparo => 'Entrega pós-reparo',
    EquipamentoMovimentoTipo.entregaPosCompra => 'Entrega pós-compra',
  };
}
