import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';

class OrderRejectionSheet extends StatefulWidget {
  const OrderRejectionSheet({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderRejectionSheet> createState() => _OrderRejectionSheetState();
}

class _OrderRejectionSheetState extends State<OrderRejectionSheet> {
  String _selectedReason = 'Kitchen too busy';
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: MitablSpacing.pagePadding,
        right: MitablSpacing.pagePadding,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MitablColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Reject Order #${widget.orderId}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 20),

            // Radio options
            RadioListTile<String>(
              title: const Text('Kitchen too busy'),
              value: 'Kitchen too busy',
              groupValue: _selectedReason,
              activeColor: MitablColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _selectedReason = v!),
            ),
            RadioListTile<String>(
              title: const Text('Out of ingredients'),
              value: 'Out of ingredients',
              groupValue: _selectedReason,
              activeColor: MitablColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _selectedReason = v!),
            ),
            RadioListTile<String>(
              title: const Text('Other'),
              value: 'Other',
              groupValue: _selectedReason,
              activeColor: MitablColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _selectedReason = v!),
            ),

            const SizedBox(height: 16),

            // Message field
            MitablTextField(
              controller: _messageController,
              label: 'Message to the Foodie',
              hint: 'Add a personal message (optional)',
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            // Info note
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: MitablColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'This information will be shared with the customer',
                    style: TextStyle(
                      fontSize: 12,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Confirm button
            MitablButton(
              label: 'Confirm Rejection',
              variant: MitablButtonVariant.primary,
              onPressed: () {
                final message = _messageController.text.trim();
                String result = _selectedReason;
                if (message.isNotEmpty) {
                  result = '$result: $message';
                }
                Navigator.of(context).pop(result);
              },
            ),
          ],
        ),
      ),
    );
  }
}
