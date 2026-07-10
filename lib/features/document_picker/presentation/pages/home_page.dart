import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_letter_signer/core/design_system/app_spacing.dart';
import 'package:pdf_letter_signer/features/document_picker/presentation/bloc/document_picker_bloc.dart';
import 'package:pdf_letter_signer/features/pdf_editor/presentation/bloc/pdf_editor_bloc.dart';
import 'package:pdf_letter_signer/features/pdf_editor/presentation/pages/pdf_editor_page.dart';
import 'package:pdf_letter_signer/features/settings/presentation/bloc/theme_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentPickerBloc, DocumentPickerState>(
      listener: (context, state) {
        if (state case DocumentPickerSuccess(:final document)) {
          context.read<PdfEditorBloc>().add(PdfEditorDocumentOpened(document));
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PdfEditorPage()),
          );
        } else if (state case DocumentPickerFailure(:final message)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PDF Letter Signer'),
          actions: [
            IconButton(
              tooltip: 'Change theme',
              onPressed: () => context.read<ThemeCubit>().toggle(),
              icon: const Icon(Icons.brightness_6_outlined),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 88,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Edit and sign PDF letters',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Open a PDF, draw a signature, place it on the page, and export a newly signed copy.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  BlocBuilder<DocumentPickerBloc, DocumentPickerState>(
                    builder: (context, state) {
                      return FilledButton.icon(
                        onPressed:
                            state is DocumentPickerLoading
                                ? null
                                : () => context.read<DocumentPickerBloc>().add(
                                  const DocumentPickerRequested(),
                                ),
                        icon:
                            state is DocumentPickerLoading
                                ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.folder_open),
                        label: const Text('Open PDF'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
