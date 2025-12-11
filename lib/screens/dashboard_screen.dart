import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/retail_service.dart';
import 'product_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RetailService _service = RetailService();

  // Variabel untuk menampung data dari API
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Fungsi ambil data dari Laravel
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

  @override
  Widget build(BuildContext context) {
    // Formatter Duit (Biar jadi $1,000.00 atau Rp...)
    final currency = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Background abu modern
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigasi ke Halaman Produk
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductListScreen()),
          ).then((_) => _fetchData()); // Refresh dashboard pas balik
        },
        label: Text(
          "Transaksi Baru",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      appBar: AppBar(
        title: Text(
          "Retail Dashboard",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _fetchData, // Tombol refresh manual
          ),
        ],
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
                    // 1. KARTU TOTAL SALES (Gede di Atas)
                    _buildTotalCard(currency),

                    const SizedBox(height: 24),

                    // 2. GRAFIK TREN PENJUALAN (Line Chart)
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: LineChart(_buildLineChartData()),
                    ),

                    const SizedBox(height: 24),

                    // 3. PIE CHART KATEGORI & TOP PRODUK (Grid)
                    // Kalau di HP layar kecil, kita tumpuk ke bawah
                    Text(
                      "Analisis Produk",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kategori (Pie Chart)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                          _buildPieLegend(), // Keterangan warna
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 4. TOP 5 PRODUK (List)
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
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

  // 1. Logic Data Line Chart
  LineChartData _buildLineChartData() {
    List<dynamic> trends = _data!['monthly_sales_trend'];
    List<FlSpot> spots = [];

    // Ubah data JSON jadi titik koordinat (X, Y)
    for (int i = 0; i < trends.length; i++) {
      double yVal = double.parse(trends[i]['total'].toString());
      spots.add(FlSpot(i.toDouble(), yVal));
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 22,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true, // Garis melengkung
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

  // 2. Logic Data Pie Chart
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

  // 3. Legend untuk Pie Chart (Keterangan Warna)
  Widget _buildPieLegend() {
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
            Text(cats[i]['category'], style: GoogleFonts.poppins(fontSize: 12)),
          ],
        );
      }),
    );
  }
}
