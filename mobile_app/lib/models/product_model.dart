class ProductModel {
  final int id;
  final String name;
  final String sku;
  final String? description;
  final double price;
  final int quantity;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    required this.price,
    required this.quantity,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity > 0 && quantity < 10;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      description: json['description'],
      price: json['price'] is num 
          ? (json['price'] as num).toDouble() 
          : double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: json['quantity'] is int 
          ? json['quantity'] 
          : int.tryParse(json['quantity'].toString()) ?? 0,
      status: json['status'] ?? 'active',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'description': description,
      'price': price,
      'quantity': quantity,
      'status': status,
    };
  }
}
