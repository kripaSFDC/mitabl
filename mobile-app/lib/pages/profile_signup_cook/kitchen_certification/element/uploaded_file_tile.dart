import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

/// Displays a picked file with its name, size, and a delete action.
class UploadedFileTile extends StatelessWidget {
  const UploadedFileTile({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.onDelete,
  });

  final String fileName;
  final String fileSize;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MitablCard(
      color: MitablColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: MitablColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: MitablColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fileSize,
                  style: const TextStyle(
                    fontSize: 12,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: MitablColors.error,
              size: 20,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
