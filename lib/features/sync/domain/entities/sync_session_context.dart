/// Contexto tipado da sessao usada para definir o escopo de um item de sync.
///
/// Representa **quem executa a acao** (sessao atual), e nao o criador da
/// entidade. Substitui o uso de dois `String` soltos (`empresaId`/`usuarioId`),
/// reduzindo o risco de inverter parametros ou misturar contextos.
final class SyncSessionContext {
  const SyncSessionContext({required this.empresaId, required this.usuarioId});

  final String empresaId;
  final String usuarioId;

  bool get isValid => empresaId.isNotEmpty && usuarioId.isNotEmpty;
}
