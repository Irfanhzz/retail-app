import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/retail_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final RetailService _service = RetailService();

  // Fungsi Transaksi
  void _showTransactionDialog() {
    final qtyController = TextEditingController(text: "1");
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Judul ikut tema
        title: Text(
          "Jual Produk",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.product['product_name'],
              // Warna teks abu di mode terang, agak terang di mode gelap
              style: GoogleFonts.poppins(
                fontSize: 12,
                color:
                    Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Jumlah (Qty)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Harga Total (\$)", // Pakai \ sebelum $
                hintText: "Contoh: 500.00",
                prefixText: "\$ ", // Pakai \ sebelum $
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (qtyController.text.isEmpty || priceController.text.isEmpty)
                return;

              Navigator.pop(context);

              bool success = await _service.createTransaction(
                widget.product['product_id'],
                int.parse(qtyController.text),
                double.parse(priceController.text),
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Transaksi Berhasil!"),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true); // Balik & Refresh
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Gagal menyimpan transaksi"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("SIMPAN"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AMBIL WARNA DARI TEMA
    final cardColor = Theme.of(context).cardTheme.color;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: scaffoldColor, // Background Dinamis

      appBar: AppBar(
        title: Text(
          "Detail Produk",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        // Hapus background/foreground statis, biarkan ikut tema
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Icon Produk Besar
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2,
                  size: 60,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Informasi Utama (Kartu)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor, // <--- PENTING: Ikut warna kartu tema
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nama Produk",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    widget.product['product_name'],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor, // Pastikan teks kontras
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Grid Info
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          "Kategori",
                          widget.product['category'],
                          textColor,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          "Sub-Kategori",
                          widget.product['sub_category'],
                          textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          "ID Produk",
                          widget.product['product_source_id'],
                          textColor,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem("Segment", "General", textColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 3. Tombol Jual Besar di Bawah
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: cardColor, // Background area tombol ikut warna kartu
        child: ElevatedButton(
          onPressed: _showTransactionDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_checkout, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "BUAT TRANSAKSI",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color? textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textColor, // Teks nilai ikut tema
          ),
        ),
      ],
    );
  }
}
