import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // Asumsikan ApiEndpoints.baseUrl ada di sini

// Helper untuk logging dan parsing respons
void _logRequest(String method, String url,
    {dynamic body, Map<String, String>? headers}) {
  print('🚀 [API Request] $method: $url');
  if (headers != null) print('📋 Headers: $headers');
  if (body != null) print('📦 Body: ${jsonEncode(body)}');
}

void _logResponse(http.Response response) {
  print('✅ [API Response] Status: ${response.statusCode}');
  print('📋 Headers: ${response.headers}');
  print('📦 Body: ${response.body}');
}

void _logError(String method, String url, dynamic error, dynamic stackTrace) {
  print('❌ [API Error] $method: $url');
  print('💣 Error: $error');
  print('📄 StackTrace: $stackTrace');
}

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

  static Map<String, dynamic> _parseResponse(http.Response response) {
    _logResponse(response);
    if (response.body.isEmpty) {
      return {
        'error': 'Empty response from server',
        'statusCode': response.statusCode
      };
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing JSON: $e');
      return {
        'error': 'Invalid JSON response',
        'details': response.body,
        'statusCode': response.statusCode
      };
    }
  }

  // Fungsi fullServerTest ditambahkan kembali di sini
  static Future<Map<String, dynamic>> fullServerTest(String token) async {
    final results = <String, dynamic>{};

    print('🔍 Starting comprehensive server test...');
    print('🌐 Base URL: ${ApiEndpoints.baseUrl}');
    print('🔑 Token provided: ${token.isNotEmpty}');

    // 1. Test base server connectivity
    try {
      print('\n1️⃣ Testing base server...');
      final baseResponse = await http.get(
        Uri.parse(ApiEndpoints.baseUrl), // Menggunakan ApiEndpoints.baseUrl
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
    // Pastikan endpoint ini sesuai dengan struktur API Anda (misal, dengan prefix /api/)
    final endpointVariations = [
      '/api/transactions', // Contoh dengan prefix /api/
      // '/transactions', // Mungkin tidak perlu jika semua pakai /api/
      // '/api/transaction', // Sesuaikan jika ada endpoint tunggal
      // '/transaction',
    ];

    for (final endpoint in endpointVariations) {
      try {
        print('\n2️⃣ Testing endpoint: $endpoint');
        final url = '${ApiEndpoints.baseUrl}$endpoint';

        final response = await http
            .get(
              Uri.parse(url),
              headers: _getHeaders(token: token), // Menggunakan _getHeaders
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
      // Pastikan endpoint ini adalah endpoint yang memerlukan autentikasi dan valid
      final authTestEndpoints = [
        '/api/users/balance', // Contoh endpoint yang memerlukan auth
        // '/api/user/profile', // Jika ada endpoint profile
      ];

      for (final endpoint in authTestEndpoints) {
        try {
          final url = '${ApiEndpoints.baseUrl}$endpoint';
          final response = await http
              .get(
                Uri.parse(url),
                headers: _getHeaders(token: token), // Menggunakan _getHeaders
              )
              .timeout(Duration(seconds: 10));

          results['auth_$endpoint'] = {
            'status': response.statusCode,
            'bodyPreview': response.body.length > 100
                ? response.body.substring(0, 100) + '...'
                : response.body,
          };

          print('🔐 Auth test $endpoint -> ${response.statusCode}');

          if (response.statusCode == 200) {
            print('✅ Authentication working with $endpoint');
            break; // Hentikan jika satu endpoint auth berhasil
          }
        } catch (e) {
          print('❌ Auth test $endpoint failed: $e');
          // Jangan break di sini, coba endpoint auth lain jika ada
        }
      }
    } catch (e) {
      // Catch error umum untuk blok test authentication
      print('❌ Authentication test block failed: $e');
    }

    // 4. Test with different HTTP methods (OPTIONS, HEAD)
    try {
      print('\n4️⃣ Testing different HTTP methods...');
      final transactionUrl =
          '${ApiEndpoints.baseUrl}/api/transactions'; // Contoh endpoint

      // OPTIONS request (check CORS)
      try {
        print('🔧 Testing OPTIONS: $transactionUrl');
        final request = http.Request('OPTIONS', Uri.parse(transactionUrl));
        request.headers
            .addAll(_getHeaders(token: token)); // Menggunakan _getHeaders

        final streamedResponse =
            await http.Client().send(request).timeout(Duration(seconds: 10));

        results['OPTIONS_api_transactions'] = {
          'status': streamedResponse.statusCode,
          'headers': streamedResponse.headers,
        };
        print('🔧 OPTIONS $transactionUrl -> ${streamedResponse.statusCode}');
      } catch (e) {
        print('❌ OPTIONS test failed for $transactionUrl: $e');
        results['OPTIONS_api_transactions'] = {
          'error': e.toString(),
          'accessible': false
        };
      }

      // HEAD request
      try {
        print('🔧 Testing HEAD: $transactionUrl');
        final headResponse = await http
            .head(
              Uri.parse(transactionUrl),
              headers: _getHeaders(token: token), // Menggunakan _getHeaders
            )
            .timeout(Duration(seconds: 10));

        results['HEAD_api_transactions'] = {
          'status': headResponse.statusCode,
          'headers': headResponse.headers,
        };
        print('🔧 HEAD $transactionUrl -> ${headResponse.statusCode}');
      } catch (e) {
        print('❌ HEAD test failed for $transactionUrl: $e');
        results['HEAD_api_transactions'] = {
          'error': e.toString(),
          'accessible': false
        };
      }
    } catch (e) {
      // Catch error umum untuk blok test HTTP methods
      print('❌ HTTP methods test block failed: $e');
    }

    print('\n🏁 Server test completed');
    return results;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/users/register';
    _logRequest('POST', url, body: {
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
    });
    try {
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
    } catch (e, s) {
      _logError('POST', url, e, s);
      return {'error': 'Network error during registration: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/users/login';
    _logRequest('POST', url, body: {'email': email, 'password': password});
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('POST', url, e, s);
      return {'error': 'Network error during login: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    String type = "VERIFICATION",
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/users/verify-otp';
    _logRequest('POST', url, body: {'email': email, 'otp': otp});
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('POST', url, e, s);
      return {
        'error': 'Network error during OTP verification: ${e.toString()}'
      };
    }
  }

  static Future<Map<String, dynamic>> resendOtp({
    required String email,
    required String type,
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/users/resend-otp';
    _logRequest('POST', url, body: {'email': email, 'type': type});
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'type': type,
        }),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('POST', url, e, s);
      return {'error': 'Network error during resend OTP: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/users/forgot-password';
    _logRequest('POST', url, body: {'email': email});
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('POST', url, e, s);
      return {'error': 'Network error during forgot password: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/users/reset-password';
    _logRequest('POST', url,
        body: {'email': email, 'otp': otp, 'newPassword': '***'});
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('POST', url, e, s);
      return {'error': 'Network error during reset password: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/users/change-password';
    _logRequest('POST', url,
        body: {'oldPassword': '***', 'newPassword': '***'},
        headers: _getHeaders(token: token));
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('POST', url, e, s);
      return {'error': 'Network error during change password: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getBalance(String token) async {
    final url = '${ApiEndpoints.baseUrl}/api/users/balance';
    _logRequest('GET', url, headers: _getHeaders(token: token));
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token: token),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('GET', url, e, s);
      return {'error': 'Network error fetching balance: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getTransactions({
    required String token,
    int page = 1,
    int limit = 10,
    String? type,
  }) async {
    String url =
        '${ApiEndpoints.baseUrl}/api/transactions?page=$page&limit=$limit';
    if (type != null && type.isNotEmpty) {
      url += '&type=$type';
    }
    _logRequest('GET', url, headers: _getHeaders(token: token));
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token: token),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('GET', url, e, s);
      return {'error': 'Network error fetching transactions: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> topUp({
    required String token,
    required int amount,
    required String paymentMethod,
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/wallet/topup';
    _logRequest('POST', url,
        body: {'amount': amount, 'paymentMethod': paymentMethod},
        headers: _getHeaders(token: token));
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'amount': amount,
          'paymentMethod': paymentMethod,
        }),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('POST', url, e, s);
      return {'error': 'Network error during top up: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> transfer({
    required String token,
    required String recipientPhoneNumber,
    required int amount,
    String? description,
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/wallet/transfer';
    _logRequest('POST', url,
        body: {
          'recipientPhoneNumber': recipientPhoneNumber,
          'amount': amount,
          'description': description,
        },
        headers: _getHeaders(token: token));
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'recipientPhoneNumber': recipientPhoneNumber,
          'amount': amount,
          'description': description,
        }),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('POST', url, e, s);
      return {'error': 'Network error during transfer: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> withdraw({
    required String token,
    required int amount,
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/wallet/withdraw';
    _logRequest('POST', url,
        body: {
          'amount': amount,
          'bankCode': bankCode,
          'accountNumber': accountNumber,
          'accountHolderName': accountHolderName,
        },
        headers: _getHeaders(token: token));
    try {
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
    } catch (e, s) {
      _logError('POST', url, e, s);
      return {'error': 'Network error during withdrawal: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus({
    required String token,
    required String referenceId,
  }) async {
    final url = '${ApiEndpoints.baseUrl}/api/wallet/topup/status/$referenceId';
    _logRequest('GET', url, headers: _getHeaders(token: token));
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token: token),
      );
      return _parseResponse(response);
    } catch (e, s) {
      _logError('GET', url, e, s);
      return {
        'error': 'Network error checking payment status: ${e.toString()}'
      };
    }
  }
}
