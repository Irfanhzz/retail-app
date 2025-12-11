import 'package:dio/dio.dart';

class RetailService {
  // ⚠️ PENTING: Setting IP Address Backend
  // Gunakan '10.0.2.2' jika pakai Android Emulator.
  // Gunakan IP Laptop (misal '192.168.1.x') jika pakai HP Fisik via kabel data.
  // JANGAN pakai 'localhost' karena HP tidak kenal localhost laptop.
  final String baseUrl = "http://127.0.0.1:8000/api/retail";

  final Dio _dio = Dio();

  // 1. Ambil Data Dashboard (Grafik & Ringkasan)
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _dio.get('$baseUrl/dashboard');
      // Mengambil isi 'data' dari JSON response Laravel
      return response.data['data'];
    } catch (e) {
      throw Exception('Gagal koneksi ke server: $e');
    }
  }

  // 2. Ambil Daftar Produk (Bisa Search)
  Future<List<dynamic>> getProducts({String query = ''}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/products',
        queryParameters: {'search': query},
      );
      // Data produk ada di dalam 'data' karena pakai pagination Laravel
      return response.data['data'];
    } catch (e) {
      throw Exception('Gagal mengambil produk: $e');
    }
  }

  // 3. Kirim Transaksi Baru (Jual Barang)
  Future<bool> createTransaction(
    int productId,
    int qty,
    double totalSales,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/transaction',
        data: {'product_id': productId, 'quantity': qty, 'sales': totalSales},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
