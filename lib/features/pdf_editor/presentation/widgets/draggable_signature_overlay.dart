import 'package:flutter/material.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';

class DraggableSignatureOverlay extends StatelessWidget {
  const DraggableSignatureOverlay({
    required this.placement,
    required this.onMoved,
    super.key,
  });

  final SignaturePlacement placement;
  final void Function(double x, double y) onMoved;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final overlayWidth = constraints.maxWidth * placement.width;
        final overlayHeight = constraints.maxHeight * placement.height;
        final left = constraints.maxWidth * placement.x;
        final top = constraints.maxHeight * placement.y;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: overlayWidth,
              height: overlayHeight,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final nextX = (placement.x + details.delta.dx / constraints.maxWidth)
                      .clamp(0.0, 1.0 - placement.width);
                  final nextY = (placement.y + details.delta.dy / constraints.maxHeight)
                      .clamp(0.0, 1.0 - placement.height);
                  onMoved(nextX, nextY);
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                  child: Image.memory(placement.pngBytes, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
