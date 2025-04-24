/// A robust HTTP client built on top of Dio, providing simplified API calls,
/// automatic authentication header injection, and custom exception mapping.
library;

// Export the custom exception types
export 'src/exceptions.dart';
// Export the main client class
export 'src/ht_http_client.dart' show HtHttpClient;
// Export the TokenProvider typedef for convenience
export 'src/interceptors/auth_interceptor.dart' show TokenProvider;
