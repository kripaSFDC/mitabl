import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';

/// A warm, filled text field with no border — uses surface-container-low fill
/// and a 16px corner radius. On focus, background shifts to surface-container-lowest
/// with a 2px ghost-primary border.
class MitablTextField extends StatelessWidget {
  const MitablTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.inputFormatters,
    this.enabled = true,
    this.autofillHints,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MitablColors.onSurface,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          enabled: enabled,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          style: const TextStyle(
            fontSize: 15,
            color: MitablColors.onSurface,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: MitablColors.surfaceContainerLow,
            border: const OutlineInputBorder(
              borderRadius: MitablRadius.inputBorder,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: MitablRadius.inputBorder,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: MitablRadius.inputBorder,
              borderSide: BorderSide(
                color: MitablColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: MitablRadius.inputBorder,
              borderSide: BorderSide(color: MitablColors.error, width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: MitablRadius.inputBorder,
              borderSide: BorderSide(color: MitablColors.error, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintStyle: TextStyle(
              color: MitablColors.onSurfaceVariant.withValues(alpha: 0.5),
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}
