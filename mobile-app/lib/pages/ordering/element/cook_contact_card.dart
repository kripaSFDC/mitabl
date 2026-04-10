import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Cook info card: photo with online dot, name, rating, and "Message" button.
/// Design: bg-white rounded-xl p-4 shadow-sm, border border-slate-100,
/// 56x56 avatar with green online dot, Message button with chat icon.
class CookContactCard extends StatelessWidget {
  const CookContactCard({
    super.key,
    required this.cookName,
  });

  final String cookName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF1F5F9), // slate-100
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with online dot
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: MitablColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const ClipOval(
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              // Online green dot
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E), // green-500
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Cook info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cookName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF0F172A), // slate-900
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber.shade500,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '4.9 (120+ meals)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B), // slate-500
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message button
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                '/SettingsCook',
                arguments: RouteArguments(
                  id: 'foodie',
                  data: const {'openSupport': true},
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFFE2E8F0), // slate-200
                  width: 2,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_outlined,
                    size: 20,
                    color: Color(0xFF334155), // slate-700
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Message',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
