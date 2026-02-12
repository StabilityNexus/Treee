import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:tree_planting_protocol/services/tree_map_service.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';

/// Search result types
enum SearchResultType { tree, location, geohash }

/// Search result model
class MapSearchResult {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final LatLng location;
  final MapTreeData? tree;

  MapSearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.location,
    this.tree,
  });
}

/// Search widget for the map
class MapSearchWidget extends StatefulWidget {
  final List<MapTreeData> trees;
  final Function(MapSearchResult) onResultSelected;
  final Function(LatLng, double)? onLocationSearch;

  const MapSearchWidget({
    super.key,
    required this.trees,
    required this.onResultSelected,
    this.onLocationSearch,
  });

  @override
  State<MapSearchWidget> createState() => _MapSearchWidgetState();
}

class _MapSearchWidgetState extends State<MapSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<MapSearchResult> _results = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _showResults = false);
          }
        });
      }
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = <MapSearchResult>[];
    final queryLower = query.toLowerCase();

    // Search by tree ID
    if (RegExp(r'^\d+$').hasMatch(query)) {
      final id = int.tryParse(query);
      if (id != null) {
        final matchingTrees = widget.trees.where((t) => t.id == id);
        for (final tree in matchingTrees) {
          results.add(MapSearchResult(
            type: SearchResultType.tree,
            title: 'Tree #${tree.id}',
            subtitle: tree.species,
            location: tree.position,
            tree: tree,
          ));
        }
      }
    }

    // Search by species
    final speciesMatches = widget.trees.where(
      (t) => t.species.toLowerCase().contains(queryLower),
    );
    for (final tree in speciesMatches.take(5)) {
      if (!results.any((r) => r.tree?.id == tree.id)) {
        results.add(MapSearchResult(
          type: SearchResultType.tree,
          title: tree.species,
          subtitle: 'Tree #${tree.id}',
          location: tree.position,
          tree: tree,
        ));
      }
    }

    // Search by geohash
    if (query.length >= 4 && RegExp(r'^[0-9a-z]+$').hasMatch(queryLower)) {
      final geohashMatches = widget.trees.where(
        (t) => t.geoHash.toLowerCase().startsWith(queryLower),
      );
      if (geohashMatches.isNotEmpty) {
        final firstMatch = geohashMatches.first;
        results.add(MapSearchResult(
          type: SearchResultType.geohash,
          title: 'Geohash: $query',
          subtitle: '${geohashMatches.length} trees in this area',
          location: firstMatch.position,
        ));
      }
    }

    // Search by coordinates (lat,lng format)
    final coordMatch = RegExp(r'^(-?\d+\.?\d*),\s*(-?\d+\.?\d*)$').firstMatch(query);
    if (coordMatch != null) {
      final lat = double.tryParse(coordMatch.group(1)!);
      final lng = double.tryParse(coordMatch.group(2)!);
      if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        results.add(MapSearchResult(
          type: SearchResultType.location,
          title: 'Location',
          subtitle: '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
          location: LatLng(lat, lng),
        ));
      }
    }

    setState(() {
      _results = results;
      _isSearching = false;
      _showResults = results.isNotEmpty;
    });
  }

  void _selectResult(MapSearchResult result) {
    _searchController.clear();
    setState(() {
      _results = [];
      _showResults = false;
    });
    _focusNode.unfocus();
    widget.onResultSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input
        Container(
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
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.search,
                color: getThemeColors(context)['icon'],
                size: 20,
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search trees, species, or location...',
                    hintStyle: TextStyle(
                      color: getThemeColors(context)['textPrimary']!.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: getThemeColors(context)['textPrimary'],
                    fontSize: 14,
                  ),
                  onChanged: _performSearch,
                  onTap: () {
                    if (_results.isNotEmpty) {
                      setState(() => _showResults = true);
                    }
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: getThemeColors(context)['icon'],
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        getThemeColors(context)['primary']!,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Search results
        if (_showResults && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
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
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return _buildResultItem(context, result);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildResultItem(BuildContext context, MapSearchResult result) {
    IconData icon;
    Color iconColor;

    switch (result.type) {
      case SearchResultType.tree:
        icon = Icons.park;
        iconColor = Colors.green;
        break;
      case SearchResultType.location:
        icon = Icons.location_on;
        iconColor = Colors.red;
        break;
      case SearchResultType.geohash:
        icon = Icons.grid_on;
        iconColor = Colors.blue;
        break;
    }

    return InkWell(
      onTap: () => _selectResult(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: getThemeColors(context)['textPrimary'],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    result.subtitle,
                    style: TextStyle(
                      color: getThemeColors(context)['textPrimary']!.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: getThemeColors(context)['icon']!.withValues(alpha: 0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
