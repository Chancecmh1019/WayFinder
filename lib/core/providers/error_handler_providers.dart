import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/error_handler_service.dart';

/// Provider for ErrorHandlerService instance
final errorHandlerServiceProvider = Provider<ErrorHandlerService>((ref) {
  return ErrorHandlerService.instance;
});

/// Provider for handling errors with user-friendly messages
final errorMessageProvider = Provider.family<String, dynamic>((ref, error) {
  final service = ref.watch(errorHandlerServiceProvider);
  
  if (error is Exception) {
    return service.handleException(error);
  } else if (error is Error) {
    return service.handleFailure(error as dynamic);
  }
  
  return '發生未知錯誤';
});
