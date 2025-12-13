import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tree_planting_protocol/services/tree_map_service.dart';

/// Custom heatmap layer for visualizing tree density
class TreeHeatmapLayer extends StatelessWidget {
  final List<MapTreeData> trees;
  final double zoom;
  final double opacity;
  final double radius;

  const TreeHeatmapLayer({
    super.key,
    required this.trees,
    required this.zoom,
    this.opacity = 0.6,
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (trees.isEmpty || zoom > 14) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _HeatmapPainter(
        trees: trees,
        opacity: opacity,
        radius: _getRadiusForZoom(zoom),
      ),
      size: Size.infinite,
    );
  }

  double _getRadiusForZoom(double zoom) {
    // Adjust radius based on zoom level
    if (zoom < 6) return 15;
    if (zoom < 8) return 20;
    if (zoom < 10) return 25;
    if (zoom < 12) return 30;
    return 40;
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<MapTreeData> trees;
  final double opacity;
  final double radius;

  _HeatmapPainter({
    required this.trees,
    required this.opacity,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // This is a simplified heatmap - in production you'd use proper heatmap algorithms
    // For now, we'll draw gradient circles at tree locations
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return trees != oldDelegate.trees ||
           opacity != oldDelegate.opacity ||
           radius != oldDelegate.radius;
  }
}

/// Widget that shows tree density as colored regions on the map
class TreeDensityOverlay extends StatelessWidget {
  final List<TreeCluster> clusters;
  final MapCamera camera;

  const TreeDensityOverlay({
    super.key,
    required this.clusters,
    required this.camera,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: clusters.map((cluster) {
        if (cluster.count < 3) return const SizedBox.shrink();
        
        final point = camera.latLngToScreenPoint(cluster.center);
        final intensity = (cluster.totalTreeCount / 100).clamp(0.2, 1.0);
        final size = 40 + (cluster.totalTreeCount * 2).clamp(0, 60).toDouble();

        return Positioned(
          left: point.x - size / 2,
          top: point.y - size / 2,
          child: IgnorePointer(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _getColorForIntensity(intensity).withValues(alpha: 0.4),
                    _getColorForIntensity(intensity).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForIntensity(double intensity) {
    if (intensity > 0.7) return Colors.red;
    if (intensity > 0.4) return Colors.orange;
    return Colors.green;
  }
}

/// Legend widget for the heatmap
class TreeDensityLegend extends StatelessWidget {
  const TreeDensityLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tree Density',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(Colors.green, 'Low'),
          _buildLegendItem(Colors.orange, 'Medium'),
          _buildLegendItem(Colors.red, 'High'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
