import 'package:flutter/material.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';

/// Keeps pointer-frequency signature changes local and commits once on release.
class DraggableSignatureOverlay extends StatefulWidget {
  const DraggableSignatureOverlay({
    required this.placement,
    required this.onCommitted,
    super.key,
  });

  final SignaturePlacement placement;
  final ValueChanged<SignaturePlacement> onCommitted;

  @override
  State<DraggableSignatureOverlay> createState() =>
      _DraggableSignatureOverlayState();
}

class _DraggableSignatureOverlayState extends State<DraggableSignatureOverlay> {
  late final ValueNotifier<SignaturePlacement> _temporaryPlacement;
  bool _interacting = false;

  @override
  void initState() {
    super.initState();
    _temporaryPlacement = ValueNotifier(widget.placement);
  }

  @override
  void didUpdateWidget(covariant DraggableSignatureOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interacting && oldWidget.placement != widget.placement) {
      _temporaryPlacement.value = widget.placement;
    }
  }

  void _startInteraction() => _interacting = true;

  void _finishInteraction(DragEndDetails _) {
    _interacting = false;
    final placement = _temporaryPlacement.value;
    if (placement != widget.placement) widget.onCommitted(placement);
  }

  @override
  void dispose() {
    _temporaryPlacement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ValueListenableBuilder<SignaturePlacement>(
            valueListenable: _temporaryPlacement,
            builder: (context, placement, _) {
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
                      onPanStart: (_) => _startInteraction(),
                      onPanUpdate: (details) {
                        final current = _temporaryPlacement.value;
                        _temporaryPlacement.value = current.copyWith(
                          x: (current.x +
                                  details.delta.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0 - current.width),
                          y: (current.y +
                                  details.delta.dy / constraints.maxHeight)
                              .clamp(0.0, 1.0 - current.height),
                        );
                      },
                      onPanEnd: _finishInteraction,
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
                              gaplessPlayback: true,
                            ),
                          ),
                          Positioned(
                            right: -8,
                            bottom: -8,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (_) => _startInteraction(),
                              onPanUpdate: (details) {
                                final current = _temporaryPlacement.value;
                                _temporaryPlacement.value = current.copyWith(
                                  width: (current.width +
                                          details.delta.dx /
                                              constraints.maxWidth)
                                      .clamp(0.05, 1.0 - current.x),
                                  height: (current.height +
                                          details.delta.dy /
                                              constraints.maxHeight)
                                      .clamp(0.03, 1.0 - current.y),
                                );
                              },
                              onPanEnd: _finishInteraction,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
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
        },
      ),
    );
  }
}
