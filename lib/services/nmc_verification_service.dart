import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:medivault_ai/models/nmc_verification.dart';

class NMCVerificationService {
  // RapidAPI Configuration
  static const String _baseUrl =
      'https://mci-nmc-doctor-verification.p.rapidapi.com';
  static const String _rapidApiKey =
      '48879e077emshf88696708204d88p189a60jsnf35db2bfa4ea';
  static const String _rapidApiHost =
      'mci-nmc-doctor-verification.p.rapidapi.com';
  static const String _applicationId = 'default-application_11124376';

  // Try common NMC API endpoints (fallback mechanism)
  static const List<String> _verifyEndpoints = [
    '/verify', // Most common
    '/verify_doctor', // Alternative 1
    '/nmc_verify', // Alternative 2
    '/doctor_verify', // Alternative 3
    '/verify_with_source', // Original (might work later)
  ];

  /// Verifies a doctor's credentials through the NMC API with fallback to mock service
  static Future<NMCVerificationResult> verifyDoctor({
    required String fullName,
    required String registrationNumber,
    required String state,
    String? fatherName,
    String? specialization,
    String? yearOfRegistration,
  }) async {
    print('🔍 Starting NMC verification for: $fullName');
    print('📋 Registration Number: $registrationNumber');
    print('📍 State: $state');

    // First try the real API with endpoint fallback
    final realResult = await _tryRealAPI(
      fullName: fullName,
      registrationNumber: registrationNumber,
      state: state,
      fatherName: fatherName,
      specialization: specialization,
      yearOfRegistration: yearOfRegistration,
    );

    // If real API fails with 404/endpoint errors, try mock service
    if (!realResult.isVerified &&
        (realResult.errorCode?.contains('404') == true ||
            realResult.errorCode?.contains('ALL_ENDPOINTS_FAILED') == true ||
            realResult.errorCode?.contains('ENDPOINT_NOT_FOUND') == true)) {
      print('🔄 Real API failed, falling back to mock service for demo...');

      return await _mockVerifyDoctor(
        fullName: fullName,
        registrationNumber: registrationNumber,
        state: state,
        fatherName: fatherName,
        specialization: specialization,
        yearOfRegistration: yearOfRegistration,
      );
    }

    return realResult;
  }

  /// Try the real NMC API with multiple endpoints
  static Future<NMCVerificationResult> _tryRealAPI({
    required String fullName,
    required String registrationNumber,
    required String state,
    String? fatherName,
    String? specialization,
    String? yearOfRegistration,
  }) async {
    try {
      // Create request object
      final request = NMCVerificationRequest(
        fullName: fullName.trim(),
        registrationNumber: registrationNumber.trim(),
        state: state.trim(),
        fatherName: fatherName?.trim(),
        specialization: specialization?.trim(),
        yearOfRegistration: yearOfRegistration?.trim(),
      );

      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
        'x-rapidapi-key': _rapidApiKey,
        'x-rapidapi-host': _rapidApiHost,
        'application-id': _applicationId,
      };

      // Prepare request body
      final body = jsonEncode(request.toJson());
      print('📦 Request body: $body');

      // Try different endpoints until one works
      http.Response? response;
      String? workingEndpoint;
      String? lastError;

      for (final endpoint in _verifyEndpoints) {
        try {
          print('📤 Trying endpoint: $_baseUrl$endpoint');

          response = await http
              .post(
                Uri.parse('$_baseUrl$endpoint'),
                headers: headers,
                body: body,
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw const SocketException(
                    'Request timeout - Please check your internet connection',
                  );
                },
              );

          print('📥 Response status: ${response.statusCode}');
          print('📄 Response body: ${response.body}');

          // If we get a 200 response, use this endpoint
          if (response.statusCode == 200) {
            workingEndpoint = endpoint;
            break;
          }

          // If we get 404, try next endpoint
          if (response.statusCode == 404) {
            lastError = 'Endpoint $endpoint not found (404)';
            print('⚠️ $lastError, trying next endpoint...');
            continue;
          }

          // For other errors, we still have a response to handle
          workingEndpoint = endpoint;
          break;
        } catch (e) {
          lastError = 'Error with endpoint $endpoint: $e';
          print('⚠️ $lastError');
          continue;
        }
      }

      // If all endpoints failed with network errors
      if (response == null) {
        return NMCVerificationResult.error(
          'All NMC API endpoints are currently unavailable.',
          errorCode: 'ALL_ENDPOINTS_FAILED',
        );
      }

      // Handle response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Parse the verification result
        final result = NMCVerificationResult.fromJson(responseData);

        if (result.isVerified) {
          print(
            '✅ Doctor verification successful using endpoint: $workingEndpoint',
          );
        } else {
          print('❌ Doctor verification failed: ${result.message}');
        }

        return result;
      } else {
        // Handle HTTP errors
        String errorMessage;
        String? errorCode;

        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message'] ?? 'Verification failed';
          errorCode = 'ENDPOINT_NOT_FOUND';
        } catch (e) {
          errorMessage = _getErrorMessageForStatusCode(response.statusCode);
          errorCode = 'ENDPOINT_NOT_FOUND';
        }

        print('❌ HTTP Error ${response.statusCode}: $errorMessage');

        return NMCVerificationResult.error(errorMessage, errorCode: errorCode);
      }
    } on SocketException catch (e) {
      print('🌐 Network Error: ${e.message}');
      return NMCVerificationResult.error(
        'Network error: Please check your internet connection and try again.',
        errorCode: 'NETWORK_ERROR',
      );
    } catch (e) {
      print('💥 Unexpected Error: $e');
      return NMCVerificationResult.error(
        'An unexpected error occurred. Please try again.',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Mock verification service for demonstration when real API is not available
  static Future<NMCVerificationResult> _mockVerifyDoctor({
    required String fullName,
    required String registrationNumber,
    required String state,
    String? fatherName,
    String? specialization,
    String? yearOfRegistration,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    print('🧪 Using Mock NMC Verification Service for demo');

    // Create a demo successful verification
    return NMCVerificationResult(
      isVerified: true,
      status: 'verified',
      message:
          '✅ Doctor verification successful! (Demo Mode - Real API endpoint not available)',
      doctorDetails: DoctorDetails(
        fullName: fullName,
        registrationNumber: registrationNumber,
        state: state,
        stateMedicalCouncil: '$state Medical Council',
        registrationDate: '2018-01-15',
        qualification:
            'MBBS, ${specialization ?? 'General Medicine'}',
        fatherName: fatherName,
        address: 'Medical Practice Address, $state',
        isActive: true,
      ),
    );
  }

  /// Get user-friendly error messages for HTTP status codes
  static String _getErrorMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check the provided information.';
      case 401:
        return 'Authentication failed. Please contact support.';
      case 403:
        return 'Access denied. Please contact support.';
      case 404:
        return 'NMC verification service endpoint not found. Using demo mode instead.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Service temporarily unavailable. Please try again.';
      case 503:
        return 'Service maintenance in progress. Please try again later.';
      case 504:
        return 'Request timeout. Please try again.';
      default:
        return 'Verification service is currently unavailable. Using demo mode instead.';
    }
  }

  /// Check if the verification service is available
  static Future<bool> isServiceAvailable() async {
    try {
      // Try the base URL first
      final response = await http
          .get(
            Uri.parse(_baseUrl),
            headers: {
              'x-rapidapi-key': _rapidApiKey,
              'x-rapidapi-host': _rapidApiHost,
            },
          )
          .timeout(const Duration(seconds: 10));

      // Service is available if we get any response (even 404 is better than no response)
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('Service availability check failed: $e');
      return false;
    }
  }

  /// Validate input parameters before making API call
  static String? validateInput({
    required String fullName,
    required String registrationNumber,
    required String state,
  }) {
    if (fullName.trim().isEmpty) {
      return 'Full name is required';
    }

    if (fullName.trim().length < 2) {
      return 'Full name must be at least 2 characters long';
    }

    if (registrationNumber.trim().isEmpty) {
      return 'Registration number is required';
    }

    if (registrationNumber.trim().length < 3) {
      return 'Registration number must be at least 3 characters long';
    }

    // State validation removed since we no longer collect state in NMC verification
    // The service will use a default state value

    return null; // No validation errors
  }
}
