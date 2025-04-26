import 'package:dio/dio.dart';
import 'package:ht_http_client/src/interceptors/auth_interceptor.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Helper class to mock the typedef
abstract class CallableTokenProvider {
  Future<String?> call();
}

// Mocks using mocktail
class MockCallableTokenProvider extends Mock implements CallableTokenProvider {}

class MockRequestOptions extends Mock implements RequestOptions {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

void main() {
  group('AuthInterceptor', () {
    late MockCallableTokenProvider mockCallableTokenProvider;
    late AuthInterceptor interceptor;
    late MockRequestOptions mockRequestOptions;
    late MockRequestInterceptorHandler mockHandler;

    setUp(() {
      mockCallableTokenProvider = MockCallableTokenProvider();
      // Pass the call method of the mock which matches the typedef signature
      interceptor = AuthInterceptor(
        tokenProvider: mockCallableTokenProvider.call,
      );
      mockRequestOptions = MockRequestOptions();
      mockHandler = MockRequestInterceptorHandler();

      // REMOVED: when(() => mockRequestOptions.headers).thenReturn({});
      // We will stub the headers getter directly when needed in the test.
    });

    test('should add Authorization header when token is provided', () async {
      // Stub the headers getter for this specific test case
      final headersMap = <String, dynamic>{};
      when(() => mockRequestOptions.headers).thenReturn(headersMap);

      const token = 'test_token';
      // Mock the call method - ensure the async keyword is inside the closure
      when(() => mockCallableTokenProvider.call()).thenAnswer((_) async {
        return token;
      });

      await interceptor.onRequest(mockRequestOptions, mockHandler);

      // Verify the call method was called
      verify(() => mockCallableTokenProvider.call()).called(1);

      // Verify Authorization header was added correctly
      expect(
        headersMap['Authorization'], // Check the actual map used in the stub
        'Bearer $token',
      );

      // Verify handler.next was called with the modified options
      verify(() => mockHandler.next(mockRequestOptions)).called(1);
    });

    test('should NOT add Authorization header when token is null', () async {
      // Stub the headers getter for this specific test case
      final headersMap = <String, dynamic>{};
      when(() => mockRequestOptions.headers).thenReturn(headersMap);

      // Mock the call method - ensure the async keyword is inside the closure
      when(() => mockCallableTokenProvider.call()).thenAnswer((_) async {
        return null;
      });

      await interceptor.onRequest(mockRequestOptions, mockHandler);

      // Verify the call method was called
      verify(() => mockCallableTokenProvider.call()).called(1);

      // Verify Authorization header was NOT added
      expect(
        headersMap.containsKey('Authorization'),
        isFalse,
      ); // Check the actual map

      // Verify handler.next was called
      verify(() => mockHandler.next(mockRequestOptions)).called(1);
    });

    test('should NOT add Authorization header when token is empty', () async {
      // Stub the headers getter for this specific test case
      final headersMap = <String, dynamic>{};
      when(() => mockRequestOptions.headers).thenReturn(headersMap);

      // Mock the call method - ensure the async keyword is inside the closure
      when(() => mockCallableTokenProvider.call()).thenAnswer((_) async {
        return '';
      });

      await interceptor.onRequest(mockRequestOptions, mockHandler);

      // Verify the call method was called
      verify(() => mockCallableTokenProvider.call()).called(1);

      // Verify Authorization header was NOT added
      expect(
        headersMap.containsKey('Authorization'),
        isFalse,
      ); // Check the actual map

      // Verify handler.next was called
      verify(() => mockHandler.next(mockRequestOptions)).called(1);
    });
  });
}
