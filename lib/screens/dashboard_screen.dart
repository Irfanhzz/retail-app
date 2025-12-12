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

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductListScreen()),
          ).then((_) => _fetchData());
        },
        label: Text(
          "Transaksi Baru",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Retail Dashboard",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _fetchData,
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTotalCard(currency),
                        const SizedBox(height: 26),

                        // --- TITLE ---
                        _sectionTitle("Tren Penjualan (6 Bulan)"),

                        const SizedBox(height: 12),
                        _buildChartCard(
                          child: SizedBox(
                            height: 220,
                            child: LineChart(_buildLineChartData()),
                          ),
                        ),

                        const SizedBox(height: 28),
                        _sectionTitle("Analisis Produk"),
                        const SizedBox(height: 12),

                        // Pie Chart Section
                        _buildChartCard(
                          child: Column(
                            children: [
                              Text(
                                "Penjualan per Kategori",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 150,
                                child: PieChart(_buildPieChartData()),
                              ),
                              const SizedBox(height: 16),
                              _buildPieLegend(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),
                        _sectionTitle("Top 5 Produk Terlaris"),
                        const SizedBox(height: 14),

                        ...(_data!['top_products'] as List).map((prod) {
                          return _buildProductCard(prod);
                        }),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  // --- SECTION TITLE ---
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // --- CARD WRAPPER ---
  Widget _buildChartCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // --- TOTAL SALES CARD (IMPROVED UI) ---
  Widget _buildTotalCard(NumberFormat currency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.35),
            blurRadius: 14,
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
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const Icon(Icons.monetization_on, color: Colors.white, size: 30),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currency.format(_data!['total_sales']),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Semua waktu",
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- PRODUCT CARD ---
  Widget _buildProductCard(dynamic prod) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
          ),
          const SizedBox(width: 14),
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Terjual: \$${prod['total_sales']}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.emoji_events, color: Colors.amber),
        ],
      ),
    );
  }

  // --- LINE CHART LOGIC ---
  LineChartData _buildLineChartData() {
    List<dynamic> trends = _data!['monthly_sales_trend'];

    List<FlSpot> spots = [];
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
          sideTitles: SideTitles(showTitles: true, interval: 1),
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
            color: Colors.blueAccent.withOpacity(0.18),
          ),
        ),
      ],
    );
  }

  // --- PIE CHART LOGIC ---
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
          radius: 52,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }),
    );
  }

  // --- PIE LEGEND ---
  Widget _buildPieLegend() {
    List<dynamic> cats = _data!['sales_by_category'];
    List<Color> colors = [
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];

    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: List.generate(cats.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              cats[i]['category'],
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        );
      }),
    );
  }
}
