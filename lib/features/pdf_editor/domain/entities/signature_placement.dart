import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class SignaturePlacement extends Equatable {
  const SignaturePlacement({
    required this.pageIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.pngBytes,
  });

  final int pageIndex;
  final double x;
  final double y;
  final double width;
  final double height;
  final Uint8List pngBytes;

  SignaturePlacement copyWith({
    int? pageIndex,
    double? x,
    double? y,
    double? width,
    double? height,
    Uint8List? pngBytes,
  }) {
    return SignaturePlacement(
      pageIndex: pageIndex ?? this.pageIndex,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      pngBytes: pngBytes ?? this.pngBytes,
    );
  }

  @override
  List<Object?> get props => [pageIndex, x, y, width, height, pngBytes.length];
}
