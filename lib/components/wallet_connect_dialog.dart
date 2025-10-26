import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';

class WalletConnectDialog extends StatelessWidget {
  final String uri;

  const WalletConnectDialog({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonCircularRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: getThemeColors(context)['background'],
          borderRadius: BorderRadius.circular(buttonCircularRadius),
          border: Border.all(
            color: getThemeColors(context)['border']!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Choose Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your wallet app to connect:',
              style: TextStyle(
                fontSize: 14,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'On emulator: Consider using web wallets or copying URI',
              style: TextStyle(
                fontSize: 11,
                color: getThemeColors(context)['textSecondary'],
              ),
            ),
            const SizedBox(height: 20),

            // Wallet options
            ...walletProvider.walletOptions.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final wallet = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(buttonCircularRadius),
                      child: InkWell(
                        onTap: () async {
                          try {
                            await walletProvider.openWallet(wallet, uri);
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();
                          } catch (e) {
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor:
                                    // ignore: use_build_context_synchronously
                                    getThemeColors(context)['error'],
                              ),
                            );
                          }
                        },
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                        child: Container(
                          decoration: BoxDecoration(
                            color: index % 2 == 0
                                ? getThemeColors(context)['primary']
                                : getThemeColors(context)['secondary'],
                            border: Border.all(
                              color: getThemeColors(context)['border']!,
                              width: buttonborderWidth,
                            ),
                            borderRadius:
                                BorderRadius.circular(buttonCircularRadius),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                wallet.icon,
                                size: 20,
                                color: getThemeColors(context)['textPrimary'],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                wallet.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: getThemeColors(context)['textPrimary'],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(buttonCircularRadius),
                  child: InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: uri));
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('URI copied to clipboard!'),
                          // ignore: use_build_context_synchronously
                          backgroundColor: getThemeColors(context)['primary'],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                    child: Container(
                      decoration: BoxDecoration(
                        color: getThemeColors(context)['secondary'],
                        border: Border.all(
                          color: getThemeColors(context)['border']!,
                          width: buttonborderWidth,
                        ),
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.copy,
                            size: 20,
                            color: getThemeColors(context)['textPrimary'],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Copy URI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: getThemeColors(context)['textPrimary'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(buttonCircularRadius),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                    child: Container(
                      decoration: BoxDecoration(
                        color: getThemeColors(context)['background'],
                        border: Border.all(
                          color: getThemeColors(context)['border']!,
                          width: buttonborderWidth,
                        ),
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: getThemeColors(context)['textPrimary'],
                          ),
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
    );
  }
}
