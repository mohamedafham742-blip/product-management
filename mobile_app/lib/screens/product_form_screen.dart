import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;
  final bool isTab;
  final VoidCallback? onSaved;
  final Function(ProductModel)? onProductCreated;

  const ProductFormScreen({
    super.key,
    this.product,
    this.isTab = false,
    this.onSaved,
    this.onProductCreated,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  String _status = 'active';
  bool _isSaving = false;
  String? _errorMessage;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _priceController = TextEditingController(
      text: widget.product != null ? widget.product!.price.toStringAsFixed(2) : '',
    );
    _quantityController = TextEditingController(
      text: widget.product != null ? widget.product!.quantity.toString() : '',
    );
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _status = widget.product?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = {
      'name': _nameController.text.trim(),
      'sku': _skuController.text.trim().toUpperCase(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
      'status': _status,
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    };

    final Map<String, dynamic> res;
    if (isEditing) {
      res = await ApiService().updateProduct(widget.product!.id, payload);
    } else {
      res = await ApiService().createProduct(payload);
    }

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Product saved successfully.'),
          backgroundColor: const Color(0xFF2C6E3D),
        ),
      );
      if (widget.isTab) {
        _nameController.clear();
        _skuController.clear();
        _priceController.clear();
        _quantityController.clear();
        _descriptionController.clear();
        setState(() {
          _status = 'active';
        });
        if (res['product'] != null && res['product'] is ProductModel) {
          widget.onProductCreated?.call(res['product'] as ProductModel);
        }
        widget.onSaved?.call();
      } else {
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Failed to save product.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2623)),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          isEditing ? 'Edit Product' : 'Add New Product',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2B2623)),
        ),
        actions: widget.isTab && !isEditing
            ? [
                TextButton(
                  onPressed: () {
                    _formKey.currentState?.reset();
                    _nameController.clear();
                    _skuController.clear();
                    _priceController.clear();
                    _quantityController.clear();
                    _descriptionController.clear();
                    setState(() {
                      _status = 'active';
                      _errorMessage = null;
                    });
                  },
                  child: const Text('Reset', style: TextStyle(color: Color(0xFF8C7F77))),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF0EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEBCAC4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFA63628), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFA63628)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Card Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5D8CF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    _buildLabel('Product Name *'),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('e.g. Minimalist Linen Notebook'),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // SKU / Code
                    _buildLabel('SKU / Code *'),
                    TextFormField(
                      controller: _skuController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration('e.g. PRD-NB-001'),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'SKU is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Price & Quantity Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Price (Rs.) *'),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _inputDecoration('29.99'),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Price required';
                                  if (double.tryParse(val) == null) return 'Invalid number';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Stock Quantity *'),
                              TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('50'),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Qty required';
                                  if (int.tryParse(val) == null) return 'Invalid integer';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    _buildLabel('Status *'),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: _inputDecoration(''),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active (Visible in catalog)')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive (Hidden from catalog)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildLabel('Description (Optional)'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration('Product specifications, notes...'),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D3835),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isEditing ? 'UPDATE PRODUCT' : 'SAVE PRODUCT',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5A4F48)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA89C94)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
