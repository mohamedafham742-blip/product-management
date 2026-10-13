import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final result = await ApiService().getProduct(widget.productId);
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _product = result['product'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to load details')),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Move to Recycle Bin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete ${_product?.name}? It will be moved to the Recycle Bin and can be restored anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF7D716A))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA33B2E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService().deleteProduct(widget.productId);
      if (!mounted) return;

      if (res['success'] == true) {
        Navigator.pop(context, true); // Return true to indicate change
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Delete failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2623)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2B2623)),
        ),
        actions: [
          if (_product != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF3D3835)),
              tooltip: 'Edit Product',
              onPressed: () async {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => ProductFormScreen(product: _product)),
                );
                if (updated == true) _loadDetails();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFA33B2E)),
              tooltip: 'Delete Product',
              onPressed: _handleDelete,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3D3835)),
              ),
            )
          : _product == null
              ? const Center(child: Text('Product not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5D8CF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF5F0),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE5D8CF)),
                                  ),
                                  child: Text(
                                    _product!.sku,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5C5049),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _product!.isActive ? const Color(0xFFEAF5ED) : const Color(0xFFF5ECE6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _product!.isActive ? const Color(0xFFCDE5D4) : const Color(0xFFE0D2C7),
                                    ),
                                  ),
                                  child: Text(
                                    _product!.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _product!.isActive ? const Color(0xFF2C6E3D) : const Color(0xFF7D7068),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _product!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B2623),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Metric Grid (Price & Quantity)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5D8CF)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'UNIT PRICE',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: Color(0xFF8A7C73)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs. ${_product!.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2B2623),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5D8CF)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'STOCK LEVEL',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: Color(0xFF8A7C73)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_product!.quantity} units',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2B2623),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Description Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5D8CF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DESCRIPTION',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: Color(0xFF8A7C73)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _product!.description != null && _product!.description!.isNotEmpty
                                  ? _product!.description!
                                  : 'No description provided for this product.',
                              style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF5C5049)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
