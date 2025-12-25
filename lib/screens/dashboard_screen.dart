import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/retail_service.dart';
import '../theme/theme_provider.dart';
import 'product_list_screen.dart';
import 'login_screen.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RetailService _service = RetailService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.getDashboardData();
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Helper: Konversi data API ke Double
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // --- LOGOUT LOGIC ---

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Konfirmasi Logout",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final cardColor = Theme.of(context).cardTheme.color;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Retail Dashboard",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Theme Switcher
          Consumer<ThemeProvider>(
            builder: (context, theme, child) {
              return Row(
                children: [
                  Icon(
                    theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.isDarkMode ? Colors.yellow : Colors.orange,
                    size: 20,
                  ),
                  Switch(
                    value: theme.isDarkMode,
                    onChanged: (value) => theme.toggleTheme(value),
                    activeColor: Colors.blueAccent,
                  ),
                ],
              );
            },
          ),

          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            tooltip: "Refresh Data",
            onPressed: _fetchData,
          ),

          // Notification Button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),

          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Logout",
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductListScreen()),
          ).then((_) => _fetchData());
        },
        label: Text(
          "Transaksi Baru",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text("Error: $_errorMessage"))
          : RefreshIndicator(
              onRefresh: () async => _fetchData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kartu Total Sales
                    _buildTotalCard(currency),

                    const SizedBox(height: 24),

                    // Line Chart
                    Text(
                      "Tren Penjualan (6 Bulan)",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: LineChart(_buildLineChartData(textColor)),
                    ),

                    const SizedBox(height: 24),

                    // Pie Chart
                    Text(
                      "Analisis Produk",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Penjualan per Kategori",
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 150,
                            child: PieChart(_buildPieChartData()),
                          ),
                          const SizedBox(height: 10),
                          _buildPieLegend(textColor),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // List Top Products
                    Text(
                      "Top 5 Produk Terlaris",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_data!['top_products'] as List).map((prod) {
                      double sales = _parseToDouble(prod['total_sales']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prod['product_name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Terjual: \$${sales.toStringAsFixed(2)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.emoji_events, color: Colors.amber),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildTotalCard(NumberFormat currency) {
    double total = _parseToDouble(_data!['total_sales']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Colors.lightBlue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Omzet",
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const Icon(Icons.monetization_on, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(total),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Semua waktu",
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- CHART DATA GENERATORS ---

  LineChartData _buildLineChartData(Color? textColor) {
    List<dynamic> trends = _data!['monthly_sales_trend'];
    List<FlSpot> spots = [];

    for (int i = 0; i < trends.length; i++) {
      double yVal = _parseToDouble(trends[i]['total']);
      spots.add(FlSpot(i.toDouble(), yVal));
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < trends.length) {
                return Text(
                  trends[value.toInt()]['month_name'].toString().substring(
                    0,
                    3,
                  ),
                  style: TextStyle(
                    color: textColor ?? Colors.grey,
                    fontSize: 10,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blueAccent,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blueAccent.withOpacity(0.15),
          ),
        ),
      ],
    );
  }

  PieChartData _buildPieChartData() {
    List<dynamic> cats = _data!['sales_by_category'];
    List<Color> colors = [
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];

    double totalAll = 0;
    for (var cat in cats) {
      totalAll += _parseToDouble(cat['total']);
    }

    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      sections: List.generate(cats.length, (i) {
        final cat = cats[i];
        final double value = _parseToDouble(cat['total']);

        String percent = totalAll > 0
            ? '${(value / totalAll * 100).toStringAsFixed(0)}%'
            : '0%';

        return PieChartSectionData(
          color: colors[i % colors.length],
          value: value,
          title: percent,
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }),
    );
  }

  Widget _buildPieLegend(Color? textColor) {
    List<dynamic> cats = _data!['sales_by_category'];
    List<Color> colors = [
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];

    return Wrap(
      spacing: 16,
      children: List.generate(cats.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: colors[i % colors.length]),
            const SizedBox(width: 4),
            Text(
              cats[i]['category'],
              style: GoogleFonts.poppins(fontSize: 12, color: textColor),
            ),
          ],
        );
      }),
    );
  }
}
