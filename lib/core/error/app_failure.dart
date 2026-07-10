import 'package:equatable/equatable.dart';

class AppFailure extends Equatable implements Exception {
  const AppFailure(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];
}
