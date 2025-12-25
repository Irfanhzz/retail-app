import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    final data = await NotificationService().getHistory();
    setState(() {
      _notifications = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Riwayat Notifikasi",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: "Hapus Semua",
              onPressed: () async {
                await NotificationService().clearHistory();
                _loadNotifications();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada notifikasi",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];

                final DateTime date = DateTime.parse(notif['time']);
                final String timeStr = DateFormat('dd MMM, HH:mm').format(date);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      notif['title'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif['body'], style: GoogleFonts.poppins()),
                        Text(
                          "Total: \$${notif['price']}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      timeStr,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
