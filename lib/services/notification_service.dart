import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _historyKey = 'notification_history';

  Future<void> init() async {
    // 1. Setup Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // 2. Initialize Plugin
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 3. Minta Izin Notifikasi (Wajib untuk Android 13+)
    final platform = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (platform != null) {
      await platform.requestNotificationsPermission();
    }
  }

  Future<void> showTransactionSuccess(
    String productName,
    int qty,
    String price,
  ) async {
    // 1. Munculkan Notifikasi Pop-up
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'transaction_channel',
          'Transaksi',
          channelDescription: 'Notifikasi transaksi berhasil',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // ID Unik berdasarkan waktu
      'Transaksi Berhasil!',
      'Terjual $qty x $productName',
      platformChannelSpecifics,
    );

    // 2. Simpan ke Riwayat (Storage HP)
    await _addToHistory(productName, qty, price);
  }

  Future<void> _addToHistory(String productName, int qty, String price) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ambil data lama
      List<String> history = prefs.getStringList(_historyKey) ?? [];

      // Buat data baru
      Map<String, dynamic> newNotif = {
        'title': 'Transaksi Berhasil',
        'body': '$qty x $productName',
        'price': price,
        'time': DateTime.now().toString(),
      };

      // Masukkan ke paling atas (index 0)
      history.insert(0, jsonEncode(newNotif));

      // Simpan Balik
      await prefs.setStringList(_historyKey, history);
    } catch (e) {
      // Silent error handling untuk production
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_historyKey) ?? [];

      return history.map((item) {
        return jsonDecode(item) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
