import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/theme_provider.dart';

Color primaryYellowColor = Color.fromARGB(255, 251, 251, 99);
Color primaryGreenColor = Color.fromARGB(255, 28, 211, 129);

Map<String, Color> getThemeColors(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  return {
    'primary': themeProvider.isDarkMode
        ? Color.fromARGB(255, 0, 128, 70)
        : Color.fromARGB(255, 28, 211, 129),
    'primaryLight': themeProvider.isDarkMode
        ? Color.fromARGB(255, 0, 128, 70)
        : Color.fromARGB(255, 28, 211, 129),
    'primaryBorder': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 1, 135, 12)
        : const Color.fromARGB(255, 28, 211, 129),
    'border': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 255, 255, 255)
        : const Color.fromARGB(255, 18, 18, 18),
    'BNWBorder': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 1, 135, 12)
        : const Color.fromARGB(255, 28, 211, 129),
    'secondary': themeProvider.isDarkMode
        ? Color.fromARGB(255, 131, 131, 36)
        : Color.fromARGB(255, 251, 251, 99),
    'background': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 18, 18, 18)
        : const Color.fromARGB(255, 255, 255, 255),
    'secondaryBackground': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 83, 81, 84)
        : const Color.fromARGB(255, 210, 210, 210),
    'textPrimary': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 255, 255, 255)
        : const Color.fromARGB(255, 0, 0, 0),
    'textSecondary': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color.fromARGB(255, 255, 255, 255),
    'primaryButton': themeProvider.isDarkMode
        ? Color.fromARGB(255, 0, 128, 70)
        : Color.fromARGB(255, 28, 211, 129),
    'secondaryButton': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 255, 100, 100)
        : const Color.fromARGB(255, 255, 0, 0),
    'icon': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 255, 255, 255)
        : const Color.fromARGB(255, 0, 0, 0),
    'error': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 255, 100, 100)
        : const Color.fromARGB(255, 255, 0, 0),
    'marker': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 255, 100, 100)
        : const Color.fromARGB(255, 255, 0, 0),
    'primaryShadow': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 255, 255, 255)
        : const Color.fromARGB(255, 0, 0, 0),
    'secondaryBorder': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 1, 135, 12)
        : const Color.fromARGB(255, 28, 211, 129),
    'shadow': themeProvider.isDarkMode
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color.fromARGB(255, 128, 128, 128),
  };
}
