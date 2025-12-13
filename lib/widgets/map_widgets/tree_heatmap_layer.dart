import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tree_planting_protocol/services/tree_map_service.dart';

/// Custom heatmap layer for visualizing tree density on flutter_map
/// Uses gradient circles to show concentration of trees
class TreeHeatmapLayer extends StatelessWidget {
  final List<MapTreeData> trees;
  final MapCamera camera;
  final double opacity;
  final double baseRadius;

  const TreeHeatmapLayer({
    super.key,
    required this.trees,
    required this.camera,
    this.opacity = 0.5,
    this.baseRadius = 30,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show heatmap at high zoom levels (show individual markers instead)
    if (trees.isEmpty || camera.zoom > 14) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _HeatmapPainter(
        trees: trees,
        camera: camera,
        opacity: opacity,
        radius: _getRadiusForZoom(camera.zoom),
      ),
      size: Size.infinite,
    );
  }

  double _getRadiusForZoom(double zoom) {
    // Adjust radius based on zoom level for better visualization
    if (zoom < 6) return baseRadius * 0.5;
    if (zoom < 8) return baseRadius * 0.7;
    if (zoom < 10) return baseRadius * 0.85;
    if (zoom < 12) return baseRadius;
    return baseRadius * 1.3;
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<MapTreeData> trees;
  final MapCamera camera;
  final double opacity;
  final double radius;

  _HeatmapPainter({
    required this.trees,
    required this.camera,
    required this.opacity,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trees.isEmpty) return;

    // Create a list of screen points for all trees
    final points = <Offset>[];
    for (final tree in trees) {
      final screenPoint = camera.latLngToScreenPoint(tree.position);
      // Only include points that are within or near the visible area
      if (screenPoint.x >= -radius &&
          screenPoint.x <= size.width + radius &&
          screenPoint.y >= -radius &&
          screenPoint.y <= size.height + radius) {
        points.add(Offset(screenPoint.x, screenPoint.y));
      }
    }

    if (points.isEmpty) return;

    // Draw gradient circles at each tree location
    for (final point in points) {
      _drawHeatPoint(canvas, point);
    }
  }

  void _drawHeatPoint(Canvas canvas, Offset center) {
    // Create a radial gradient for the heat point
    final gradient = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.green.withValues(alpha: opacity * 0.8),
        Colors.green.withValues(alpha: opacity * 0.4),
        Colors.green.withValues(alpha: opacity * 0.1),
        Colors.transparent,
      ],
      [0.0, 0.3, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.plus; // Additive blending for overlapping areas

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return trees.length != oldDelegate.trees.length ||
        camera.zoom != oldDelegate.camera.zoom ||
        camera.center != oldDelegate.camera.center ||
        opacity != oldDelegate.opacity ||
        radius != oldDelegate.radius;
  }
}

/// Widget that shows tree density as colored regions on the map
/// This is an alternative to the heatmap that uses discrete clusters
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
        boxShadow: const [
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
