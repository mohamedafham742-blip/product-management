import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import 'recycle_bin_screen.dart';

class ProductsScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onAddTap;
  final VoidCallback? onTrashTap;

  const ProductsScreen({
    super.key,
    this.isTab = false,
    this.onAddTap,
    this.onTrashTap,
  });

  @override
  State<ProductsScreen> createState() => ProductsScreenState();
}

class ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  List<ProductModel> _products = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _selectedStatus = 'all';
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    // Real-time auto-sync: periodically refresh catalog in background so items added on Web appear instantly on Phone
    _autoSyncTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted && _searchController.text.trim().isEmpty) {
        _loadProducts(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void reloadProducts({bool silent = false}) {
    _loadProducts(silent: silent);
  }

  void addProductInstantly(ProductModel product) {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'all';
      _products.removeWhere((p) => p.id == product.id);
      _products.insert(0, product);
      if (_stats.containsKey('total_products')) {
        _stats['total_products'] = (_stats['total_products'] ?? 0) + 1;
      }
      if (product.status == 'active' && _stats.containsKey('active_products')) {
        _stats['active_products'] = (_stats['active_products'] ?? 0) + 1;
      }
    });
    // Silently sync with backend to refresh server state without spinner
    _loadProducts(silent: true);
  }

  Future<void> _loadProducts({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    final result = await ApiService().getProducts(
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      status: _selectedStatus != 'all' ? _selectedStatus : null,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _products = result['products'] ?? [];
        _stats = result['stats'] ?? {};
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load products')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isTab,
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products Catalog',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2B2623)),
            ),
            Text(
              'Manage inventory & stock items',
              style: TextStyle(fontSize: 11, color: Color(0xFF8C7F77)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFA33B2E), size: 20),
            tooltip: 'Recycle Bin',
            onPressed: () async {
              if (widget.onTrashTap != null) {
                widget.onTrashTap!();
              } else {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
                );
                _loadProducts();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5C5049), size: 20),
            tooltip: 'Refresh',
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadProducts(),
                  decoration: InputDecoration(
                    hintText: 'Search products by name or SKU...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA89C94)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF8C7F77), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadProducts();
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

                // Status Filter Chips
                Row(
                  children: [
                    _buildFilterChip('all', 'All (${_stats['total_products'] ?? _products.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('active', 'Active (${_stats['active_products'] ?? 0})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('inactive', 'Inactive (${_stats['inactive_products'] ?? 0})'),
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
                : _products.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFFC4B5AA)),
                                  SizedBox(height: 12),
                                  Text(
                                    'No products found',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2B2623)),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Pull down to refresh or tap + to add a product',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF8A7C73)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (widget.onAddTap != null) {
            widget.onAddTap!();
          } else {
            final created = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const ProductFormScreen()),
            );
            if (created == true) _loadProducts();
          }
        },
        backgroundColor: const Color(0xFF3D3835),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Product', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF7D7068),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF3D3835),
      backgroundColor: const Color(0xFFFAF7F4),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3D3835) : const Color(0xFFE5D8CF),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = status);
          _loadProducts();
        }
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
          );
          if (changed == true) _loadProducts();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2B2623),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5F0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5D8CF)),
                          ),
                          child: Text(
                            product.sku,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5C5049),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.isActive ? const Color(0xFFEAF5ED) : const Color(0xFFF5ECE6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: product.isActive ? const Color(0xFFCDE5D4) : const Color(0xFFE0D2C7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: product.isActive ? const Color(0xFF2C6E3D) : const Color(0xFF8C7D75),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.isActive ? const Color(0xFF2C6E3D) : const Color(0xFF7D7068),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (product.description != null && product.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  product.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8A7C73)),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0E6DE)),
              const SizedBox(height: 10),

              // Bottom Details: Price & Stock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rs. ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B2623),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${product.quantity} units',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF5C5049)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.isOutOfStock
                              ? const Color(0xFFFAF0EE)
                              : product.isLowStock
                                  ? const Color(0xFFFFF8EB)
                                  : const Color(0xFFEAF5ED),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.isOutOfStock
                              ? 'Out of stock'
                              : product.isLowStock
                                  ? 'Low stock'
                                  : 'In stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.isOutOfStock
                                ? const Color(0xFFA33B2E)
                                : product.isLowStock
                                    ? const Color(0xFF9E6517)
                                    : const Color(0xFF2C6E3D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
