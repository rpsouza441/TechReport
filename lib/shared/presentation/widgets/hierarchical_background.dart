import 'package:flutter/material.dart';

/// Background com hierarquia visual sutil.
///
/// Aplica um degradê vertical suave que transita de `surfaceContainerHighest`
/// no topo para `surface` na base da tela.
///
/// Sem linha dura, sem curva customizada — apenas `LinearGradient`
/// com duas cores da paleta Material 3 do tema.
///
/// Uso em telas de home/lista (não em formulários densos):
/// ```dart
/// body: HierarchicalBackground(
///   child: MinhaLista(),
/// ),
/// ```
///
/// A `NavigationBar` e `AppBar` do tema ficam sobre o gradiente com cor
/// sólida, criando hierarquia visual orgânica: header mais concentrado no topo,
/// conteúdo mais aberto na base.
class HierarchicalBackground extends StatelessWidget {
  const HierarchicalBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surface,
          ],
          // Topo estável até ~70% da tela; transição suave no último terço.
          stops: const [0.0, 0.72],
        ),
      ),
      child: child,
    );
  }
}

/// Helper para construir o gradiente como [BoxDecoration].
/// Útil em Preview, testes e widgets que precisam da decoração pronta.
BoxDecoration hierarchicalBackgroundDecoration(ColorScheme colorScheme) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colorScheme.surfaceContainerHighest,
        colorScheme.surface,
      ],
      stops: const [0.0, 0.72],
    ),
  );
}