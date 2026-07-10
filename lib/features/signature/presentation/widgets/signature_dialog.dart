import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf_letter_signer/core/design_system/app_colors.dart';
import 'package:signature/signature.dart';

class SignatureDialog extends StatefulWidget {
  const SignatureDialog({super.key});

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.signatureInk,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_controller.isEmpty) return;
    final Uint8List? bytes = await _controller.toPngBytes(
      height: 320,
      width: 720,
    );
    if (bytes != null && mounted) Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Draw your signature'),
      content: SizedBox(
        width: 620,
        height: 280,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Signature(
            controller: _controller,
            backgroundColor: Colors.white,
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _controller.clear, child: const Text('Clear')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _accept, child: const Text('Use signature')),
      ],
    );
  }
}
