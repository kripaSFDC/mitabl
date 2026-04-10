import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// "Or continue with" divider line used across auth screens.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.text = 'Or continue with'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: MitablColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: MitablColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: MitablColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

/// Row of 3 social login icon buttons (Google, Apple, Facebook).
/// All show a "Coming soon" snackbar on tap — no backend integration.
class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialIcon(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google',
          size: 28,
        ),
        SizedBox(width: 16),
        _SocialIcon(
          icon: Icons.apple,
          label: 'Apple',
          size: 24,
        ),
        SizedBox(width: 16),
        _SocialIcon(
          icon: Icons.facebook_rounded,
          label: 'Facebook',
          size: 24,
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({
    required this.icon,
    required this.label,
    this.size = 24,
  });

  final IconData icon;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label sign-in coming soon'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(MitablRadius.card),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: MitablColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(MitablRadius.card),
        ),
        child: Icon(
          icon,
          size: size,
          color: MitablColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
