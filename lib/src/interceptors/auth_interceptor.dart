import 'package:dio/dio.dart';

/// A typedef for a function that asynchronously retrieves an
/// authentication token.
///
/// Returns the token string or null if no token is available.
typedef TokenProvider = Future<String?> Function();

/// Dio interceptor to automatically add the Authorization header (Bearer token)
/// to requests.
class AuthInterceptor extends Interceptor {
  /// Creates an [AuthInterceptor].
  ///
  /// Requires a [tokenProvider] function that will be called to get the
  /// latest token before each request.
  AuthInterceptor({required this.tokenProvider});

  /// Function responsible for providing the authentication token.
  final TokenProvider tokenProvider;

  /// The HTTP header key for authorization.
  static const String _authorizationHeader = 'Authorization';

  /// The prefix for the Bearer token value.
  static const String _bearerPrefix = 'Bearer ';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenProvider();

    if (token != null && token.isNotEmpty) {
      options.headers[_authorizationHeader] = '$_bearerPrefix$token';
    }

    // Continue with the request
    handler.next(options);
  }

  // Optionally, you could override onError or onResponse if needed,
  // but for simple token injection, onRequest is usually sufficient.
}
