import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/addon_controller.dart';
import '../controller/auth_controller.dart';
import '../model/addon_model.dart';

// Color constants matching the app theme
const Color primaryGreen = Color(0xFF8AC53D);
const Color lightGreen = Color(0xFFF0F7E6);
const Color textPrimary = Color(0xFF1F2937);
const Color textSecondary = Color(0xFF6B7280);
const Color cardBorder = Color(0xFFE5E7EB);
const Color backgroundColor = Color(0xFFFAFAFA);

class AddOnsListScreen extends StatefulWidget {
  const AddOnsListScreen({super.key});

  @override
  State<AddOnsListScreen> createState() => _AddOnsListScreenState();
}

class _AddOnsListScreenState extends State<AddOnsListScreen> {
  // Track quantities for each product
  final Map<String, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _loadAddOns();
  }

  Future<void> _loadAddOns() async {
    final authController = context.read<AuthController>();
    final addOnController = context.read<AddOnController>();

    if (authController.accessToken != null) {
      await addOnController.fetchAddOns(authController.accessToken!);
    }
  }

  Future<void> _addAllToCart() async {
    final controller = context.read<AddOnController>();
    final authController = context.read<AuthController>();
    final userName = authController.user?.fullName ?? 'Customer';

    // Build order message
    String message = '*New Add-on Order*\n';
    message += '*Customer:* $userName\n\n';
    double totalPrice = 0;
    int totalItems = 0;

    for (final entry in _quantities.entries) {
      if (entry.value > 0) {
        final product = controller.addOns.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => controller.addOns.first,
        );

        final itemTotal = product.price * entry.value;
        totalPrice += itemTotal;
        totalItems += entry.value;

        message += '• ${product.title}\n';
        message += '  Quantity: ${entry.value}\n';
        message +=
            '  Price: ₹${product.price.toStringAsFixed(0)} x ${entry.value} = ₹${itemTotal.toStringAsFixed(0)}\n\n';
      }
    }

    message += '━━━━━━━━━━━━━━━━\n';
    message += '*Total Items:* $totalItems\n';
    message += '*Total Amount:* ₹${totalPrice.toStringAsFixed(0)}';

    // WhatsApp number
    const phoneNumber = '919895960067';

    // Encode message for URL
    final encodedMessage = Uri.encodeComponent(message);

    // Try WhatsApp URL schemes
    final whatsappUrls = [
      'whatsapp://send?phone=$phoneNumber&text=$encodedMessage',
      'https://wa.me/$phoneNumber?text=$encodedMessage',
      'https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage',
    ];

    bool launched = false;

    for (final urlString in whatsappUrls) {
      try {
        final uri = Uri.parse(urlString);
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          launched = true;
          break;
        }
      } catch (e) {
        // Try next URL
        continue;
      }
    }

    if (launched) {
      // Clear quantities after successful redirect
      if (mounted) {
        setState(() {
          _quantities.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Opening WhatsApp...')),
              ],
            ),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open WhatsApp. Please make sure WhatsApp is installed.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total items and price
    final totalItems = _quantities.values.fold<int>(0, (sum, qty) => sum + qty);
    final totalPrice = _calculateTotalPrice();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<AddOnController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage!,
                    style: const TextStyle(fontSize: 16, color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadAddOns,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (controller.addOns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No add-ons available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check back later for new products',
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadAddOns,
            color: primaryGreen,
            child: CustomScrollView(
              slivers: [
                // Category Filter
                SliverToBoxAdapter(child: _buildCategoryFilter(controller)),

                // Products List
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = controller.filteredAddOns[index];
                      return _buildProductListItem(product);
                    }, childCount: controller.filteredAddOns.length),
                  ),
                ),
                // Add bottom padding if cart has items
                if (totalItems > 0)
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomBar(totalItems, totalPrice),
    );
  }

  double _calculateTotalPrice() {
    double total = 0;
    final controller = context.read<AddOnController>();

    _quantities.forEach((productId, quantity) {
      final product = controller.addOns.firstWhere(
        (p) => p.id == productId,
        orElse: () => controller.addOns.first,
      );
      total += product.price * quantity;
    });

    return total;
  }

  Widget? _buildBottomBar(int totalItems, double totalPrice) {
    if (totalItems == 0) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Items and Price Info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Add to Cart Button
            Expanded(
              child: ElevatedButton(
                onPressed: _addAllToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Add-ons',
        style: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: cardBorder),
      ),
    );
  }

  Widget _buildCategoryFilter(AddOnController controller) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final category = controller.categories[index];
          final isSelected = controller.selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                controller.setCategory(category);
              },
              backgroundColor: Colors.white,
              selectedColor: lightGreen,
              checkmarkColor: primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? primaryGreen : textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
              side: BorderSide(
                color: isSelected ? primaryGreen : cardBorder,
                width: isSelected ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductListItem(AddOnProduct product) {
    final currentQuantity = _quantities[product.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title, Category and Price Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              fontSize: 11,
                              color: primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price
              Text(
                '₹${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          if (product.description.isNotEmpty) ...[
            Text(
              product.description,
              style: const TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],

          // Tags
          if (product.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: product.tags.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Nutrition Info
          if (product.nutritionInfo != null &&
              product.nutritionInfo!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    product.nutritionInfo!,
                    style: const TextStyle(fontSize: 11, color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Stock Status and Quantity Controls
          Row(
            children: [
              // Stock Status
              Icon(
                product.inStock ? Icons.check_circle : Icons.cancel,
                color: product.inStock ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                product.inStock
                    ? 'In Stock (${product.stockQuantity})'
                    : 'Out of Stock',
                style: TextStyle(
                  fontSize: 12,
                  color: product.inStock ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),

              // Quantity Controls or Add Button
              if (currentQuantity == 0)
                // Add Button
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: product.inStock
                        ? () => _incrementQuantity(product)
                        : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                )
              else
                // Quantity Controls
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryGreen, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus Button
                      InkWell(
                        onTap: () => _decrementQuantity(product),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(7),
                          bottomLeft: Radius.circular(7),
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.remove,
                            color: primaryGreen,
                            size: 18,
                          ),
                        ),
                      ),
                      // Quantity Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: primaryGreen, width: 1),
                            right: BorderSide(color: primaryGreen, width: 1),
                          ),
                        ),
                        child: Text(
                          currentQuantity.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      // Plus Button
                      InkWell(
                        onTap: currentQuantity < product.stockQuantity
                            ? () => _incrementQuantity(product)
                            : null,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(7),
                          bottomRight: Radius.circular(7),
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add,
                            color: currentQuantity < product.stockQuantity
                                ? primaryGreen
                                : Colors.grey,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _incrementQuantity(AddOnProduct product) {
    if ((_quantities[product.id] ?? 0) < product.stockQuantity) {
      setState(() {
        _quantities[product.id] = (_quantities[product.id] ?? 0) + 1;
      });
    }
  }

  void _decrementQuantity(AddOnProduct product) {
    final currentQty = _quantities[product.id] ?? 0;
    if (currentQty > 0) {
      setState(() {
        _quantities[product.id] = currentQty - 1;
      });
    }
  }
}
