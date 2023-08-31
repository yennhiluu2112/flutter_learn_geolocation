import 'package:flutter/material.dart';

class OkCancelDialog extends StatelessWidget {
  const OkCancelDialog({
    super.key,
    required this.onPressed,
    this.title,
    this.content,
    this.contentText,
    this.cancelText,
    this.confirmText,
    this.bgColorButtonConfirm,
    this.showCancelButton = true,
  });

  final VoidCallback onPressed;
  final String? title;
  final Widget? content;
  final String? contentText;
  final String? cancelText;
  final String? confirmText;
  final Color? bgColorButtonConfirm;
  final bool showCancelButton;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Expanded(
                    child: Text(
                      title ?? '',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          overflow: TextOverflow.ellipsis),
                      maxLines: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            content ??
                Text(
                  contentText ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Visibility(
                  visible: showCancelButton,
                  child: OutlinedButton(
                    onPressed: Navigator.of(context).pop,
                    child: Text(cancelText ?? 'Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: onPressed,
                  child: Text(confirmText ?? 'OK'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
