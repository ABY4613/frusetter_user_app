import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/address_model.dart';
import '../utlits/api_constants.dart';

/// Address Controller using ChangeNotifier for Provider state management
class AddressController extends ChangeNotifier {
  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;
  Address? _selectedAddress;
  bool _isAddingAddress = false;

  // Getters
  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Address? get selectedAddress => _selectedAddress;
  bool get isAddingAddress => _isAddingAddress;

  // Get default address
  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  /// Set access token for API calls
  String? _accessToken;
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Fetch all addresses for the customer
  Future<void> fetchAddresses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiConstants.apiBaseUrl}/customer/addresses';
      debugPrint('AddressController: Fetching addresses from $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: _accessToken != null
                ? ApiConstants.authHeaders(_accessToken!)
                : ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('AddressController: Response status: ${response.statusCode}');
      debugPrint('AddressController: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final addressResponse = AddressListResponse.fromJson(responseData);

        _addresses = addressResponse.addresses;
        _isLoading = false;
        notifyListeners();
        debugPrint('AddressController: Loaded ${_addresses.length} addresses');
      } else {
        final responseData = jsonDecode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to fetch addresses';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AddressController: Error fetching addresses: $e');
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new address
  Future<AddressResponse> addAddress(Address address) async {
    _isAddingAddress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiConstants.apiBaseUrl}/customer/addresses';
      debugPrint('AddressController: Adding address to $url');
      debugPrint(
        'AddressController: Request body: ${jsonEncode(address.toJson())}',
      );

      final response = await http
          .post(
            Uri.parse(url),
            headers: _accessToken != null
                ? ApiConstants.authHeaders(_accessToken!)
                : ApiConstants.defaultHeaders,
            body: jsonEncode(address.toJson()),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('AddressController: Response status: ${response.statusCode}');
      debugPrint('AddressController: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final addressResponse = AddressResponse.fromJson(responseData);

        if (addressResponse.success && addressResponse.address != null) {
          // Add to local list
          _addresses.add(addressResponse.address!);

          // If this is set as default, update other addresses
          if (address.isDefault) {
            _updateDefaultAddress(addressResponse.address!.id);
          }

          _isAddingAddress = false;
          notifyListeners();
          debugPrint('AddressController: Address added successfully');
          return addressResponse;
        } else {
          _errorMessage =
              addressResponse.errorMessage ?? 'Failed to add address';
          _isAddingAddress = false;
          notifyListeners();
          return addressResponse;
        }
      } else {
        final responseData = jsonDecode(response.body);
        final errorMsg = responseData['message'] ?? 'Failed to add address';
        _errorMessage = errorMsg;
        _isAddingAddress = false;
        notifyListeners();
        return AddressResponse.error(errorMsg);
      }
    } catch (e) {
      debugPrint('AddressController: Error adding address: $e');
      _errorMessage = 'Network error. Please check your connection.';
      _isAddingAddress = false;
      notifyListeners();
      return AddressResponse.error(_errorMessage!);
    }
  }

  /// Update an existing address
  Future<AddressResponse> updateAddress(
    String addressId,
    Address address,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiConstants.apiBaseUrl}/customer/addresses/$addressId';
      debugPrint('AddressController: Updating address at $url');

      final response = await http
          .put(
            Uri.parse(url),
            headers: _accessToken != null
                ? ApiConstants.authHeaders(_accessToken!)
                : ApiConstants.defaultHeaders,
            body: jsonEncode(address.toJson()),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('AddressController: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final addressResponse = AddressResponse.fromJson(responseData);

        if (addressResponse.success) {
          // Update local list
          final index = _addresses.indexWhere((a) => a.id == addressId);
          if (index != -1 && addressResponse.address != null) {
            _addresses[index] = addressResponse.address!;
          }

          // If this is set as default, update other addresses
          if (address.isDefault) {
            _updateDefaultAddress(addressId);
          }

          _isLoading = false;
          notifyListeners();
          return addressResponse;
        } else {
          _errorMessage =
              addressResponse.errorMessage ?? 'Failed to update address';
          _isLoading = false;
          notifyListeners();
          return addressResponse;
        }
      } else {
        final responseData = jsonDecode(response.body);
        final errorMsg = responseData['message'] ?? 'Failed to update address';
        _errorMessage = errorMsg;
        _isLoading = false;
        notifyListeners();
        return AddressResponse.error(errorMsg);
      }
    } catch (e) {
      debugPrint('AddressController: Error updating address: $e');
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return AddressResponse.error(_errorMessage!);
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String addressId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiConstants.apiBaseUrl}/customer/addresses/$addressId';
      debugPrint('AddressController: Deleting address at $url');

      final response = await http
          .delete(
            Uri.parse(url),
            headers: _accessToken != null
                ? ApiConstants.authHeaders(_accessToken!)
                : ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('AddressController: Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from local list
        _addresses.removeWhere((a) => a.id == addressId);
        _isLoading = false;
        notifyListeners();
        debugPrint('AddressController: Address deleted successfully');
        return true;
      } else {
        final responseData = jsonDecode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to delete address';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AddressController: Error deleting address: $e');
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set an address as default
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      final url =
          '${ApiConstants.apiBaseUrl}/customer/addresses/$addressId/default';
      debugPrint('AddressController: Setting default address at $url');

      final response = await http
          .patch(
            Uri.parse(url),
            headers: _accessToken != null
                ? ApiConstants.authHeaders(_accessToken!)
                : ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        _updateDefaultAddress(addressId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AddressController: Error setting default address: $e');
      return false;
    }
  }

  /// Update default address locally
  void _updateDefaultAddress(String? newDefaultId) {
    for (int i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(
        isDefault: _addresses[i].id == newDefaultId,
      );
    }
  }

  /// Select an address
  void selectAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Add address locally (for testing/offline mode)
  void addAddressLocally(Address address) {
    _addresses.add(address);
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _addresses = [];
    _selectedAddress = null;
    _errorMessage = null;
    _isLoading = false;
    _isAddingAddress = false;
    notifyListeners();
  }
}
