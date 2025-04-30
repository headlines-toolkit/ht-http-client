import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ht_http_client/src/interceptors/error_interceptor.dart';
import 'package:ht_shared/ht_shared.dart'; // Updated import
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Mocks using mocktail
class MockDioException extends Mock implements DioException {}

class MockResponse<T> extends Mock implements Response<T> {}

class MockRequestOptions extends Mock implements RequestOptions {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class MockSocketException extends Mock implements SocketException {}

void main() {
  group('ErrorInterceptor', () {
    late ErrorInterceptor interceptor;
    late MockErrorInterceptorHandler mockHandler;
    late MockRequestOptions mockRequestOptions;

    setUp(() {
      interceptor = ErrorInterceptor();
      mockHandler = MockErrorInterceptorHandler();
      mockRequestOptions = MockRequestOptions();

      // Stub the required getter that was causing the error
      when(() => mockRequestOptions.preserveHeaderCase).thenReturn(false);

      // Register fallback values for mocks if needed, especially for complex types
      registerFallbackValue(mockRequestOptions);
      registerFallbackValue(MockDioException()); // Fallback for DioException
      registerFallbackValue(
        DioExceptionType.unknown,
      ); // Fallback for DioExceptionType enum
      registerFallbackValue(RequestOptions()); // Fallback for RequestOptions
    });

    // Helper function to verify the rejection
    void verifyRejection<T extends HtHttpException>({
      required DioException originalDioErr,
      String? expectedMessage, // Optional: for specific message checks
    }) {
      final captured =
          verify(
                () => mockHandler.reject(captureAny<DioException>()),
              ).captured.single
              as DioException;

      expect(captured.error, isA<T>());
      expect(captured.error, isNotNull);
      // Removed check for dioException as it's no longer part of HtHttpException
      expect(captured.requestOptions, originalDioErr.requestOptions);
      expect(captured.response, originalDioErr.response);
      expect(captured.type, originalDioErr.type);
      // Check message if provided
      if (expectedMessage != null) {
        expect((captured.error! as HtHttpException).message, expectedMessage);
      }
    }

    // --- Test Cases for DioExceptionType ---

    test('onError maps connectionTimeout to NetworkException', () {
      final dioErr = DioException(
        requestOptions: mockRequestOptions,
        type: DioExceptionType.connectionTimeout,
      );
      interceptor.onError(dioErr, mockHandler);
      verifyRejection<NetworkException>(originalDioErr: dioErr);
    });

    test('onError maps sendTimeout to NetworkException', () {
      final dioErr = DioException(
        requestOptions: mockRequestOptions,
        type: DioExceptionType.sendTimeout,
      );
      interceptor.onError(dioErr, mockHandler);
      verifyRejection<NetworkException>(originalDioErr: dioErr);
    });

    test('onError maps receiveTimeout to NetworkException', () {
      final dioErr = DioException(
        requestOptions: mockRequestOptions,
        type: DioExceptionType.receiveTimeout,
      );
      interceptor.onError(dioErr, mockHandler);
      verifyRejection<NetworkException>(originalDioErr: dioErr);
    });

    test('onError maps connectionError to NetworkException', () {
      final dioErr = DioException(
        requestOptions: mockRequestOptions,
        type: DioExceptionType.connectionError,
      );
      interceptor.onError(dioErr, mockHandler);
      verifyRejection<NetworkException>(originalDioErr: dioErr);
    });

    test('onError maps badCertificate to NetworkException', () {
      final dioErr = DioException(
        requestOptions: mockRequestOptions,
        type: DioExceptionType.badCertificate,
      );
      interceptor.onError(dioErr, mockHandler);
      verifyRejection<NetworkException>(originalDioErr: dioErr);
    });

    test('onError maps unknown with SocketException to NetworkException', () {
      final socketErr = MockSocketException();
      final dioErr = DioException(
        requestOptions: mockRequestOptions,
        error: socketErr,
      );
      interceptor.onError(dioErr, mockHandler);
      verifyRejection<NetworkException>(originalDioErr: dioErr);
    });

    test('onError maps cancel to UnknownException', () {
      final dioErr = DioException(
        requestOptions: mockRequestOptions,
        type: DioExceptionType.cancel,
      );
      interceptor.onError(dioErr, mockHandler);
      verifyRejection<UnknownException>(
        originalDioErr: dioErr,
        expectedMessage: 'Request cancelled',
      );
    });

    test(
      'onError maps unknown without SocketException to UnknownException',
      () {
        final dioErr = DioException(
          requestOptions: mockRequestOptions,
          error: Exception('Some other error'),
          message: 'Generic unknown error',
        );
        interceptor.onError(dioErr, mockHandler);
        verifyRejection<UnknownException>(
          originalDioErr: dioErr,
          expectedMessage: 'Generic unknown error',
        );
      },
    );

    test(
      'onError maps unknown without SocketException and null message to UnknownException',
      () {
        final dioErr = DioException(
          requestOptions: mockRequestOptions,
          error: Exception('Some other error'),
        );
        interceptor.onError(dioErr, mockHandler);
        verifyRejection<UnknownException>(
          originalDioErr: dioErr,
          expectedMessage: 'An unknown error occurred',
        );
      },
    );

    // --- Test Cases for BadResponse Status Codes ---

    group('BadResponse Handling', () {
      // No need for createMockResponse helper anymore

      test(
        'maps 400 to BadRequestException with message from response[message]',
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 400,
            data: {'message': 'Invalid input'},
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<BadRequestException>(
            originalDioErr: dioErr,
            expectedMessage: 'Invalid input',
          );
        },
      );

      test(
        'maps 400 to BadRequestException with message from response[error]',
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 400,
            data: {'error': 'Bad data format'},
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<BadRequestException>(
            originalDioErr: dioErr,
            expectedMessage: 'Bad data format',
          );
        },
      );

      test(
        'maps 400 to BadRequestException with message from response[detail]',
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 400,
            data: {'detail': 'Missing field X'},
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<BadRequestException>(
            originalDioErr: dioErr,
            expectedMessage: 'Missing field X',
          );
        },
      );

      test(
        'maps 400 to BadRequestException with message from response[String]',
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 400,
            data: 'Direct error string',
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<BadRequestException>(
            originalDioErr: dioErr,
            expectedMessage: 'Direct error string',
          );
        },
      );

      test(
        'maps 400 to BadRequestException with default message if extraction fails',
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 400,
            data: {'other_key': 'some value'}, // No standard message key
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Dio default message', // Provide Dio message
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<BadRequestException>(
            originalDioErr: dioErr,
            expectedMessage: 'Dio default message',
          );
        },
      );

      test(
        'maps 400 to BadRequestException with generic message if extraction and dio message fail',
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 400,
            data: {'other_key': 'some value'}, // No standard message key
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<BadRequestException>(
            originalDioErr: dioErr,
            expectedMessage: 'Unknown error occurred',
          );
        },
      );

      // --- Tests for edge cases in _extractErrorMessage ---

      test(
        "maps 400 to BadRequestException when responseData['message'] is not a String",
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 400,
            data: {'message': 123}, // Non-string value
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Dio default message',
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<BadRequestException>(
            originalDioErr: dioErr,
            expectedMessage: 'Dio default message', // Should fallback
          );
        },
      );

      test(
        "maps 400 to BadRequestException when responseData['error'] is not a String",
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 400,
            data: {'error': true}, // Non-string value
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Dio default message',
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<BadRequestException>(
            originalDioErr: dioErr,
            expectedMessage: 'Dio default message', // Should fallback
          );
        },
      );

      test(
        "maps 400 to BadRequestException when responseData['detail'] is not a String",
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 400,
            //
            // ignore: inference_failure_on_collection_literal
            data: {'detail': {}}, // Non-string value
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Dio default message',
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<BadRequestException>(
            originalDioErr: dioErr,
            expectedMessage: 'Dio default message', // Should fallback
          );
        },
      );

      test('maps 400 to BadRequestException when responseData is a List', () {
        final response = Response(
          requestOptions: mockRequestOptions,
          statusCode: 400,
          data: ['error message in list'], // List, not Map or String
        );
        final dioErr = DioException(
          requestOptions: mockRequestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Dio default message',
        );
        interceptor.onError(dioErr, mockHandler);
        verifyRejection<BadRequestException>(
          originalDioErr: dioErr,
          expectedMessage: 'Dio default message', // Should fallback
        );
      });

      test(
        'maps 400 to BadRequestException when responseData is an Integer',
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 400,
            data: 400, // Integer, not Map or String
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Dio default message',
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<BadRequestException>(
            originalDioErr: dioErr,
            expectedMessage: 'Dio default message', // Should fallback
          );
        },
      );

      // --- End of edge case tests ---

      test('maps 401 to UnauthorizedException', () {
        final response = Response(
          requestOptions: mockRequestOptions,
          statusCode: 401,
          data: {'message': 'Auth required'},
        );
        final dioErr = DioException(
          requestOptions: mockRequestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(dioErr, mockHandler);
        verifyRejection<UnauthorizedException>(
          originalDioErr: dioErr,
          expectedMessage: 'Auth required',
        );
      });

      test('maps 403 to ForbiddenException', () {
        final response = Response(
          requestOptions: mockRequestOptions,
          statusCode: 403,
          data: 'Permission denied',
        );
        final dioErr = DioException(
          requestOptions: mockRequestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(dioErr, mockHandler);
        verifyRejection<ForbiddenException>(
          originalDioErr: dioErr,
          expectedMessage: 'Permission denied',
        );
      });

      test('maps 404 to NotFoundException', () {
        final response = Response(
          requestOptions: mockRequestOptions,
          statusCode: 404,
          data: {'detail': 'Resource not found'},
        );
        final dioErr = DioException(
          requestOptions: mockRequestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(dioErr, mockHandler);
        verifyRejection<NotFoundException>(
          originalDioErr: dioErr,
          expectedMessage: 'Resource not found',
        );
      });

      test('maps 500 to ServerException', () {
        final response = Response(
          requestOptions: mockRequestOptions,
          statusCode: 500,
          data: 'Internal server error',
        );
        final dioErr = DioException(
          requestOptions: mockRequestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(dioErr, mockHandler);
        verifyRejection<ServerException>(
          originalDioErr: dioErr,
          expectedMessage: 'Internal server error',
        );
      });

      test('maps 503 to ServerException', () {
        final response = Response(
          requestOptions: mockRequestOptions,
          statusCode: 503,
          data: {'error': 'Service Unavailable'},
        );
        final dioErr = DioException(
          requestOptions: mockRequestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(dioErr, mockHandler);
        verifyRejection<ServerException>(
          originalDioErr: dioErr,
          expectedMessage: 'Service Unavailable',
        );
      });

      test(
        'maps other non-2xx status codes (e.g., 418) to UnknownException',
        () {
          final response = Response(
            requestOptions: mockRequestOptions,
            statusCode: 418,
            data: "I'm a teapot",
          );
          final dioErr = DioException(
            requestOptions: mockRequestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
          interceptor.onError(dioErr, mockHandler);
          verifyRejection<UnknownException>(
            originalDioErr: dioErr,
            expectedMessage:
                "Received invalid status code: 418. Message: I'm a teapot",
          );
        },
      );

      test('maps null status code to UnknownException', () {
        // Can't use Response constructor directly with null status code easily
        // Use a mock response just for this specific case
        final mockResp = MockResponse<dynamic>();
        when(() => mockResp.statusCode).thenReturn(null);
        when(() => mockResp.data).thenReturn('Some data');
        when(() => mockResp.requestOptions).thenReturn(mockRequestOptions);

        final dioErr = DioException(
          requestOptions: mockRequestOptions,
          response: mockResp, // Use the mock response here
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(dioErr, mockHandler);
        verifyRejection<UnknownException>(
          originalDioErr: dioErr,
          expectedMessage:
              'Received response with null status code. Message: Some data',
        );
      });
    });
  });
}
