import 'package:flutter/material.dart';
import '../../app/config/theme.dart';

/// Displays a styled glassmorphic confirmation dialog.
Future<bool?> showGlassConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Color confirmColor = const Color(0xFFDC2626), // Red 600 for WCAG AA 4.6:1 contrast
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
