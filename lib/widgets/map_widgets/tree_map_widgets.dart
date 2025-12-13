import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/models/tree_details.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';

class TreeMarkerWidget extends StatelessWidget {
  final Tree tree;
  final VoidCallback onTap;

  const TreeMarkerWidget({
    super.key,
    required this.tree,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDead = tree.death > 0;
    final markerColor = isDead ? Colors.red : Colors.green;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isDead ? Icons.close : Icons.eco,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.my_location,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class MapControlsWidget extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenterUser;
  final VoidCallback onLoadTrees;
  final bool isLoading;
  final bool hasUserLocation;

  const MapControlsWidget({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenterUser,
    required this.onLoadTrees,
    required this.isLoading,
    required this.hasUserLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom controls
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onZoomIn,
                tooltip: 'Zoom In',
              ),
              Container(
                height: 1,
                color: Colors.grey[300],
              ),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: onZoomOut,
                tooltip: 'Zoom Out',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Center on user location
        if (hasUserLocation)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.blue),
              onPressed: onCenterUser,
              tooltip: 'Center on Me',
            ),
          ),
        const SizedBox(height: 8),
        
        // Load trees button
        Container(
          decoration: BoxDecoration(
            color: getThemeColors(context)['primary'],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoading ? null : onLoadTrees,
            tooltip: 'Load Trees in Area',
          ),
        ),
      ],
    );
  }
}

class TreeInfoCard extends StatelessWidget {
  final Tree tree;
  final VoidCallback onViewDetails;
  final VoidCallback onClose;

  const TreeInfoCard({
    super.key,
    required this.tree,
    required this.onViewDetails,
    required this.onClose,
  });

  double _convertCoordinate(int coordinate) {
    return (coordinate / 1000000.0) - 90.0;
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDead = tree.death > 0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDead ? Colors.red[50] : Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isDead ? Icons.close : Icons.eco,
                  color: isDead ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tree.species.isNotEmpty ? tree.species : 'Unknown Species',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDead ? Colors.red[900] : Colors.green[900],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  iconSize: 20,
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.tag,
                  'Tree ID',
                  '#${tree.id}',
                ),
                _buildInfoRow(
                  Icons.location_on,
                  'Location',
                  '${_convertCoordinate(tree.latitude).toStringAsFixed(5)}, '
                      '${_convertCoordinate(tree.longitude).toStringAsFixed(5)}',
                ),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Planted',
                  _formatDate(tree.planting),
                ),
                if (isDead)
                  _buildInfoRow(
                    Icons.event_busy,
                    'Died',
                    _formatDate(tree.death),
                  ),
                _buildInfoRow(
                  Icons.favorite,
                  'Care Count',
                  '${tree.careCount} times',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Full Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getThemeColors(context)['primary'],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
