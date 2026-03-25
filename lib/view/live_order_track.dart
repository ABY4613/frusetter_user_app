// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

// class LiveOrderTrack extends StatefulWidget {
//   const LiveOrderTrack({super.key});

//   @override
//   State<LiveOrderTrack> createState() => _LiveOrderTrackState();
// }

// class _LiveOrderTrackState extends State<LiveOrderTrack>
//     with TickerProviderStateMixin {
//   // App colors
//   static const Color primaryGreen = Color(0xFF8AC53D);
//   static const Color primaryDark = Color(0xFF6BA82E);
//   static const Color lightGreen = Color(0xFFE8F5D9);
//   static const Color backgroundColor = Color(0xFFF6F8F6);
//   static const Color surfaceColor = Colors.white;
//   static const Color textPrimary = Color(0xFF0D1B12);
//   static const Color textSecondary = Color(0xFF4C9A66);

//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;

//   // Map controller
//   final MapController _mapController = MapController();

//   // Locations - New Jersey area (like in the image)
//   final LatLng _driverLocation = const LatLng(40.7282, -74.0776); // Jersey City
//   final LatLng _destinationLocation = const LatLng(40.7580, -73.9855); // NYC

//   // Order details
//   final String _driverName = 'Marco D.';
//   final double _driverRating = 4.9;
//   final String _vehicleInfo = 'Black E-Scooter • ...';
//   final int _etaMinutes = 12;
//   final String _estimatedTime = '12:30 PM - 12:45 PM';
//   final double _progress = 0.75;

//   bool _isOrderDetailsExpanded = false;

//   @override
//   void initState() {
//     super.initState();

//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..repeat(reverse: true);

//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       body: Stack(
//         children: [
//           // Map Section
//           Positioned.fill(bottom: 380, child: _buildMapSection()),
//           // Map Controls
//           Positioned(
//             right: 16,
//             top: MediaQuery.of(context).padding.top + 100,
//             child: _buildMapControls(),
//           ),
//           // Bottom Sheet
//           Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomSheet()),
//           // Top App Bar
//           Positioned(top: 0, left: 0, right: 0, child: _buildAppBar()),
//         ],
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return Container(
//       padding: EdgeInsets.only(
//         top: MediaQuery.of(context).padding.top + 8,
//         left: 8,
//         right: 8,
//         bottom: 8,
//       ),
//       decoration: BoxDecoration(
//         color: backgroundColor.withOpacity(0.95),
//         border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
//       ),
//       child: Row(
//         children: [
//           // Back button
//           Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () => Navigator.pop(context),
//               borderRadius: BorderRadius.circular(24),
//               child: Container(
//                 width: 48,
//                 height: 48,
//                 alignment: Alignment.center,
//                 child: const Icon(
//                   Icons.arrow_back,
//                   color: textPrimary,
//                   size: 24,
//                 ),
//               ),
//             ),
//           ),
//           // Title
//           const Expanded(
//             child: Text(
//               'Order Tracking',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//                 color: textPrimary,
//                 letterSpacing: -0.5,
//               ),
//             ),
//           ),
//           // Support button
//           Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () => _showSupportDialog(),
//               borderRadius: BorderRadius.circular(24),
//               child: Container(
//                 width: 48,
//                 height: 48,
//                 alignment: Alignment.center,
//                 child: const Icon(
//                   Icons.support_agent,
//                   color: textPrimary,
//                   size: 24,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMapSection() {
//     return FlutterMap(
//       mapController: _mapController,
//       options: MapOptions(
//         initialCenter: LatLng(
//           (_driverLocation.latitude + _destinationLocation.latitude) / 2,
//           (_driverLocation.longitude + _destinationLocation.longitude) / 2,
//         ),
//         initialZoom: 12.0,
//         minZoom: 5,
//         maxZoom: 18,
//       ),
//       children: [
//         // OpenStreetMap Tile Layer
//         TileLayer(
//           urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//           userAgentPackageName: 'com.frusette.app',
//           maxZoom: 19,
//         ),
//         // Route Polyline
//         PolylineLayer(
//           polylines: [
//             Polyline(
//               points: _getRoutePoints(),
//               strokeWidth: 5.0,
//               color: primaryGreen,
//               borderStrokeWidth: 2.0,
//               borderColor: primaryDark,
//             ),
//           ],
//         ),
//         // Markers
//         MarkerLayer(
//           markers: [
//             // Destination marker
//             Marker(
//               point: _destinationLocation,
//               width: 50,
//               height: 50,
//               child: const Icon(Icons.location_on, color: Colors.red, size: 44),
//             ),
//             // Driver marker
//             Marker(
//               point: _driverLocation,
//               width: 120,
//               height: 80,
//               child: Column(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: primaryGreen,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: primaryGreen.withOpacity(0.4),
//                           blurRadius: 12,
//                           spreadRadius: 2,
//                         ),
//                       ],
//                     ),
//                     child: const Icon(
//                       Icons.moped,
//                       color: textPrimary,
//                       size: 22,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(6),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.15),
//                           blurRadius: 8,
//                         ),
//                       ],
//                     ),
//                     child: const Text(
//                       'On the way',
//                       style: TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         color: textPrimary,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   List<LatLng> _getRoutePoints() {
//     // Simulated route points between driver and destination
//     return [
//       _driverLocation,
//       LatLng(40.7350, -74.0600),
//       LatLng(40.7420, -74.0400),
//       LatLng(40.7480, -74.0200),
//       LatLng(40.7520, -74.0000),
//       _destinationLocation,
//     ];
//   }

//   Widget _buildMapControls() {
//     return Column(
//       children: [
//         // Zoom controls
//         Container(
//           decoration: BoxDecoration(
//             color: surfaceColor,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
//             ],
//           ),
//           child: Column(
//             children: [
//               _buildMapControlButton(Icons.add, () {
//                 final currentZoom = _mapController.camera.zoom;
//                 _mapController.move(
//                   _mapController.camera.center,
//                   currentZoom + 1,
//                 );
//               }),
//               Container(height: 1, color: Colors.grey[100]),
//               _buildMapControlButton(Icons.remove, () {
//                 final currentZoom = _mapController.camera.zoom;
//                 _mapController.move(
//                   _mapController.camera.center,
//                   currentZoom - 1,
//                 );
//               }),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         // My location button
//         Container(
//           decoration: BoxDecoration(
//             color: surfaceColor,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
//             ],
//           ),
//           child: _buildMapControlButton(Icons.my_location, () {
//             _mapController.move(_destinationLocation, 14);
//           }, isPrimary: true),
//         ),
//       ],
//     );
//   }

//   Widget _buildMapControlButton(
//     IconData icon,
//     VoidCallback onTap, {
//     bool isPrimary = false,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         width: 44,
//         height: 44,
//         alignment: Alignment.center,
//         child: Icon(
//           icon,
//           color: isPrimary ? primaryGreen : textPrimary,
//           size: 22,
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomSheet() {
//     return Container(
//       decoration: BoxDecoration(
//         color: surfaceColor,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.12),
//             blurRadius: 30,
//             offset: const Offset(0, -8),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Handle
//           Container(
//             margin: const EdgeInsets.only(top: 12, bottom: 8),
//             width: 48,
//             height: 5,
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(3),
//             ),
//           ),
//           // Content
//           SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ETA Header
//                 _buildETAHeader(),
//                 const SizedBox(height: 20),
//                 // Driver Card
//                 _buildDriverCard(),
//                 const SizedBox(height: 20),
//                 // Delivery Status
//                 _buildDeliveryStatus(),
//                 const SizedBox(height: 16),
//                 // Order Details
//                 _buildOrderDetails(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildETAHeader() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Arriving in $_etaMinutes mins',
//               style: const TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.w700,
//                 color: textPrimary,
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: primaryGreen.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: const Text(
//                 'ON TIME',
//                 style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.w700,
//                   color: primaryDark,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Estimated $_estimatedTime',
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: textSecondary,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDriverCard() {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.grey[100]!),
//       ),
//       child: Row(
//         children: [
//           // Driver photo with rating
//           Stack(
//             clipBehavior: Clip.none,
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.grey[300],
//                   border: Border.all(color: Colors.white, width: 2),
//                 ),
//                 child: const ClipOval(
//                   child: Icon(Icons.person, size: 28, color: Colors.grey),
//                 ),
//               ),
//               Positioned(
//                 bottom: -4,
//                 right: -4,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 6,
//                     vertical: 2,
//                   ),
//                   decoration: BoxDecoration(
//                     color: primaryGreen,
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: Colors.white, width: 1.5),
//                   ),
//                   child: Text(
//                     '$_driverRating',
//                     style: const TextStyle(
//                       fontSize: 9,
//                       fontWeight: FontWeight.w700,
//                       color: textPrimary,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(width: 12),
//           // Driver info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _driverName,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w700,
//                     color: textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   _vehicleInfo,
//                   style: const TextStyle(fontSize: 12, color: textSecondary),
//                 ),
//               ],
//             ),
//           ),
//           // Action buttons
//           Row(
//             children: [
//               _buildActionButton(
//                 Icons.chat_bubble,
//                 false,
//                 () => _showChatDialog(),
//               ),
//               const SizedBox(width: 8),
//               _buildActionButton(Icons.call, true, () => _showCallDialog()),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton(IconData icon, bool isPrimary, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         width: 40,
//         height: 40,
//         decoration: BoxDecoration(
//           color: isPrimary ? primaryGreen : Colors.white,
//           shape: BoxShape.circle,
//           border: isPrimary ? null : Border.all(color: Colors.grey[200]!),
//           boxShadow: isPrimary
//               ? [BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 8)]
//               : null,
//         ),
//         child: Icon(icon, size: 18, color: textPrimary),
//       ),
//     );
//   }

//   Widget _buildDeliveryStatus() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'DELIVERY STATUS',
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w700,
//             color: textPrimary.withOpacity(0.5),
//             letterSpacing: 0.5,
//           ),
//         ),
//         const SizedBox(height: 14),
//         // Stepper
//         _buildStatusStep(
//           icon: Icons.check,
//           title: 'Order Confirmed',
//           subtitle: '11:45 AM',
//           isCompleted: true,
//           isActive: false,
//           isLast: false,
//         ),
//         _buildStatusStep(
//           icon: Icons.restaurant,
//           title: 'Prepared & Packed',
//           subtitle: '12:10 PM',
//           isCompleted: true,
//           isActive: false,
//           isLast: false,
//         ),
//         _buildStatusStep(
//           icon: Icons.moped,
//           title: 'On the way to you',
//           subtitle: 'Marco is near your location',
//           isCompleted: false,
//           isActive: true,
//           isLast: true,
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusStep({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required bool isCompleted,
//     required bool isActive,
//     required bool isLast,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Icon and line
//         Column(
//           children: [
//             AnimatedBuilder(
//               animation: _pulseAnimation,
//               builder: (context, child) {
//                 return Transform.scale(
//                   scale: isActive ? _pulseAnimation.value : 1.0,
//                   child: Container(
//                     width: 36,
//                     height: 36,
//                     decoration: BoxDecoration(
//                       color: isActive
//                           ? primaryGreen
//                           : isCompleted
//                           ? primaryGreen.withOpacity(0.2)
//                           : Colors.grey[100],
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       icon,
//                       size: 18,
//                       color: isActive
//                           ? textPrimary
//                           : isCompleted
//                           ? primaryGreen
//                           : Colors.grey,
//                     ),
//                   ),
//                 );
//               },
//             ),
//             if (!isLast)
//               Container(
//                 width: 2,
//                 height: 28,
//                 color: isCompleted
//                     ? primaryGreen.withOpacity(0.3)
//                     : Colors.grey[200],
//               ),
//           ],
//         ),
//         const SizedBox(width: 14),
//         // Content
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.only(top: 6),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
//                     color: textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: isActive ? textSecondary : Colors.grey,
//                   ),
//                 ),
//                 if (!isLast) const SizedBox(height: 12),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildOrderDetails() {
//     return Container(
//       decoration: BoxDecoration(
//         border: Border(top: BorderSide(color: Colors.grey[100]!)),
//       ),
//       padding: const EdgeInsets.only(top: 14),
//       child: InkWell(
//         onTap: () {
//           setState(() {
//             _isOrderDetailsExpanded = !_isOrderDetailsExpanded;
//           });
//         },
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Weekly Plan: 5 Meals',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                         color: textPrimary,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       'Keto Chicken Salad x2, +3 more',
//                       style: TextStyle(fontSize: 11, color: textSecondary),
//                     ),
//                   ],
//                 ),
//                 Icon(
//                   _isOrderDetailsExpanded
//                       ? Icons.expand_less
//                       : Icons.expand_more,
//                   color: Colors.grey,
//                 ),
//               ],
//             ),
//             if (_isOrderDetailsExpanded) ...[
//               const SizedBox(height: 14),
//               _buildOrderItem('Keto Chicken Salad', 2),
//               _buildOrderItem('Grilled Salmon Bowl', 1),
//               _buildOrderItem('Avocado Toast Deluxe', 1),
//               _buildOrderItem('Green Smoothie Pack', 1),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOrderItem(String name, int quantity) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(name, style: const TextStyle(fontSize: 12, color: textPrimary)),
//           Text(
//             'x$quantity',
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSupportDialog() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Need Help?',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: textPrimary,
//               ),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: lightGreen,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.chat_bubble_outline,
//                   color: primaryGreen,
//                 ),
//               ),
//               title: const Text('Chat with Support'),
//               subtitle: const Text('Usually replies in 2 mins'),
//               onTap: () => Navigator.pop(context),
//             ),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: lightGreen,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(Icons.call, color: primaryGreen),
//               ),
//               title: const Text('Call Support'),
//               subtitle: const Text('Available 24/7'),
//               onTap: () => Navigator.pop(context),
//             ),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showChatDialog() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Row(
//           children: [
//             Icon(Icons.chat_bubble_outline, color: Colors.white),
//             SizedBox(width: 12),
//             Text('Opening chat with Marco...'),
//           ],
//         ),
//         backgroundColor: primaryGreen,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   void _showCallDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text(
//           'Call Driver?',
//           style: TextStyle(fontWeight: FontWeight.w700),
//         ),
//         content: Text('Call $_driverName about your delivery?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel', style: TextStyle(color: textSecondary)),
//           ),
//           ElevatedButton.icon(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(Icons.call, size: 18),
//             label: const Text('Call'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: primaryGreen,
//               foregroundColor: textPrimary,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
