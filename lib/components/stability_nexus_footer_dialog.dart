import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';

class StabilityNexusFooterDialog extends StatelessWidget {
  const StabilityNexusFooterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = getThemeColors(context);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.black,
          width: 3,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(),
                Text(
                  'About Stability Nexus',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Stability Nexus is the organization behind this innovative tree planting protocol project.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connect with us:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildSocialLinks(context, colors),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors['secondary'],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: const Text('Close',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks(BuildContext context, Map<String, Color> colors) {
    final links = [
      {
        'name': 'Website',
        'url': 'https://stability.nexus/',
        'icon': Icons.language,
        'useSecondary': true,
      },
      {
        'name': 'X (Twitter)',
        'url': 'https://x.com/StabilityNexus',
        'icon': Icons.close, // X icon
        'useSecondary': false,
      },
      {
        'name': 'LinkedIn',
        'url': 'https://linkedin.com/company/stability-nexus',
        'icon': Icons.business,
        'useSecondary': true,
      },
      {
        'name': 'GitHub',
        'url': 'https://github.com/StabilityNexus',
        'icon': Icons.code,
        'useSecondary': false,
      },
      {
        'name': 'Discord',
        'url': 'https://discord.com/invite/YzDKeEfWtS',
        'icon': Icons.chat,
        'useSecondary': true,
      },
      {
        'name': 'Telegram',
        'url': 'https://t.me/StabilityNexus',
        'icon': Icons.send,
        'useSecondary': false,
      },
      {
        'name': 'YouTube',
        'url': 'https://www.youtube.com/@StabilityNexus',
        'icon': Icons.play_circle_filled,
        'useSecondary': true,
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: links.map((link) {
        return _buildSocialButton(
          name: link['name'] as String,
          url: link['url'] as String,
          icon: link['icon'] as IconData,
          colors: colors,
          useSecondary: link['useSecondary'] as bool,
        );
      }).toList(),
    );
  }

  Widget _buildSocialButton({
    required String name,
    required String url,
    required IconData icon,
    required Map<String, Color> colors,
    required bool useSecondary,
  }) {
    final buttonColor =
        useSecondary ? colors['secondary']! : colors['primary']!;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _launchURL(url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      // Fallback or error handling
      debugPrint('Error launching URL: $e');
    }
  }
}
