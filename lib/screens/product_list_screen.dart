import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/retail_service.dart';
import '../services/notification_service.dart';
import 'product_detail_screen.dart';
import 'qr_scanner_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final RetailService _service = RetailService();
  final TextEditingController _searchController = TextEditingController();

  // Pagination State
  List<dynamic> _products = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts({String query = '', int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.getProducts(query: query, page: page);

      setState(() {
        _products = response['data'];
        _currentPage = response['current_page'];
        _lastPage = response['last_page'];
        _totalItems = response['total'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _changePage(int newPage) {
    if (newPage < 1 || newPage > _lastPage) return;
    _fetchProducts(query: _searchController.text, page: newPage);
  }

  // --- TRANSACTION DIALOG ---
  void _showTransactionDialog(Map<String, dynamic> product) {
    final qtyController = TextEditingController(text: "1");
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Jual Produk",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product['product_name'],
              style: GoogleFonts.poppins(fontSize: 12),
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
                labelText: "Harga Total (\$)",
                prefixText: "\$ ",
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
            onPressed: () async {
              if (qtyController.text.isEmpty || priceController.text.isEmpty)
                return;

              // Capture Context Reference (Anti-Crash)
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              // Parse Data Safely
              int qty = int.tryParse(qtyController.text) ?? 1;
              double sales =
                  double.tryParse(priceController.text.replaceAll(',', '')) ??
                  0.0;
              int prodId = int.tryParse(product['product_id'].toString()) ?? 0;

              navigator.pop(); // Close Dialog

              messenger.showSnackBar(
                const SnackBar(content: Text("Memproses transaksi...")),
              );

              bool success = await _service.createTransaction(
                prodId,
                qty,
                sales,
              );

              if (success) {
                // Trigger Notification
                try {
                  await NotificationService().showTransactionSuccess(
                    product['product_name'],
                    qty,
                    priceController.text,
                  );
                } catch (_) {}

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text("Transaksi Berhasil!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text("Gagal! Cek inputan."),
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
    final cardColor = Theme.of(context).cardTheme.color;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text(
          "Katalog Produk",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: cardColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari nama / scan...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _fetchProducts(page: 1);
                        },
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRScannerScreen(),
                          ),
                        );
                        if (result != null && result is String) {
                          _searchController.text = result;
                          _fetchProducts(query: result, page: 1);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (value) => _fetchProducts(query: value, page: 1),
            ),
          ),

          // 2. Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? Center(
                    child: Text(
                      "Produk tidak ditemukan",
                      style: GoogleFonts.poppins(),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );
                          },
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.blueAccent,
                            ),
                          ),
                          title: Text(
                            product['product_name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            "${product['category']} • ${product['sub_category']}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _showTransactionDialog(product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              "JUAL",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 3. Pagination Controls
          if (!_isLoading && _products.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentPage > 1
                        ? () => _changePage(_currentPage - 1)
                        : null,
                    icon: const Icon(Icons.arrow_back_ios, size: 14),
                    label: const Text("Prev"),
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "Halaman $_currentPage / $_lastPage",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Total: $_totalItems Item",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _currentPage < _lastPage
                        ? () => _changePage(_currentPage + 1)
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                    label: const Text("Next"),
                    iconAlignment: IconAlignment.end,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
