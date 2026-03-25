import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class OrderRejectionSheet extends StatefulWidget {
  const OrderRejectionSheet({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderRejectionSheet> createState() => _OrderRejectionSheetState();
}

class _OrderRejectionSheetState extends State<OrderRejectionSheet> {
  String _selectedReason = 'Kitchen too busy';
  final TextEditingController _messageController = TextEditingController();

  static const List<String> _reasons = [
    'Kitchen too busy',
    'Out of ingredients',
    'Other',
  ];

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
        left: 16,
        right: 16,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ──
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
            const SizedBox(height: 16),

            // ── Back button ──
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Row(
                children: const [
                  Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: MitablColors.onSurfaceVariant,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'BACK TO ORDER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ──
            Text(
              'Reject Order #${widget.orderId}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Please select a reason for declining this request.',
              style: TextStyle(
                fontSize: 14,
                color: MitablColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // ── Rejection Form Container ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MitablColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Radio Options ──
                  ..._reasons.map((reason) {
                    final isSelected = _selectedReason == reason;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedReason = reason),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: MitablColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Custom radio circle
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? MitablColors.primary
                                        : MitablColors.outlineVariant,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: MitablColors.primary,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                reason,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: MitablColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // ── Custom Message Field Label ──
                  const Text(
                    'MESSAGE TO THE FOODIE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Text Area ──
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          "Briefly explain why you can't fulfill this order...",
                      hintStyle: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: MitablColors.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: MitablColors.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'A kind message helps keep your rating high.',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Confirm Button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final message = _messageController.text.trim();
                        String result = _selectedReason;
                        if (message.isNotEmpty) {
                          result = '$result: $message';
                        }
                        Navigator.of(context).pop(result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MitablColors.primary,
                        foregroundColor: MitablColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor:
                            MitablColors.primary.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: MitablRadius.pillBorder,
                        ),
                      ),
                      child: const Text(
                        'Confirm Rejection',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Info Note ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Color(0xFF475569),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Declining orders frequently may affect your visibility in the search results. Try setting your kitchen to "Busy" if you\'re over capacity.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
