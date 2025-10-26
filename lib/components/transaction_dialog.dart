import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';

class TransactionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? transactionHash;
  final bool isSuccess;
  final VoidCallback? onClose;

  const TransactionDialog({
    super.key,
    required this.title,
    required this.message,
    this.transactionHash,
    this.isSuccess = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = getThemeColors(context);

    return Dialog(
      backgroundColor: colors['background'],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        side: BorderSide(
          color: colors['border']!,
          width: buttonborderWidth,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors['background'],
          borderRadius: BorderRadius.circular(buttonCircularRadius),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSuccess ? colors['primary'] : colors['error'],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors['border']!,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle : Icons.error,
                      color: colors['textPrimary'],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors['textPrimary'],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: colors['textPrimary'],
                  height: 1.5,
                ),
              ),

              if (transactionHash != null && transactionHash!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors['secondary'],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors['border']!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 16,
                            color: colors['textPrimary'],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Transaction Hash',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors['textPrimary'],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${transactionHash!.substring(0, 10)}...${transactionHash!.substring(transactionHash!.length - 8)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: colors['textPrimary'],
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: transactionHash!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Hash copied!'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: colors['primary'],
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.copy,
                              size: 16,
                              color: colors['textPrimary'],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(buttonCircularRadius),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onClose != null) onClose!();
                    },
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSuccess ? colors['primary'] : colors['secondary'],
                        border: Border.all(
                          color: colors['border']!,
                          width: buttonborderWidth,
                        ),
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                      ),
                      child: Center(
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: colors['textPrimary'],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String? transactionHash,
    VoidCallback? onClose,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TransactionDialog(
            title: title,
            message: message,
            transactionHash: transactionHash,
            isSuccess: true,
            onClose: onClose,
          ),
        );
      }
    });
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onClose,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TransactionDialog(
            title: title,
            message: message,
            isSuccess: false,
            onClose: onClose,
          ),
        );
      }
    });
  }
}
