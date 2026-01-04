class AddOnProduct {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final bool isAvailable;
  final int stockQuantity;
  final List<String> tags;
  final String? nutritionInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AddOnProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.stockQuantity = 0,
    this.tags = const [],
    this.nutritionInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory AddOnProduct.fromJson(Map<String, dynamic> json) {
    return AddOnProduct(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _parseDouble(json['price']),
      category: json['category']?.toString() ?? 'General',
      isAvailable: json['is_available'] ?? true,
      stockQuantity: _parseInt(json['stock_quantity']),
      tags: json['tags'] != null
          ? List<String>.from(json['tags'].map((e) => e.toString()))
          : [],
      nutritionInfo: json['nutrition_info']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'is_available': isAvailable,
      'stock_quantity': stockQuantity,
      'tags': tags,
      'nutrition_info': nutritionInfo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper getter to check if product is in stock
  bool get inStock => isAvailable && stockQuantity > 0;
}

/// Pagination model for API response
class PaginationInfo {
  final int limit;
  final int page;
  final int total;
  final int totalPages;

  PaginationInfo({
    required this.limit,
    required this.page,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      limit: json['limit'] ?? 50,
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limit': limit,
      'page': page,
      'total': total,
      'total_pages': totalPages,
    };
  }
}

/// API Response model for addons list
class AddonsResponse {
  final List<AddOnProduct> addons;
  final PaginationInfo pagination;
  final bool success;

  AddonsResponse({
    required this.addons,
    required this.pagination,
    required this.success,
  });

  factory AddonsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final addonsList = data['addons'] as List<dynamic>? ?? [];

    return AddonsResponse(
      addons: addonsList
          .map((item) => AddOnProduct.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(data['pagination'] ?? {}),
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'addons': addons.map((addon) => addon.toJson()).toList(),
        'pagination': pagination.toJson(),
      },
      'success': success,
    };
  }
}
