import 'package:dio/dio.dart';

class RetailService {
  // ✅ PERBAIKAN 1: Tambahkan '/retail' di ujungnya
  // Karena di Laravel kamu sudah grouping semua ke Route::prefix('retail')
  final String baseUrl = "http://127.0.0.1:8000/api/retail";

  final Dio _dio = Dio();

  // Helper untuk Header (Supaya Laravel tau kita minta JSON, bukan HTML)
  Options get _jsonHeaders => Options(
    headers: {"Accept": "application/json", "Content-Type": "application/json"},
  );

  // 1. LOGIN
  // URL: http://127.0.0.1:8000/api/retail/login
  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/login',
        data: {'email': email, 'password': password},
        options: _jsonHeaders, // Penting!
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Login Error: $e"); // Debug
      throw Exception('Login Gagal: Cek email/password');
    }
  }

  // 2. REGISTER
  // URL: http://127.0.0.1:8000/api/retail/register
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
        options: _jsonHeaders, // Penting!
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response != null) {
        print("Error Laravel: ${e.response?.data}");
        throw Exception(
          "Gagal: ${e.response?.data['message'] ?? e.response?.data.toString()}",
        );
      } else {
        throw Exception("Koneksi Gagal: ${e.message}");
      }
    } catch (e) {
      throw Exception('Error tak terduga: $e');
    }
  }

  // 3. DASHBOARD
  // URL: http://127.0.0.1:8000/api/retail/dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _dio.get(
        '$baseUrl/dashboard',
        options: _jsonHeaders,
      );
      return response.data['data'];
    } catch (e) {
      throw Exception('Gagal koneksi ke server: $e');
    }
  }

  // 4. GET PRODUCTS (List Produk)
  // URL: http://127.0.0.1:8000/api/retail/products
  Future<Map<String, dynamic>> getProducts({
    String query = '',
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/products',
        queryParameters: {'search': query, 'page': page},
        options: _jsonHeaders,
      );
      return response.data;
    } catch (e) {
      throw Exception('Gagal mengambil produk: $e');
    }
  }

  // 5. TRANSAKSI
  // URL: http://127.0.0.1:8000/api/retail/transaction
  Future<bool> createTransaction(
    int productId,
    int qty,
    double totalSales,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/transaction',
        // ✅ PERBAIKAN 2: Pastikan key sesuai Controller Laravel
        // Biasanya Laravel pakai 'qty' dan 'total_price'.
        // Saya sesuaikan dengan kodemu yang lama biar aman.
        data: {
          'product_id': productId,
          'qty': qty, // Jangan 'quantity' kalau di DB kolomnya 'qty'
          'total_price':
              totalSales, // Jangan 'sales' kalau di DB kolomnya 'total_price'
        },
        options: _jsonHeaders,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Transaksi Error: $e");
      return false;
    }
  }
}
