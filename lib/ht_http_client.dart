/// A robust HTTP client built on top of Dio, providing simplified API calls,
/// automatic authentication header injection, and custom exception mapping.
library;

// Export the main client class
export 'src/ht_http_client.dart';
// Export the TokenProvider typedef for convenience
export 'src/interceptors/auth_interceptor.dart' show TokenProvider;
