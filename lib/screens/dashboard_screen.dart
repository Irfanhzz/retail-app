import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Import SharedPreferences
import '../services/retail_service.dart';
import '../theme/theme_provider.dart';
import 'product_list_screen.dart';
import 'login_screen.dart'; // 2. Import Login Screen

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

  // --- 3. FUNGSI LOGOUT ---
  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus sesi login

    if (!mounted) return;

    // Pindah ke Login & Hapus semua history halaman sebelumnya
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- 4. DIALOG KONFIRMASI LOGOUT ---
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
              Navigator.pop(context); // Tutup dialog dulu
              _logout(context); // Baru logout
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
          // SAKLAR TEMA
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

          // TOMBOL REFRESH
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            tooltip: "Refresh Data",
            onPressed: _fetchData,
          ),

          // --- 5. TOMBOL LOGOUT BARU ---
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Logout",
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 8), // Sedikit jarak di kanan
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
                    // 1. KARTU TOTAL SALES
                    _buildTotalCard(currency),

                    const SizedBox(height: 24),

                    // 2. GRAFIK TREN
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

                    // 3. PIE CHART
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

                    // 4. TOP PRODUCTS
                    Text(
                      "Top 5 Produk Terlaris",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_data!['top_products'] as List).map((prod) {
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
                                    "Terjual: \$${prod['total_sales']}",
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

  // --- WIDGET HELPER ---

  Widget _buildTotalCard(NumberFormat currency) {
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
            currency.format(_data!['total_sales']),
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

  // --- CHART LOGIC ---

  LineChartData _buildLineChartData(Color? textColor) {
    List<dynamic> trends = _data!['monthly_sales_trend'];
    List<FlSpot> spots = [];

    for (int i = 0; i < trends.length; i++) {
      double yVal = double.parse(trends[i]['total'].toString());
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

    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      sections: List.generate(cats.length, (i) {
        final cat = cats[i];
        final double value = double.parse(cat['total'].toString());
        return PieChartSectionData(
          color: colors[i % colors.length],
          value: value,
          title: '${(value / _data!['total_sales'] * 100).toStringAsFixed(0)}%',
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
