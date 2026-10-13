import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _tokenKey = 'auth_bearer_token';
  static const String _userKey = 'auth_user_data';
  static const String _baseUrlKey = 'custom_base_url';

  String? _token;
  UserModel? _currentUser;
  String _baseUrl = ApiConfig.defaultBaseUrl;

  String get baseUrl => _baseUrl;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoggedIn => isAuthenticated;

  // Initialize service on startup
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _baseUrl = prefs.getString(_baseUrlKey) ?? ApiConfig.defaultBaseUrl;

    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        debugPrint('Error decoding cached user: $e');
      }
    }
  }

  // Update base URL (useful when switching between emulator, real device, or local IP)
  Future<void> setBaseUrl(String newUrl) async {
    String cleanUrl = newUrl.trim();
    // Fix accidental typo like 127.0.0.1.8000 -> 127.0.0.1:8000
    cleanUrl = cleanUrl.replaceAll('.8000', ':8000');
    
    // Add http:// scheme if missing
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }
    
    // Strip trailing slash
    while (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    
    // Ensure it ends with /api
    if (!cleanUrl.endsWith('/api')) {
      cleanUrl = '$cleanUrl/api';
    }

    _baseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  // Ping/Test backend connection with latency measurement
  Future<Map<String, dynamic>> testConnection([String? targetUrl]) async {
    final urlToTest = targetUrl != null && targetUrl.trim().isNotEmpty
        ? targetUrl.trim()
        : _baseUrl;
    try {
      final startTime = DateTime.now();
      final uri = Uri.parse('$urlToTest${ApiConfig.productsEndpoint}?per_page=1');
      final response = await http.get(
        uri,
        headers: _getHeaders(withAuth: false),
      ).timeout(const Duration(seconds: 4));
      final latencyMs = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode >= 200 && response.statusCode < 500) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'latencyMs': latencyMs,
          'message': 'Connected to Laravel server (${latencyMs}ms)',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Server responded with error status ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot reach server at $urlToTest. Please ensure backend is running with --host=0.0.0.0',
        'error': e.toString(),
      };
    }
  }

  // HTTP Header helper with Bearer Token
  Map<String, String> _getHeaders({bool withAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ================= AUTH METHODS =================

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final uri = Uri.parse('$_baseUrl${ApiConfig.loginEndpoint}');
      final response = await http.post(
        uri,
        headers: _getHeaders(withAuth: false),
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'device_name': 'flutter_mobile_app',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['data']['token'];
        _currentUser = UserModel.fromJson(data['data']['user']);

        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

        return {'success': true, 'user': _currentUser};
      } else {
        final errorMsg = data['message'] ?? 'Authentication failed.';
        return {'success': false, 'message': errorMsg, 'errors': data['errors']};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot reach server at $_baseUrl. Please ensure Laravel backend is running and URL is reachable.',
        'error': e.toString(),
      };
    }
  }

  Future<UserModel?> getUserProfile() async {
    if (!isAuthenticated) return null;
    try {
      final uri = Uri.parse('$_baseUrl${ApiConfig.userEndpoint}');
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _currentUser = UserModel.fromJson(data['data']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
          return _currentUser;
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    return _currentUser;
  }

  Future<bool> logout() async {
    try {
      if (isAuthenticated) {
        final uri = Uri.parse('$_baseUrl${ApiConfig.logoutEndpoint}');
        await http.post(uri, headers: _getHeaders());
      }
    } catch (e) {
      debugPrint('Logout request error: $e');
    } finally {
      _token = null;
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    }
    return true;
  }

  // ================= PRODUCT METHODS =================

  Future<Map<String, dynamic>> getProducts({
    String? search,
    String? status,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseUrl${ApiConfig.productsEndpoint}').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        final products = items.map((item) => ProductModel.fromJson(item)).toList();

        return {
          'success': true,
          'products': products,
          'meta': data['meta'] ?? {},
          'stats': data['stats'] ?? {},
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired (401). Please sign out in Settings and log in again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load products (${response.statusCode}) from $_baseUrl',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot reach server at $_baseUrl. Check Settings > API Server URL.',
      };
    }
  }

  Future<Map<String, dynamic>> getProduct(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl${ApiConfig.productsEndpoint}/$id');
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'product': ProductModel.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': 'Product not found.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    try {
      final uri = Uri.parse('$_baseUrl${ApiConfig.productsEndpoint}');
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(productData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'product': ProductModel.fromJson(data['data']),
          'message': data['message'] ?? 'Product created successfully.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create product.',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> productData) async {
    try {
      final uri = Uri.parse('$_baseUrl${ApiConfig.productsEndpoint}/$id');
      final response = await http.put(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(productData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'product': ProductModel.fromJson(data['data']),
          'message': data['message'] ?? 'Product updated successfully.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update product.',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteProduct(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl${ApiConfig.productsEndpoint}/$id');
      final response = await http.delete(uri, headers: _getHeaders());

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Product moved to Recycle Bin.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete product.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ================= RECYCLE BIN METHODS =================

  Future<Map<String, dynamic>> getTrashedProducts({String? search, int page = 1}) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$_baseUrl${ApiConfig.recycleBinEndpoint}').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(uri, headers: _getHeaders());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> rawList = data['data'] ?? [];
        final products = rawList.map((item) => ProductModel.fromJson(item)).toList();
        return {
          'success': true,
          'products': products,
          'stats': data['stats'] ?? {},
          'meta': data['meta'] ?? {},
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load trashed products.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> restoreProduct(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl${ApiConfig.restoreEndpoint(id)}');
      final response = await http.post(uri, headers: _getHeaders());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Product restored successfully.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to restore product.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> forceDeleteProduct(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl${ApiConfig.forceDeleteEndpoint(id)}');
      final response = await http.delete(uri, headers: _getHeaders());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Product permanently deleted.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete product permanently.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> restoreAllProducts() async {
    try {
      final uri = Uri.parse('$_baseUrl${ApiConfig.restoreAllEndpoint}');
      final response = await http.post(uri, headers: _getHeaders());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'All products restored successfully.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to restore all products.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> emptyTrash() async {
    try {
      final uri = Uri.parse('$_baseUrl${ApiConfig.emptyTrashEndpoint}');
      final response = await http.delete(uri, headers: _getHeaders());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Recycle bin emptied.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to empty recycle bin.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
