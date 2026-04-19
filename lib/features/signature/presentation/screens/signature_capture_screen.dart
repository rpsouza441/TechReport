import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';

class SignatureCaptureScreen extends StatefulWidget {
  const SignatureCaptureScreen({super.key});

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  final List<List<Offset>> _strokes = [];
  Size _canvasSize = Size.zero;

  bool get _hasSignature => _strokes.any((stroke) => stroke.length > 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Capturar assinatura')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pe\u00e7a para o cliente assinar no quadro abaixo.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Ao virar o telefone, deixe o lado esquerdo como baixo.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _canvasSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );

                        return Stack(
                          children: [
                            GestureDetector(
                              onPanStart: (details) {
                                setState(() {
                                  _strokes.add([details.localPosition]);
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  if (_strokes.isEmpty) {
                                    _strokes.add([]);
                                  }
                                  _strokes.last.add(details.localPosition);
                                });
                              },
                              child: CustomPaint(
                                painter: _SignaturePainter(_strokes),
                                child: const SizedBox.expand(),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        'BAIXO DA ASSINATURA',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _strokes.isEmpty ? null : _clear,
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _hasSignature ? _save : null,
                      child: const Text('Salvar assinatura'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clear() {
    setState(_strokes.clear);
  }

  Future<void> _save() async {
    final bytes = await _exportPng();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(bytes);
  }

  Future<Uint8List> _exportPng() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = _SignaturePainter(_strokes);
    final size = _canvasSize == Size.zero ? const Size(800, 400) : _canvasSize;
    final rotatedSize = Size(size.height, size.width);

    canvas.drawColor(Colors.white, BlendMode.src);
    canvas.translate(0, rotatedSize.height);
    canvas.rotate(-math.pi / 2);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      rotatedSize.width.round(),
      rotatedSize.height.round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        continue;
      }

      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return true;
  }
}
