import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static Map<String, String> _getHeaders({String? token}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Helper method to handle response parsing
  static Map<String, dynamic> _parseResponse(http.Response response) {
    print('📊 Response Status: ${response.statusCode}');
    print('📝 Response Headers: ${response.headers}');
    print('📄 Response Body: ${response.body}');

    if (response.body.trim().startsWith('<!DOCTYPE') ||
        response.body.trim().startsWith('<html')) {
      throw FormatException(
          'Server returned HTML instead of JSON. Status: ${response.statusCode}');
    }

    if (response.body.trim().isEmpty) {
      throw FormatException(
          'Empty response from server. Status: ${response.statusCode}');
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException(
          'Invalid JSON response: $e. Body: ${response.body}');
    }
  }

  // Test server connectivity with multiple approaches
  static Future<Map<String, dynamic>> fullServerTest(String token) async {
    final results = <String, dynamic>{};

    print('🔍 Starting comprehensive server test...');
    print('🌐 Base URL: ${ApiEndpoints.baseUrl}');
    print('🔑 Token provided: ${token.isNotEmpty}');

    // 1. Test base server connectivity
    try {
      print('\n1️⃣ Testing base server...');
      final baseResponse = await http.get(
        Uri.parse(ApiEndpoints.baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 10));

      results['baseServer'] = {
        'status': baseResponse.statusCode,
        'accessible': true,
        'headers': baseResponse.headers,
        'bodyPreview': baseResponse.body.length > 200
            ? baseResponse.body.substring(0, 200) + '...'
            : baseResponse.body,
      };
      print('✅ Base server accessible: ${baseResponse.statusCode}');
    } catch (e) {
      results['baseServer'] = {
        'accessible': false,
        'error': e.toString(),
      };
      print('❌ Base server error: $e');
    }

    // 2. Test common endpoint variations
    final endpointVariations = [
      '/api/transactions',
      '/transactions',
      '/api/transaction',
      '/transaction',
    ];

    for (final endpoint in endpointVariations) {
      try {
        print('\n2️⃣ Testing endpoint: $endpoint');
        final url = '${ApiEndpoints.baseUrl}$endpoint';

        final response = await http
            .get(
              Uri.parse(url),
              headers: _getHeaders(token: token),
            )
            .timeout(Duration(seconds: 10));

        results[endpoint] = {
          'status': response.statusCode,
          'contentType': response.headers['content-type'],
          'bodyPreview': response.body.length > 200
              ? response.body.substring(0, 200) + '...'
              : response.body,
          'isJsonResponse':
              response.headers['content-type']?.contains('application/json') ??
                  false,
        };

        print('📊 $endpoint -> Status: ${response.statusCode}');
        print('📝 Content-Type: ${response.headers['content-type']}');
      } catch (e) {
        results[endpoint] = {
          'error': e.toString(),
          'accessible': false,
        };
        print('❌ $endpoint error: $e');
      }
    }

    // 3. Test authentication with a known working endpoint
    try {
      print('\n3️⃣ Testing authentication...');
      final authTestEndpoints = [
        '/users/balance',
        '/api/users/balance',
        '/user/profile',
        '/api/user/profile',
      ];

      for (final endpoint in authTestEndpoints) {
        try {
          final url = '${ApiEndpoints.baseUrl}$endpoint';
          final response = await http
              .get(
                Uri.parse(url),
                headers: _getHeaders(token: token),
              )
              .timeout(Duration(seconds: 10));

          results['auth_$endpoint'] = {
            'status': response.statusCode,
            'bodyPreview': response.body.length > 100
                ? response.body.substring(0, 100)
                : response.body,
          };

          print('🔐 Auth test $endpoint -> ${response.statusCode}');

          if (response.statusCode == 200) {
            print('✅ Authentication working with $endpoint');
            break;
          }
        } catch (e) {
          print('❌ Auth test $endpoint failed: $e');
        }
      }
    } catch (e) {
      print('❌ Authentication test failed: $e');
    }

    // 4. Test with different HTTP methods
    try {
      print('\n4️⃣ Testing different HTTP methods...');
      final transactionUrl = '${ApiEndpoints.baseUrl}/api/transactions';

      // OPTIONS request (check CORS)
      try {
        final optionsResponse = await http.Client()
            .send(http.Request('OPTIONS', Uri.parse(transactionUrl))
              ..headers.addAll(_getHeaders(token: token)))
            .timeout(Duration(seconds: 10));

        results['OPTIONS_api_transactions'] = {
          'status': optionsResponse.statusCode,
          'headers': optionsResponse.headers,
        };
        print('🔧 OPTIONS /api/transactions -> ${optionsResponse.statusCode}');
      } catch (e) {
        print('❌ OPTIONS test failed: $e');
      }

      // HEAD request
      try {
        final headResponse = await http
            .head(
              Uri.parse(transactionUrl),
              headers: _getHeaders(token: token),
            )
            .timeout(Duration(seconds: 10));

        results['HEAD_api_transactions'] = {
          'status': headResponse.statusCode,
          'headers': headResponse.headers,
        };
        print('🔧 HEAD /api/transactions -> ${headResponse.statusCode}');
      } catch (e) {
        print('❌ HEAD test failed: $e');
      }
    } catch (e) {
      print('❌ HTTP methods test failed: $e');
    }

    print('\n🏁 Server test completed');
    return results;
  }

  // Auth endpoints (unchanged)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/users/register';
      print('🔗 POST: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      print('❌ Register Error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/users/login';
      print('🔗 POST: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      print('❌ Login Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Wallet endpoints
  static Future<Map<String, dynamic>> getBalance(String token) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/users/balance';
      print('🔗 GET: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token: token),
      );

      return _parseResponse(response);
    } catch (e) {
      print('❌ Get Balance Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Smart transactions endpoint with multiple fallbacks
  static Future<Map<String, dynamic>> getTransactions({
    required String token,
    int page = 1,
    int limit = 50,
    String? type,
  }) async {
    // Try different endpoint variations
    final endpointVariations = [
      '/api/transactions',
      '/transactions',
      '/api/transaction',
      '/transaction',
    ];

    Map<String, dynamic>? lastError;

    for (final endpoint in endpointVariations) {
      try {
        String url = '${ApiEndpoints.baseUrl}$endpoint?page=$page&limit=$limit';

        if (type != null && type.isNotEmpty) {
          url += '&type=$type';
        }

        print('🔗 Trying GET: $url');

        final response = await http
            .get(
              Uri.parse(url),
              headers: _getHeaders(token: token),
            )
            .timeout(Duration(seconds: 15));

        print('📊 Response Status: ${response.statusCode}');

        // If successful response
        if (response.statusCode == 200) {
          print('✅ Success with endpoint: $endpoint');
          return _parseResponse(response);
        }

        // If authentication error
        if (response.statusCode == 401) {
          return {
            'error': 'Authentication failed. Please login again.',
            'statusCode': 401,
          };
        }

        // If forbidden
        if (response.statusCode == 403) {
          return {
            'error': 'Access denied. Please check your permissions.',
            'statusCode': 403,
          };
        }

        // If not found, try next endpoint
        if (response.statusCode == 404) {
          print('❌ $endpoint not found (404), trying next...');
          lastError = {
            'error': 'Endpoint $endpoint not found',
            'statusCode': 404,
            'endpoint': endpoint,
          };
          continue;
        }

        // Other error codes
        lastError = {
          'error': 'Server error: ${response.statusCode}',
          'statusCode': response.statusCode,
          'endpoint': endpoint,
          'body': response.body,
        };
      } catch (e) {
        print('❌ Error with $endpoint: $e');
        lastError = {
          'error': 'Network error: ${e.toString()}',
          'endpoint': endpoint,
          'details': e.runtimeType.toString(),
        };
        continue;
      }
    }

    // If all endpoints failed, return the last error
    return lastError ??
        {
          'error': 'All transaction endpoints failed',
          'statusCode': 404,
        };
  }

  // Other methods remain the same...
  static Future<Map<String, dynamic>> topUp({
    required String token,
    required int amount,
    required String paymentMethod,
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/wallet/topup';
      print('🔗 POST: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'amount': amount,
          'paymentMethod': paymentMethod,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      print('❌ Top Up Error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> transfer({
    required String token,
    required String recipientPhoneNumber,
    required int amount,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/wallet/transfer'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'recipientPhoneNumber': recipientPhoneNumber,
          'amount': amount,
          'description': description,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> withdraw({
    required String token,
    required int amount,
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/wallet/withdraw';
      print('🔗 POST: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'amount': amount,
          'bankCode': bankCode,
          'accountNumber': accountNumber,
          'accountHolderName': accountHolderName,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      print('❌ Withdraw Error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus({
    required String token,
    required String referenceId,
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/wallet/topup/status/$referenceId';
      print('🔗 GET: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token: token),
      );

      return _parseResponse(response);
    } catch (e) {
      print('❌ Check Payment Status Error: $e');
      throw Exception('Network error: $e');
    }
  }
}
