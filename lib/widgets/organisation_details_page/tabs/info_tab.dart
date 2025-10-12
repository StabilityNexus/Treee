import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';

class InfoTab extends StatelessWidget {
  final String organisationDescription;
  final int timeOfCreation;

  const InfoTab({
    super.key,
    required this.organisationDescription,
    required this.timeOfCreation,
  });

  String _formatDate(int timestamp) {
    if (timestamp == 0) return "Unknown";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: buttonborderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getThemeColors(context)['secondary'],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: getThemeColors(context)['border']!,
                width: 1,
              ),
            ),
            child: Text(
              organisationDescription.isNotEmpty
                  ? organisationDescription
                  : 'No description available',
              style: TextStyle(
                fontSize: 14,
                color: getThemeColors(context)['textPrimary'],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: getThemeColors(context)['primary'],
              ),
              const SizedBox(width: 8),
              Text(
                'Created: ${_formatDate(timeOfCreation)}',
                style: TextStyle(
                  fontSize: 14,
                  color: getThemeColors(context)['textPrimary'],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
