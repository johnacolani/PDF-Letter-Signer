import 'package:get_it/get_it.dart';
import 'package:pdf_letter_signer/features/document_picker/data/file_picker_service.dart';
import 'package:pdf_letter_signer/features/document_picker/domain/document_source_picker.dart';
import 'package:pdf_letter_signer/features/document_picker/presentation/bloc/document_picker_bloc.dart';
import 'package:pdf_letter_signer/features/pdf_editor/data/repositories/syncfusion_pdf_editor_repository.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/repositories/pdf_editor_repository.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/usecases/export_signed_pdf.dart';
import 'package:pdf_letter_signer/features/pdf_editor/presentation/bloc/pdf_editor_bloc.dart';
import 'package:pdf_letter_signer/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pdf_letter_signer/features/signature/presentation/bloc/signature_cubit.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  getIt
    ..registerLazySingleton<DocumentSourcePicker>(FilePickerService.new)
    ..registerLazySingleton<PdfEditorRepository>(
      SyncfusionPdfEditorRepository.new,
    )
    ..registerLazySingleton(() => ExportSignedPdf(getIt()))
    ..registerFactory(() => DocumentPickerBloc(getIt()))
    ..registerFactory(() => PdfEditorBloc(getIt()))
    ..registerFactory(ThemeCubit.new)
    ..registerFactory(SignatureCubit.new);
}
