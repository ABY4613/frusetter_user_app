import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../model/feedback_model.dart';
import '../../utlits/feedback_service.dart';
import '../../controller/notification_controller.dart';

class FeedbackPopup extends StatefulWidget {
  final String deliveryId;
  final String mealName;
  final String accessToken;
  final VoidCallback onDismissed;

  const FeedbackPopup({
    super.key,
    required this.deliveryId,
    required this.mealName,
    required this.accessToken,
    required this.onDismissed,
  });

  @override
  State<FeedbackPopup> createState() => _FeedbackPopupState();
}

class _FeedbackPopupState extends State<FeedbackPopup> {
  int _foodQualityRating = 5;
  int _deliveryRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  static const Color primaryGreen = Color(0xFF8AC53D);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rate Your Meal! 🎉',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For ${widget.mealName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : widget.onDismissed,
                    icon: const Icon(Icons.close_rounded, color: textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Food Quality Rating
              _buildRatingSection(
                title: 'How was the food quality?',
                icon: Icons.restaurant_menu_rounded,
                rating: _foodQualityRating,
                onChanged: (val) => setState(() => _foodQualityRating = val),
              ),
              
              const SizedBox(height: 20),
              
              // Delivery Rating
              _buildRatingSection(
                title: 'How was the delivery?',
                icon: Icons.local_shipping_rounded,
                rating: _deliveryRating,
                onChanged: (val) => setState(() => _deliveryRating = val),
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Add a comment',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tell us more about your experience...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[100]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 28),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : widget.onDismissed,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Review',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection({
    required String title,
    required IconData icon,
    required int rating,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: primaryGreen),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final isSelected = index < rating;
            return GestureDetector(
              onTap: () => onChanged(index + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isSelected ? Colors.orange : Colors.grey[300],
                  size: 36,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    if (widget.deliveryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid delivery information')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Create request object - handle empty comments if needed
    final request = FeedbackRequest(
      deliveryId: widget.deliveryId,
      foodQualityRating: _foodQualityRating,
      deliveryRating: _deliveryRating,
      comments: _commentController.text.trim(),
    );
    
    debugPrint('FeedbackPopup: Submitting for delivery ${widget.deliveryId}');
    
    final success = await FeedbackService.submitFeedback(
      accessToken: widget.accessToken,
      request: request,
    );
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      
      // Use the root navigator context to show snackbar to avoid it being lost on dialog pop
      final messenger = ScaffoldMessenger.of(context);
      
      if (success) {
        // Mark as submitted in local state to prevent multiple popups
        try {
          final notificationController = context.read<NotificationController>();
          notificationController.markFeedbackAsSubmitted(widget.accessToken, widget.deliveryId);
        } catch (e) {
          debugPrint('FeedbackPopup: Could not notify NotificationController: $e');
        }

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your feedback helps us improve. ✨'),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        widget.onDismissed();
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not submit feedback. Please try again later.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
