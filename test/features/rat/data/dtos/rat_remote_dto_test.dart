import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/rat/data/dtos/rat_remote_dto.dart';

void main() {
  test('toJson nunca envia ator ou horário de auditoria', () {
    final dto = RatRemoteDto(
      id: 'rat-1',
      empresaId: 'empresa-1',
      tecnicoId: 'tecnico-1',
      criadoPorUserId: 'usuario-1',
      numero: 'RAT-001',
      clienteNome: 'Cliente',
      descricao: 'Descrição',
      status: 'draft',
      deletado: false,
      criadoEmDispositivo: DateTime.utc(2026, 8, 10),
      ultimoAlteradorUserId: 'ator-forjado',
      ultimaAlteracaoEm: DateTime.utc(2026, 8, 10, 12),
    );

    final json = dto.toJson();

    expect(json, isNot(contains('ultimo_alterador_user_id')));
    expect(json, isNot(contains('ultima_alteracao_em')));
    expect(json, isNot(contains('rat_audit_log')));
  });
}
