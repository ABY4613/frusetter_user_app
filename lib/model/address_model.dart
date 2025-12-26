/// Address Model for Frusette Customer App
class Address {
  final String? id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Address({
    this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Address from JSON response
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      label: json['label'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  /// Convert Address to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'address_line1': addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty)
        'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    };
  }

  /// Helper to parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Create a copy with modified fields
  Address copyWith({
    String? id,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get full address as a string
  String get fullAddress {
    final parts = <String>[];
    parts.add(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.add('$city, $state $postalCode');
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'Address(id: $id, label: $label, address: $fullAddress, lat: $latitude, lng: $longitude, isDefault: $isDefault)';
  }
}

/// API Response wrapper for address list
class AddressListResponse {
  final bool success;
  final List<Address> addresses;
  final String? message;
  final String? errorMessage;

  AddressListResponse({
    required this.success,
    required this.addresses,
    this.message,
    this.errorMessage,
  });

  factory AddressListResponse.fromJson(Map<String, dynamic> json) {
    final addressList = <Address>[];

    if (json['data'] != null) {
      if (json['data'] is List) {
        for (var item in json['data']) {
          addressList.add(Address.fromJson(item));
        }
      } else if (json['data']['addresses'] is List) {
        for (var item in json['data']['addresses']) {
          addressList.add(Address.fromJson(item));
        }
      }
    } else if (json['addresses'] is List) {
      for (var item in json['addresses']) {
        addressList.add(Address.fromJson(item));
      }
    }

    return AddressListResponse(
      success: json['success'] ?? true,
      addresses: addressList,
      message: json['message'],
    );
  }

  factory AddressListResponse.error(String message) {
    return AddressListResponse(
      success: false,
      addresses: [],
      errorMessage: message,
    );
  }
}

/// API Response wrapper for single address operations
class AddressResponse {
  final bool success;
  final Address? address;
  final String? message;
  final String? errorMessage;

  AddressResponse({
    required this.success,
    this.address,
    this.message,
    this.errorMessage,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    Address? address;

    if (json['data'] != null) {
      if (json['data'] is Map<String, dynamic>) {
        address = Address.fromJson(json['data']);
      }
    } else if (json['address'] != null) {
      address = Address.fromJson(json['address']);
    }

    return AddressResponse(
      success: json['success'] ?? true,
      address: address,
      message: json['message'],
    );
  }

  factory AddressResponse.error(String message) {
    return AddressResponse(
      success: false,
      address: null,
      errorMessage: message,
    );
  }
}
