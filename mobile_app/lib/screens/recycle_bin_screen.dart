import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class RecycleBinScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onRestored;

  const RecycleBinScreen({
    super.key,
    this.isTab = false,
    this.onRestored,
  });

  @override
  State<RecycleBinScreen> createState() => RecycleBinScreenState();
}

class RecycleBinScreenState extends State<RecycleBinScreen> {
  final _searchController = TextEditingController();
  List<ProductModel> _trashedProducts = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isProcessingAction = false;
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _loadTrashedProducts();
    // Real-time auto-sync: keep recycle bin in sync with actions from Web
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_isProcessingAction && _searchController.text.trim().isEmpty) {
        _loadTrashedProducts(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void reloadTrash({bool silent = false}) {
    _loadTrashedProducts(silent: silent);
  }

  Future<void> _loadTrashedProducts({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    final result = await ApiService().getTrashedProducts(
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _trashedProducts = result['products'] ?? [];
        _stats = result['stats'] ?? {};
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load recycle bin')),
        );
      }
    }
  }

  Future<void> _handleRestore(ProductModel product) async {
    setState(() => _isProcessingAction = true);
    final result = await ApiService().restoreProduct(product.id);
    if (!mounted) return;
    setState(() => _isProcessingAction = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Restored '${product.name}' to catalog."),
          backgroundColor: const Color(0xFF2C6E3D),
        ),
      );
      _loadTrashedProducts();
      widget.onRestored?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to restore product.'),
          backgroundColor: const Color(0xFFA33B2E),
        ),
      );
    }
  }

  Future<void> _handleForceDelete(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Permanently Delete?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFA33B2E)),
        ),
        content: Text(
          "Are you sure you want to permanently delete '${product.name}'? This cannot be undone.",
        ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessingAction = true);
      final result = await ApiService().forceDeleteProduct(product.id);
      if (!mounted) return;
      setState(() => _isProcessingAction = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Permanently deleted '${product.name}'."),
            backgroundColor: const Color(0xFF3D3835),
          ),
        );
        _loadTrashedProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete permanently.'),
            backgroundColor: const Color(0xFFA33B2E),
          ),
        );
      }
    }
  }

  Future<void> _handleRestoreAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Restore All Products?'),
        content: const Text('All items currently in the recycle bin will be returned to the active product catalog.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF7D716A))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C6E3D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Restore All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessingAction = true);
      final result = await ApiService().restoreAllProducts();
      if (!mounted) return;
      setState(() => _isProcessingAction = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'All products restored.'),
            backgroundColor: const Color(0xFF2C6E3D),
          ),
        );
        _loadTrashedProducts();
        widget.onRestored?.call();
      }
    }
  }

  Future<void> _handleEmptyTrash() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Empty Recycle Bin?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFA33B2E)),
        ),
        content: const Text(
          'This will PERMANENTLY erase all soft-deleted products from the database. This action CANNOT be reversed.',
        ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessingAction = true);
      final result = await ApiService().emptyTrash();
      if (!mounted) return;
      setState(() => _isProcessingAction = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recycle bin has been emptied.'),
            backgroundColor: Color(0xFF3D3835),
          ),
        );
        _loadTrashedProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalInTrash = _stats['total_in_trash'] ?? _trashedProducts.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isTab,
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.delete_sweep_outlined, size: 18, color: Color(0xFFA33B2E)),
                SizedBox(width: 6),
                Text(
                  'Recycle Bin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2B2623)),
                ),
              ],
            ),
            Text(
              '$totalInTrash soft-deleted items safely stored',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8C7F77)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5C5049), size: 20),
            tooltip: 'Refresh Trash',
            onPressed: _loadTrashedProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Batch Actions Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadTrashedProducts(),
                  decoration: InputDecoration(
                    hintText: 'Search deleted items by name, SKU...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA89C94)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF8C7F77), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadTrashedProducts();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFFAF7F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5D8CF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5D8CF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3D3835), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Batch Actions Row
                if (_trashedProducts.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessingAction ? null : _handleRestoreAll,
                          icon: const Icon(Icons.restore, size: 16, color: Color(0xFF2C6E3D)),
                          label: const Text(
                            'Restore All',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2C6E3D)),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFEAF5ED),
                            side: const BorderSide(color: Color(0xFFCDE5D4)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessingAction ? null : _handleEmptyTrash,
                          icon: const Icon(Icons.delete_forever_outlined, size: 16, color: Color(0xFFA33B2E)),
                          label: const Text(
                            'Empty Trash',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA33B2E)),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF9F8),
                            side: const BorderSide(color: Color(0xFFF4C5BD)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE7DCD2)),

          // Product List Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3D3835)),
                    ),
                  )
                : _trashedProducts.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadTrashedProducts,
                        child: ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0EBE6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, size: 36, color: Color(0xFF8C7F77)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Recycle Bin is Empty',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2B2623)),
                                  ),
                                  const SizedBox(height: 6),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 40),
                                    child: Text(
                                      'Soft-deleted products are safely stored here and can be restored anytime back to your catalog.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Color(0xFF8A7C73), height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTrashedProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _trashedProducts.length,
                          itemBuilder: (context, index) {
                            final product = _trashedProducts[index];
                            return _buildTrashedCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashedCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5D8CF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5D8CF).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: SKU and Trashed Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5D8CF)),
                  ),
                  child: Text(
                    product.sku,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5C5049),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBEBE8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF4C5BD)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline, size: 12, color: Color(0xFFA33B2E)),
                      SizedBox(width: 4),
                      Text(
                        'Soft Deleted',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA33B2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Product Name
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2623),
              ),
            ),

            if (product.description != null && product.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                product.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7D7068), height: 1.3),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0E6DE)),
            const SizedBox(height: 10),

            // Price in Rs. and Stock Quantity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Price: ',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8C7F77)),
                    ),
                    Text(
                      'Rs. ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D3835),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Stock: ${product.quantity} units',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7D7068)),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Action Buttons: Restore & Delete Forever
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessingAction ? null : () => _handleRestore(product),
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Restore to Catalog'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C6E3D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isProcessingAction ? null : () => _handleForceDelete(product),
                  icon: const Icon(Icons.delete_forever_outlined, color: Color(0xFFA33B2E), size: 20),
                  tooltip: 'Permanent Delete',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF9F8),
                    side: const BorderSide(color: Color(0xFFF4C5BD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
