import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';

/// Sentinel object to distinguish "not provided" from "explicitly null"
const _unset = Object();

/// Filter options for the tree map
class MapFilterOptions {
  final bool showAliveOnly;
  final bool showDeceasedOnly;
  final String? speciesFilter;
  final int? minCareCount;
  final DateTime? plantedAfter;
  final DateTime? plantedBefore;

  const MapFilterOptions({
    this.showAliveOnly = false,
    this.showDeceasedOnly = false,
    this.speciesFilter,
    this.minCareCount,
    this.plantedAfter,
    this.plantedBefore,
  });

  /// Creates a copy with the given fields replaced.
  /// Uses sentinel pattern to allow explicitly setting nullable fields to null.
  MapFilterOptions copyWith({
    bool? showAliveOnly,
    bool? showDeceasedOnly,
    Object? speciesFilter = _unset,
    Object? minCareCount = _unset,
    Object? plantedAfter = _unset,
    Object? plantedBefore = _unset,
  }) {
    return MapFilterOptions(
      showAliveOnly: showAliveOnly ?? this.showAliveOnly,
      showDeceasedOnly: showDeceasedOnly ?? this.showDeceasedOnly,
      speciesFilter: speciesFilter == _unset
          ? this.speciesFilter
          : speciesFilter as String?,
      minCareCount:
          minCareCount == _unset ? this.minCareCount : minCareCount as int?,
      plantedAfter: plantedAfter == _unset
          ? this.plantedAfter
          : plantedAfter as DateTime?,
      plantedBefore: plantedBefore == _unset
          ? this.plantedBefore
          : plantedBefore as DateTime?,
    );
  }

  bool get hasActiveFilters =>
      showAliveOnly ||
      showDeceasedOnly ||
      speciesFilter != null ||
      minCareCount != null ||
      plantedAfter != null ||
      plantedBefore != null;
}

/// Widget for filtering trees on the map
class MapFilterWidget extends StatefulWidget {
  final MapFilterOptions initialOptions;
  final List<String> availableSpecies;
  final Function(MapFilterOptions) onFilterChanged;

  const MapFilterWidget({
    super.key,
    required this.initialOptions,
    required this.availableSpecies,
    required this.onFilterChanged,
  });

  @override
  State<MapFilterWidget> createState() => _MapFilterWidgetState();
}

class _MapFilterWidgetState extends State<MapFilterWidget> {
  late MapFilterOptions _options;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _options = widget.initialOptions;
  }

  void _updateOptions(MapFilterOptions newOptions) {
    setState(() {
      _options = newOptions;
    });
    widget.onFilterChanged(newOptions);
  }

  void _clearFilters() {
    _updateOptions(const MapFilterOptions());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    color: _options.hasActiveFilters
                        ? getThemeColors(context)['primary']
                        : getThemeColors(context)['icon'],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
                  if (_options.hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: getThemeColors(context)['primary'],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: getThemeColors(context)['icon'],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded filters
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status filter
                  Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFilterChip(
                        context,
                        label: 'Alive',
                        isSelected: _options.showAliveOnly,
                        onTap: () {
                          _updateOptions(_options.copyWith(
                            showAliveOnly: !_options.showAliveOnly,
                            showDeceasedOnly: false,
                          ));
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Deceased',
                        isSelected: _options.showDeceasedOnly,
                        onTap: () {
                          _updateOptions(_options.copyWith(
                            showDeceasedOnly: !_options.showDeceasedOnly,
                            showAliveOnly: false,
                          ));
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Species filter
                  if (widget.availableSpecies.isNotEmpty) ...[
                    Text(
                      'Species',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: getThemeColors(context)['textPrimary'],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: getThemeColors(context)['border']!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String?>(
                        value: _options.speciesFilter,
                        hint: Text(
                          'All species',
                          style: TextStyle(
                            color: getThemeColors(context)['textPrimary'],
                          ),
                        ),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All species'),
                          ),
                          ...widget.availableSpecies.map((species) {
                            return DropdownMenuItem<String?>(
                              value: species,
                              child: Text(species),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          _updateOptions(_options.copyWith(speciesFilter: value));
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Clear filters button
                  if (_options.hasActiveFilters)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear all filters'),
                        style: TextButton.styleFrom(
                          foregroundColor: getThemeColors(context)['error'],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? getThemeColors(context)['primary']
              : getThemeColors(context)['background'],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? getThemeColors(context)['primary']!
                : getThemeColors(context)['border']!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? Colors.white
                : getThemeColors(context)['textPrimary'],
          ),
        ),
      ),
    );
  }
}

/// Quick filter bar for common filters
class QuickFilterBar extends StatelessWidget {
  final MapFilterOptions options;
  final Function(MapFilterOptions) onFilterChanged;

  const QuickFilterBar({
    super.key,
    required this.options,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _buildQuickFilter(
            context,
            icon: Icons.eco,
            label: 'Alive',
            isActive: options.showAliveOnly,
            onTap: () {
              onFilterChanged(options.copyWith(
                showAliveOnly: !options.showAliveOnly,
                showDeceasedOnly: false,
              ));
            },
          ),
          const SizedBox(width: 8),
          _buildQuickFilter(
            context,
            icon: Icons.favorite,
            label: 'Well-cared',
            isActive: options.minCareCount != null && options.minCareCount! > 0,
            onTap: () {
              onFilterChanged(options.copyWith(
                minCareCount: options.minCareCount == null ? 5 : null,
              ));
            },
          ),
          const SizedBox(width: 8),
          _buildQuickFilter(
            context,
            icon: Icons.new_releases,
            label: 'Recent',
            isActive: options.plantedAfter != null,
            onTap: () {
              final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
              onFilterChanged(options.copyWith(
                plantedAfter: options.plantedAfter == null ? thirtyDaysAgo : null,
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? getThemeColors(context)['primary']
              : getThemeColors(context)['background'],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? getThemeColors(context)['primary']!
                : getThemeColors(context)['border']!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : getThemeColors(context)['icon'],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : getThemeColors(context)['textPrimary'],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
