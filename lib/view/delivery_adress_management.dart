import 'package:flutter/material.dart';

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

  // Locations data
  final List<LocationItem> _locations = [
    LocationItem(
      id: '1',
      name: 'Home',
      address: '123 Maple Street',
      city: 'New York, NY 10012',
      isDefault: true,
      icon: Icons.home_rounded,
    ),
    LocationItem(
      id: '2',
      name: 'Office',
      address: 'Tech Park',
      city: 'San Francisco',
      isDefault: false,
      icon: Icons.business_rounded,
    ),
  ];

  // Schedule data
  final List<ScheduleItem> _schedule = [
    ScheduleItem(day: 'Monday', mealType: 'Lunch & Dinner', location: 'Home'),
    ScheduleItem(day: 'Tuesday', mealType: 'Lunch Only', location: 'Office'),
    ScheduleItem(day: 'Wednesday', mealType: 'Dinner Only', location: 'Office'),
    ScheduleItem(day: 'Thursday', mealType: 'Lunch & Dinner', location: 'Home'),
    ScheduleItem(day: 'Friday', mealType: 'Breakfast & Lunch', location: 'Gym'),
    ScheduleItem(day: 'Saturday', mealType: 'Skipped', location: 'None'),
    ScheduleItem(day: 'Sunday', mealType: 'Skipped', location: 'None'),
  ];

  final List<String> _locationOptions = ['Home', 'Office', 'Gym', 'None'];

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
      body: FadeTransition(
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
                      _buildMyLocationsSection(),
                      const SizedBox(height: 20),
                      // Add New Location Button
                      _buildAddLocationButton(),
                      const SizedBox(height: 32),
                      // Delivery Schedule Section
                      _buildDeliveryScheduleSection(),
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

  Widget _buildMyLocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Locations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _locations.length,
            itemBuilder: (context, index) {
              return _buildLocationCard(_locations[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(LocationItem location, int index) {
    final isSelected = _selectedLocationIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocationIndex = index;
        });
      },
      child: Container(
        width: 160,
        margin: EdgeInsets.only(right: index < _locations.length - 1 ? 12 : 0),
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
                        Icon(location.icon, color: primaryGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          location.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.address,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      location.city,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (location.isDefault)
                          Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                              letterSpacing: 0.5,
                            ),
                          )
                        else
                          const SizedBox(),
                        GestureDetector(
                          onTap: () => _showEditLocationDialog(location),
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
    return GestureDetector(
      onTap: () => _showAddLocationDialog(),
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
            const Text(
              'Add New Location',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Delivery Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Weekly',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Schedule list
        ...List.generate(_schedule.length, (index) {
          return _buildScheduleRow(_schedule[index], index);
        }),
      ],
    );
  }

  Widget _buildScheduleRow(ScheduleItem schedule, int index) {
    final isSkipped = schedule.location == 'None';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: index < _schedule.length - 1
                ? dividerColor
                : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Day info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.day,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSkipped ? textSecondary : textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  schedule.mealType,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    fontStyle: isSkipped ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          // Location dropdown
          _buildLocationDropdown(schedule, index),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown(ScheduleItem schedule, int index) {
    final isSkipped = schedule.location == 'None';

    IconData getLocationIcon(String location) {
      switch (location) {
        case 'Home':
          return Icons.home_rounded;
        case 'Office':
          return Icons.business_rounded;
        case 'Gym':
          return Icons.fitness_center_rounded;
        default:
          return Icons.not_listed_location_outlined;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSkipped ? dividerColor : lightGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSkipped ? cardBorder : primaryGreen.withOpacity(0.3),
        ),
      ),
      child: PopupMenuButton<String>(
        initialValue: schedule.location,
        onSelected: (value) {
          setState(() {
            _schedule[index] = ScheduleItem(
              day: schedule.day,
              mealType: value == 'None' ? 'Skipped' : schedule.mealType,
              location: value,
            );
          });
        },
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => _locationOptions.map((location) {
          return PopupMenuItem<String>(
            value: location,
            child: Row(
              children: [
                Icon(
                  getLocationIcon(location),
                  color: location == 'None' ? textSecondary : primaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  location,
                  style: TextStyle(
                    color: location == 'None' ? textSecondary : textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSkipped)
              Icon(
                getLocationIcon(schedule.location),
                color: primaryGreen,
                size: 16,
              ),
            if (!isSkipped) const SizedBox(width: 6),
            Text(
              schedule.location,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSkipped ? textSecondary : primaryGreen,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isSkipped ? textSecondary : primaryGreen,
              size: 18,
            ),
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
            onPressed: () {
              _showUpdateConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Update Schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddLocationDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: 20),
              _buildTextField(
                controller: nameController,
                label: 'Location Name',
                hint: 'e.g., Office, Gym',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: addressController,
                label: 'Street Address',
                hint: '123 Main Street',
                icon: Icons.home_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: cityController,
                label: 'City, State ZIP',
                hint: 'New York, NY 10012',
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        _locations.add(
                          LocationItem(
                            id: DateTime.now().toString(),
                            name: nameController.text,
                            address: addressController.text,
                            city: cityController.text,
                            isDefault: false,
                            icon: Icons.place_outlined,
                          ),
                        );
                        _locationOptions.insert(
                          _locationOptions.length - 1,
                          nameController.text,
                        );
                      });
                      Navigator.pop(context);
                      _showSuccessSnackbar('Location added successfully!');
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
                  child: const Text(
                    'Add Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditLocationDialog(LocationItem location) {
    final nameController = TextEditingController(text: location.name);
    final addressController = TextEditingController(text: location.address);
    final cityController = TextEditingController(text: location.city);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: 20),
              _buildTextField(
                controller: nameController,
                label: 'Location Name',
                hint: 'e.g., Office, Gym',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: addressController,
                label: 'Street Address',
                hint: '123 Main Street',
                icon: Icons.home_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: cityController,
                label: 'City, State ZIP',
                hint: 'New York, NY 10012',
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(location);
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
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          final index = _locations.indexWhere(
                            (l) => l.id == location.id,
                          );
                          if (index != -1) {
                            _locations[index] = LocationItem(
                              id: location.id,
                              name: nameController.text,
                              address: addressController.text,
                              city: cityController.text,
                              isDefault: location.isDefault,
                              icon: location.icon,
                            );
                          }
                        });
                        Navigator.pop(context);
                        _showSuccessSnackbar('Location updated successfully!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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

  void _showDeleteConfirmation(LocationItem location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Location?',
          style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${location.name}"? This action cannot be undone.',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _locations.removeWhere((l) => l.id == location.id);
                _locationOptions.remove(location.name);
              });
              Navigator.pop(context);
              _showSuccessSnackbar('Location deleted!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSaveConfirmation() {
    _showSuccessSnackbar('Settings saved successfully!');
    Navigator.pop(context);
  }

  void _showUpdateConfirmation() {
    _showSuccessSnackbar('Schedule updated successfully!');
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
}

// Data models
class LocationItem {
  final String id;
  final String name;
  final String address;
  final String city;
  final bool isDefault;
  final IconData icon;

  LocationItem({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.isDefault,
    required this.icon,
  });
}

class ScheduleItem {
  final String day;
  final String mealType;
  final String location;

  ScheduleItem({
    required this.day,
    required this.mealType,
    required this.location,
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
