import 'package:flutter/material.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';

class DraggableSignatureOverlay extends StatelessWidget {
  const DraggableSignatureOverlay({
    required this.placement,
    required this.onChanged,
    super.key,
  });

  final SignaturePlacement placement;
  final void Function(double x, double y, double width, double height)
  onChanged;

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
                  final nextX = (placement.x +
                          details.delta.dx / constraints.maxWidth)
                      .clamp(0.0, 1.0 - placement.width);
                  final nextY = (placement.y +
                          details.delta.dy / constraints.maxHeight)
                      .clamp(0.0, 1.0 - placement.height);
                  onChanged(nextX, nextY, placement.width, placement.height);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                      child: Image.memory(
                        placement.pngBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          final nextWidth = (placement.width +
                                  details.delta.dx / constraints.maxWidth)
                              .clamp(0.05, 1.0 - placement.x);
                          final nextHeight = (placement.height +
                                  details.delta.dy / constraints.maxHeight)
                              .clamp(0.03, 1.0 - placement.y);
                          onChanged(
                            placement.x,
                            placement.y,
                            nextWidth,
                            nextHeight,
                          );
                        },
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            border: Border.all(color: Colors.white, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.open_in_full,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
