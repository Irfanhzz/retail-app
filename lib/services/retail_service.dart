import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RetailService {
  final String baseUrl = "https://tacky-almost-arie.ngrok-free.dev/api/retail";

  final Dio _dio = Dio();

  RetailService() {
    _dio.options.validateStatus = (status) => status! < 500;
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  // 1. LOGIN
  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        if (response.data['token'] != null) {
          await prefs.setString('token', response.data['token']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 2. REGISTER
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 3. DASHBOARD
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _dio.get('$baseUrl/dashboard');
      final rawData = response.data['data'];

      return {
        'total_sales': _safeDouble(rawData['total_sales']),

        'sales_by_category': (rawData['sales_by_category'] as List).map((item) {
          return {
            'category': item['category'],
            'total': _safeDouble(item['total']),
          };
        }).toList(),

        'top_products': (rawData['top_products'] as List).map((item) {
          return {
            'product_name': item['product_name'],
            'total_sales': _safeDouble(item['total_sales']),
          };
        }).toList(),

        'monthly_sales_trend': (rawData['monthly_sales_trend'] as List).map((
          item,
        ) {
          return {
            'month_name': item['month_name'],
            'year': item['year'],
            'total': _safeDouble(item['total']),
          };
        }).toList(),
      };
    } catch (e) {
      throw Exception('Gagal ambil dashboard');
    }
  }

  // 4. GET PRODUCTS
  Future<Map<String, dynamic>> getProducts({
    String query = '',
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/products',
        queryParameters: {'search': query, 'page': page},
      );
      return response.data;
    } catch (e) {
      throw Exception('Gagal ambil produk');
    }
  }

  // 5. TRANSAKSI
  Future<bool> createTransaction(int productId, int qty, double total) async {
    try {
      final Map<String, dynamic> data = {
        'product_id': productId,
        'quantity': qty,
        'sales': total,
      };

      final response = await _dio.post('$baseUrl/transaction', data: data);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Helper: Convert Numeric String to Double safely
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }
}
