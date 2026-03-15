import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../controller/address_controller.dart';
import '../controller/auth_controller.dart';
import '../controller/subscription_controller.dart';
import '../model/address_model.dart';
import '../utlits/meal_service.dart';
import 'location_picker_screen.dart';

class DeliveryAddressManagement extends StatefulWidget {
  const DeliveryAddressManagement({super.key});

  @override
  State<DeliveryAddressManagement> createState() =>
      _DeliveryAddressManagementState();
}

class _DeliveryAddressManagementState extends State<DeliveryAddressManagement>
    with SingleTickerProviderStateMixin {
  // App colors
  static const Color primaryGreen = Color(0xFF8AC53D);
  static const Color lightGreen = Color(0xFFE8F5D9);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Selected location index
  int _selectedLocationIndex = 0;

  // Schedule data
  List<ScheduleItem> _schedule = [];
  bool _isUpdatingSchedule = false;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Initialize address controller with token and fetch addresses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAddressController();
      _generateSchedule();
    });
  }

  void _generateSchedule() {
    final subscriptionController = context.read<SubscriptionController>();
    final addressController = context.read<AddressController>();
    
    // Default meal types if plan data not yet loaded
    List<String> planMealTypes = subscriptionController.plan?.mealTypes ?? ['lunch', 'dinner'];
    if (planMealTypes.isEmpty) planMealTypes = ['lunch', 'dinner'];

    List<ScheduleItem> newSchedule = [];
    DateTime current = DateTime.now().add(const Duration(days: 1));
    int count = 0;

    // Generate next 6 delivery days (excluding Sunday)
    while (count < 6) {
      if (current.weekday != DateTime.sunday) {
        newSchedule.add(ScheduleItem(
          date: current,
          settings: planMealTypes.map((type) => MealAddressSetting(
            mealType: type,
            // Try to find default address
            addressId: addressController.addresses.isNotEmpty 
                ? addressController.addresses.firstWhere((a) => a.isDefault, orElse: () => addressController.addresses.first).id 
                : null,
            addressLabel: addressController.addresses.isNotEmpty 
                ? addressController.addresses.firstWhere((a) => a.isDefault, orElse: () => addressController.addresses.first).label 
                : 'Select Address',
          )).toList(),
        ));
        count++;
      }
      current = current.add(const Duration(days: 1));
    }

    setState(() {
      _schedule = newSchedule;
    });
  }

  void _initializeAddressController() {
    final authController = context.read<AuthController>();
    final addressController = context.read<AddressController>();

    // Set the access token
    addressController.setAccessToken(authController.accessToken);

    // Fetch addresses from API
    addressController.fetchAddresses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<AddressController>(
        builder: (context, addressController, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // My Locations Section
                          _buildMyLocationsSection(addressController),
                          const SizedBox(height: 20),
                          // Add New Location Button
                          _buildAddLocationButton(),
                          const SizedBox(height: 32),
                          // Delivery Schedule Section
                          _buildDeliveryScheduleSection(addressController),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
                // Update Schedule Button
                _buildUpdateButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: textPrimary, size: 24),
      ),
      title: const Text(
        'Delivery\nSettings',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.3,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () {
            _showSaveConfirmation();
          },
          child: const Text(
            'Save',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyLocationsSection(AddressController addressController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Locations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            if (addressController.isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryGreen,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (addressController.errorMessage != null)
          _buildErrorCard(addressController.errorMessage!)
        else if (addressController.addresses.isEmpty &&
            !addressController.isLoading)
          _buildEmptyLocationsCard()
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: addressController.addresses.length,
              itemBuilder: (context, index) {
                return _buildLocationCard(
                  addressController.addresses[index],
                  index,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(errorMessage, style: TextStyle(color: Colors.red[700])),
          ),
          IconButton(
            onPressed: _initializeAddressController,
            icon: Icon(Icons.refresh, color: Colors.red[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLocationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_outlined,
              color: primaryGreen,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No locations added',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first delivery location',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Address address, int index) {
    final isSelected = _selectedLocationIndex == index;

    IconData getIconForLabel(String label) {
      switch (label.toLowerCase()) {
        case 'home':
          return Icons.home_rounded;
        case 'office':
        case 'work':
          return Icons.business_rounded;
        case 'gym':
          return Icons.fitness_center_rounded;
        default:
          return Icons.place_outlined;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocationIndex = index;
        });
        context.read<AddressController>().selectAddress(address);
      },
      child: Container(
        width: 160,
        margin: EdgeInsets.only(
          right: index < context.read<AddressController>().addresses.length - 1
              ? 12
              : 0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryGreen : cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryGreen.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Preview
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[200]),
                    child: Stack(
                      children: [
                        // Map placeholder with grid pattern
                        CustomPaint(
                          size: const Size(double.infinity, 80),
                          painter: _MapGridPainter(),
                        ),
                        // Map location marker
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryGreen.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Selection checkmark
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            // Location Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getIconForLabel(address.label),
                          color: primaryGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            address.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.addressLine1,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${address.city}, ${address.state}',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: lightGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: primaryGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        else
                          const SizedBox(),
                        GestureDetector(
                          onTap: () => _showEditLocationDialog(address),
                          child: Icon(
                            Icons.edit_outlined,
                            color: textSecondary,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddLocationButton() {
    return Consumer<AddressController>(
      builder: (context, addressController, child) {
        return GestureDetector(
          onTap: addressController.isAddingAddress
              ? null
              : () => _showAddLocationDialog(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (addressController.isAddingAddress)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryGreen,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_location_alt_outlined,
                      color: primaryGreen,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  addressController.isAddingAddress
                      ? 'Adding Location...'
                      : 'Add New Location',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: addressController.isAddingAddress
                        ? textSecondary
                        : textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryScheduleSection(AddressController addressController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Delivery Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Next 6 Days',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Set different addresses for your breakfast, lunch, and dinner deliveries.',
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
        const SizedBox(height: 20),
        
        if (_schedule.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: primaryGreen),
            ),
          )
        else
          // Schedule list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _schedule.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildScheduleCard(_schedule[index], index, addressController);
            },
          ),
      ],
    );
  }

  Widget _buildScheduleCard(ScheduleItem schedule, int scheduleIndex, AddressController addressController) {
    String formattedDate = DateFormat('EEEE, MMM dd').format(schedule.date);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: primaryGreen),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Meal Types
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: schedule.settings.map((setting) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Meal Type Icon & Label
                      Container(
                        width: 100,
                        child: Row(
                          children: [
                            Icon(
                              _getMealIcon(setting.mealType),
                              size: 18,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              setting.mealType[0].toUpperCase() + setting.mealType.substring(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Address Dropdown
                      Expanded(
                        child: _buildAddressSelector(scheduleIndex, setting, addressController),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return Icons.free_breakfast_rounded;
      case 'lunch': return Icons.lunch_dining_rounded;
      case 'dinner': return Icons.dinner_dining_rounded;
      default: return Icons.restaurant_rounded;
    }
  }

  Widget _buildAddressSelector(int scheduleIndex, MealAddressSetting setting, AddressController addressController) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
      ),
      child: PopupMenuButton<Address>(
        onSelected: (address) {
          setState(() {
            setting.addressId = address.id;
            setting.addressLabel = address.label;
          });
        },
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => addressController.addresses.map((addr) {
          return PopupMenuItem<Address>(
            value: addr,
            child: Row(
              children: [
                Icon(
                  addr.label.toLowerCase() == 'home' ? Icons.home_rounded : 
                  (addr.label.toLowerCase() == 'office' ? Icons.business_rounded : Icons.place),
                  color: primaryGreen, 
                  size: 18
                ),
                const SizedBox(width: 10),
                Text(addr.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                setting.addressLabel ?? 'Select Address',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryGreen,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: primaryGreen, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUpdatingSchedule ? null : _handleUpdateSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isUpdatingSchedule
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Update Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdateSchedule() async {
    final authController = context.read<AuthController>();
    final token = authController.accessToken;
    
    if (token == null) return;

    setState(() => _isUpdatingSchedule = true);

    int successCount = 0;
    int totalUpdates = 0;

    // Collect all unique updates
    for (var schedule in _schedule) {
      for (var setting in schedule.settings) {
        if (setting.addressId != null) {
          totalUpdates++;
          final success = await MealService.updateMealAddress(
            accessToken: token,
            deliveryDate: DateFormat('yyyy-MM-dd').format(schedule.date),
            mealType: setting.mealType,
            addressId: setting.addressId!,
          );
          if (success) successCount++;
        }
      }
    }

    if (mounted) {
      setState(() => _isUpdatingSchedule = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successCount == totalUpdates 
              ? 'Schedule updated successfully! ✨' 
              : 'Updated $successCount of $totalUpdates meal settings.'
          ),
          backgroundColor: successCount == totalUpdates ? primaryGreen : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  void _showAddLocationDialog() {
    final labelController = TextEditingController();
    final addressLine1Controller = TextEditingController();
    final addressLine2Controller = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final postalCodeController = TextEditingController();

    double? selectedLatitude;
    double? selectedLongitude;
    bool isDefault = false;
    bool hasPickedLocation = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: textSecondary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Picker Button
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push<LatLng>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationPickerScreen(
                                initialLocation:
                                    selectedLatitude != null &&
                                        selectedLongitude != null
                                    ? LatLng(
                                        selectedLatitude!,
                                        selectedLongitude!,
                                      )
                                    : null,
                              ),
                            ),
                          );

                          if (result != null) {
                            setModalState(() {
                              selectedLatitude = result.latitude;
                              selectedLongitude = result.longitude;
                              hasPickedLocation = true;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hasPickedLocation
                                ? lightGreen
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasPickedLocation
                                  ? primaryGreen
                                  : cardBorder,
                              width: hasPickedLocation ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: hasPickedLocation
                                      ? primaryGreen
                                      : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  hasPickedLocation
                                      ? Icons.check
                                      : Icons.map_outlined,
                                  color: hasPickedLocation
                                      ? Colors.white
                                      : textSecondary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasPickedLocation
                                          ? 'Location Selected'
                                          : 'Pick Location on Map',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: hasPickedLocation
                                            ? primaryGreen
                                            : textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hasPickedLocation
                                          ? 'Lat: ${selectedLatitude!.toStringAsFixed(4)}, Lng: ${selectedLongitude!.toStringAsFixed(4)}'
                                          : 'Tap to select your delivery location',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: hasPickedLocation
                                    ? primaryGreen
                                    : textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Label
                      _buildFormTextField(
                        controller: labelController,
                        label: 'Location Label *',
                        hint: 'e.g., Home, Office, Gym',
                        icon: Icons.label_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Address Line 1
                      _buildFormTextField(
                        controller: addressLine1Controller,
                        label: 'Address Line 1 *',
                        hint: '123 Main Street',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Address Line 2
                      _buildFormTextField(
                        controller: addressLine2Controller,
                        label: 'Address Line 2 (Optional)',
                        hint: 'Apartment, suite, unit, etc.',
                        icon: Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 16),

                      // City and State Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormTextField(
                              controller: cityController,
                              label: 'City *',
                              hint: 'Mumbai',
                              icon: Icons.location_city_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormTextField(
                              controller: stateController,
                              label: 'State *',
                              hint: 'Maharashtra',
                              icon: Icons.map_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Postal Code
                      _buildFormTextField(
                        controller: postalCodeController,
                        label: 'Postal Code *',
                        hint: '400001',
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      // Set as Default
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_outline,
                              color: primaryGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Set as Default',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Use this as primary delivery location',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isDefault,
                              onChanged: (value) {
                                setModalState(() {
                                  isDefault = value;
                                });
                              },
                              activeColor: primaryGreen,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Add Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Consumer<AddressController>(
                  builder: (context, addressController, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: addressController.isAddingAddress
                            ? null
                            : () async {
                                // Validate
                                if (labelController.text.isEmpty ||
                                    addressLine1Controller.text.isEmpty ||
                                    cityController.text.isEmpty ||
                                    stateController.text.isEmpty ||
                                    postalCodeController.text.isEmpty) {
                                  _showErrorSnackbar(
                                    'Please fill all required fields',
                                  );
                                  return;
                                }

                                if (!hasPickedLocation) {
                                  _showErrorSnackbar(
                                    'Please pick a location on the map',
                                  );
                                  return;
                                }

                                // Create address object
                                final address = Address(
                                  label: labelController.text,
                                  addressLine1: addressLine1Controller.text,
                                  addressLine2:
                                      addressLine2Controller.text.isNotEmpty
                                      ? addressLine2Controller.text
                                      : null,
                                  city: cityController.text,
                                  state: stateController.text,
                                  postalCode: postalCodeController.text,
                                  latitude: selectedLatitude!,
                                  longitude: selectedLongitude!,
                                  isDefault: isDefault,
                                );

                                // Call API
                                final response = await addressController
                                    .addAddress(address);

                                if (response.success) {
                                  Navigator.pop(context);
                                  _showSuccessSnackbar(
                                    'Location added successfully!',
                                  );
                                } else {
                                  _showErrorSnackbar(
                                    response.errorMessage ??
                                        'Failed to add location',
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: addressController.isAddingAddress
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Add Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditLocationDialog(Address address) {
    final labelController = TextEditingController(text: address.label);
    final addressLine1Controller = TextEditingController(
      text: address.addressLine1,
    );
    final addressLine2Controller = TextEditingController(
      text: address.addressLine2 ?? '',
    );
    final cityController = TextEditingController(text: address.city);
    final stateController = TextEditingController(text: address.state);
    final postalCodeController = TextEditingController(
      text: address.postalCode,
    );

    double? selectedLatitude = address.latitude;
    double? selectedLongitude = address.longitude;
    bool isDefault = address.isDefault;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: textSecondary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Picker Button
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push<LatLng>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationPickerScreen(
                                initialLocation: LatLng(
                                  selectedLatitude!,
                                  selectedLongitude!,
                                ),
                              ),
                            ),
                          );

                          if (result != null) {
                            setModalState(() {
                              selectedLatitude = result.latitude;
                              selectedLongitude = result.longitude;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primaryGreen, width: 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_location,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Change Location on Map',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lat: ${selectedLatitude!.toStringAsFixed(4)}, Lng: ${selectedLongitude!.toStringAsFixed(4)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: primaryGreen),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form fields (same as add dialog)
                      _buildFormTextField(
                        controller: labelController,
                        label: 'Location Label *',
                        hint: 'e.g., Home, Office, Gym',
                        icon: Icons.label_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildFormTextField(
                        controller: addressLine1Controller,
                        label: 'Address Line 1 *',
                        hint: '123 Main Street',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildFormTextField(
                        controller: addressLine2Controller,
                        label: 'Address Line 2 (Optional)',
                        hint: 'Apartment, suite, unit, etc.',
                        icon: Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormTextField(
                              controller: cityController,
                              label: 'City *',
                              hint: 'Mumbai',
                              icon: Icons.location_city_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormTextField(
                              controller: stateController,
                              label: 'State *',
                              hint: 'Maharashtra',
                              icon: Icons.map_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFormTextField(
                        controller: postalCodeController,
                        label: 'Postal Code *',
                        hint: '400001',
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      // Set as Default
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_outline,
                              color: primaryGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Set as Default',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Use this as primary delivery location',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isDefault,
                              onChanged: (value) {
                                setModalState(() {
                                  isDefault = value;
                                });
                              },
                              activeColor: primaryGreen,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Delete Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(address);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Save Button
                    Expanded(
                      flex: 2,
                      child: Consumer<AddressController>(
                        builder: (context, addressController, child) {
                          return ElevatedButton(
                            onPressed: addressController.isLoading
                                ? null
                                : () async {
                                    // Validate
                                    if (labelController.text.isEmpty ||
                                        addressLine1Controller.text.isEmpty ||
                                        cityController.text.isEmpty ||
                                        stateController.text.isEmpty ||
                                        postalCodeController.text.isEmpty) {
                                      _showErrorSnackbar(
                                        'Please fill all required fields',
                                      );
                                      return;
                                    }

                                    // Create updated address
                                    final updatedAddress = Address(
                                      id: address.id,
                                      label: labelController.text,
                                      addressLine1: addressLine1Controller.text,
                                      addressLine2:
                                          addressLine2Controller.text.isNotEmpty
                                          ? addressLine2Controller.text
                                          : null,
                                      city: cityController.text,
                                      state: stateController.text,
                                      postalCode: postalCodeController.text,
                                      latitude: selectedLatitude!,
                                      longitude: selectedLongitude!,
                                      isDefault: isDefault,
                                    );

                                    // Call API
                                    final response = await addressController
                                        .updateAddress(
                                          address.id!,
                                          updatedAddress,
                                        );

                                    if (response.success) {
                                      Navigator.pop(context);
                                      _showSuccessSnackbar(
                                        'Location updated successfully!',
                                      );
                                    } else {
                                      _showErrorSnackbar(
                                        response.errorMessage ??
                                            'Failed to update location',
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: addressController.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
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

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: primaryGreen, size: 22),
            filled: true,
            fillColor: dividerColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Location?',
          style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${address.label}"? This action cannot be undone.',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          Consumer<AddressController>(
            builder: (context, addressController, child) {
              return ElevatedButton(
                onPressed: addressController.isLoading
                    ? null
                    : () async {
                        final success = await addressController.deleteAddress(
                          address.id!,
                        );
                        Navigator.pop(context);
                        if (success) {
                          _showSuccessSnackbar('Location deleted!');
                        } else {
                          _showErrorSnackbar(
                            addressController.errorMessage ??
                                'Failed to delete location',
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: addressController.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Delete'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSaveConfirmation() {
    _showSuccessSnackbar('Settings saved successfully!');
    Navigator.pop(context);
  }


  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Data models
class ScheduleItem {
  final DateTime date;
  final List<MealAddressSetting> settings;

  ScheduleItem({
    required this.date,
    required this.settings,
  });
}

class MealAddressSetting {
  final String mealType;
  String? addressId;
  String? addressLabel;

  MealAddressSetting({
    required this.mealType,
    this.addressId,
    this.addressLabel,
  });
}

// Map grid painter for location card background
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Draw vertical lines
    for (double x = 0; x < size.width; x += 15) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw some "road" lines
    final roadPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
