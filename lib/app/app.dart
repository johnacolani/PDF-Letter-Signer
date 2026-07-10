import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_letter_signer/app/di/injection_container.dart';
import 'package:pdf_letter_signer/core/design_system/app_theme.dart';
import 'package:pdf_letter_signer/features/document_picker/presentation/bloc/document_picker_bloc.dart';
import 'package:pdf_letter_signer/features/document_picker/presentation/pages/home_page.dart';
import 'package:pdf_letter_signer/features/pdf_editor/presentation/bloc/pdf_editor_bloc.dart';
import 'package:pdf_letter_signer/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pdf_letter_signer/features/signature/presentation/bloc/signature_cubit.dart';

class PdfLetterSignerApp extends StatelessWidget {
  const PdfLetterSignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ThemeCubit>()),
        BlocProvider(create: (_) => getIt<DocumentPickerBloc>()),
        BlocProvider(create: (_) => getIt<PdfEditorBloc>()),
        BlocProvider(create: (_) => getIt<SignatureCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'PDF Letter Signer',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
