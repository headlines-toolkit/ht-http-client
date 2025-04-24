import 'package:dio/dio.dart';

/// Base class for all custom HTTP exceptions thrown by HtHttpClient.
sealed class HtHttpException implements Exception {
  /// {@macro ht_http_exception}
  const HtHttpException(this.message, [this.dioException]);

  /// The error message associated with the exception.
  final String message;

  /// The original DioException, if available.
  final DioException? dioException;

  @override
  String toString() => 'HtHttpException: $message';
}

/// Exception thrown when a network error occurs (e.g., no internet connection).
final class NetworkException extends HtHttpException {
  /// {@macro network_exception}
  const NetworkException([DioException? dioException])
    : super('Network error occurred', dioException);
}

/// Exception thrown for 400 Bad Request errors.
final class BadRequestException extends HtHttpException {
  /// {@macro bad_request_exception}
  const BadRequestException(super.message, [super.dioException]);
}

/// Exception thrown for 401 Unauthorized errors.
final class UnauthorizedException extends HtHttpException {
  /// {@macro unauthorized_exception}
  const UnauthorizedException(super.message, [super.dioException]);
}

/// Exception thrown for 403 Forbidden errors.
final class ForbiddenException extends HtHttpException {
  /// {@macro forbidden_exception}
  const ForbiddenException(super.message, [super.dioException]);
}

/// Exception thrown for 404 Not Found errors.
final class NotFoundException extends HtHttpException {
  /// {@macro not_found_exception}
  const NotFoundException(super.message, [super.dioException]);
}

/// Exception thrown for 5xx Server errors.
final class ServerException extends HtHttpException {
  /// {@macro server_exception}
  const ServerException(super.message, [super.dioException]);
}

/// Exception thrown for unexpected errors.
final class UnknownException extends HtHttpException {
  /// {@macro unknown_exception}
  const UnknownException(super.message, [super.dioException]);
}
