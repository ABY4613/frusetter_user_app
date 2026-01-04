import 'package:flutter/foundation.dart';
import '../model/addon_model.dart';
import '../utlits/addon_service.dart';

/// Controller for managing addon state using Provider pattern
/// Follows MVC architecture for clean separation of concerns
class AddOnController extends ChangeNotifier {
  // Private state variables
  List<AddOnProduct> _addOns = [];
  PaginationInfo? _paginationInfo;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';

  // Public getters
  List<AddOnProduct> get addOns => _addOns;
  PaginationInfo? get paginationInfo => _paginationInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  /// Get unique categories from loaded addons
  List<String> get categories {
    final cats = _addOns.map((addon) => addon.category).toSet().toList();
    cats.sort(); // Sort alphabetically
    cats.insert(0, 'All');
    return cats;
  }

  /// Get filtered addons based on selected category
  List<AddOnProduct> get filteredAddOns {
    if (_selectedCategory == 'All') {
      return _addOns;
    }
    return _addOns
        .where((addon) => addon.category == _selectedCategory)
        .toList();
  }

  /// Get count of available addons
  int get availableCount => _addOns.where((addon) => addon.inStock).length;

  /// Get count of out of stock addons
  int get outOfStockCount => _addOns.where((addon) => !addon.inStock).length;

  /// Set selected category filter
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Fetch addons from API
  ///
  /// Parameters:
  /// - [accessToken]: User's authentication token
  /// - [page]: Page number for pagination (default: 1)
  /// - [limit]: Number of items per page (default: 50)
  /// - [category]: Optional category filter
  Future<void> fetchAddOns(
    String accessToken, {
    int page = 1,
    int limit = 50,
    String? category,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call API service
      final response = await AddonService.fetchAddons(
        accessToken: accessToken,
        page: page,
        limit: limit,
        category: category,
      );

      // Update state with response data
      if (response.success) {
        _addOns = response.addons;
        _paginationInfo = response.pagination;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load addons';
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _addOns = [];
      _paginationInfo = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh addons (convenience method for pull-to-refresh)
  Future<void> refreshAddOns(String accessToken) async {
    return fetchAddOns(accessToken);
  }

  /// Load more addons (for pagination)
  Future<void> loadMoreAddOns(String accessToken) async {
    if (_paginationInfo == null) return;

    final currentPage = _paginationInfo!.page;
    final totalPages = _paginationInfo!.totalPages;

    if (currentPage >= totalPages) {
      // Already at last page
      return;
    }

    // Load next page
    await fetchAddOns(
      accessToken,
      page: currentPage + 1,
      limit: _paginationInfo!.limit,
    );
  }

  /// Add addon to cart
  ///
  /// Parameters:
  /// - [accessToken]: User's authentication token
  /// - [productId]: ID of the addon product
  /// - [quantity]: Quantity to add
  ///
  /// Returns [bool] indicating success
  Future<bool> addToCart(
    String accessToken,
    String productId,
    int quantity,
  ) async {
    try {
      final success = await AddonService.addToCart(
        accessToken: accessToken,
        addonId: productId,
        quantity: quantity,
      );
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Get addon by ID
  AddOnProduct? getAddonById(String id) {
    try {
      return _addOns.firstWhere((addon) => addon.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset controller state
  void reset() {
    _addOns = [];
    _paginationInfo = null;
    _isLoading = false;
    _errorMessage = null;
    _selectedCategory = 'All';
    notifyListeners();
  }
}
