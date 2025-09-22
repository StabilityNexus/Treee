import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/map_widgets/flutter_map_widget.dart';
import 'package:tree_planting_protocol/utils/services/get_current_location.dart';
import 'package:dart_geohash/dart_geohash.dart';

class MintNftCoordinatesPage extends StatefulWidget {
  const MintNftCoordinatesPage({super.key});

  @override
  State<MintNftCoordinatesPage> createState() => _MintNftCoordinatesPageState();
}

class _MintNftCoordinatesPageState extends State<MintNftCoordinatesPage> {
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  var geoHasher = GeoHasher();

  final LocationService _locationService = LocationService();
  Timer? _locationTimer;
  bool _isLoadingLocation = true;
  String _locationStatus = "Getting current location...";
  bool _userHasManuallySetCoordinates = false;
  bool _isInitialLocationSet = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startLocationUpdates();
    _setupTextFieldListeners();
  }

  void _setupTextFieldListeners() {
    latitudeController.addListener(() {
      if (_isInitialLocationSet && !_isLoadingLocation) {
        _userHasManuallySetCoordinates = true;
      }
    });

    longitudeController.addListener(() {
      if (_isInitialLocationSet && !_isLoadingLocation) {
        _userHasManuallySetCoordinates = true;
      }
    });
  }

  Future<void> _initializeLocation() async {
    await _getCurrentLocation();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_userHasManuallySetCoordinates) {
        _getCurrentLocation();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationInfo locationInfo =
          await _locationService.getCurrentLocationWithTimeout(
        timeout: const Duration(seconds: 10),
      );

      if (mounted && locationInfo.isValid) {
        final provider = Provider.of<MintNftProvider>(context, listen: false);

        setState(() {
          _isLoadingLocation = false;
          _locationStatus = "Location updated";
        });
        provider.setLatitude(locationInfo.latitude!);
        provider.setLongitude(locationInfo.longitude!);
        if (!_userHasManuallySetCoordinates) {
          latitudeController.text = locationInfo.latitude!.toStringAsFixed(6);
          longitudeController.text = locationInfo.longitude!.toStringAsFixed(6);
        }
        if (!_isInitialLocationSet) {
          _isInitialLocationSet = true;
        }
      }
    } on LocationException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatus = "Location error: ${e.message}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatus = "Failed to get location: $e";
        });
      }
    }
  }

  void _onMapLocationSelected(double lat, double lng) {
    setState(() {
      _userHasManuallySetCoordinates = true;
      latitudeController.text = lat.toStringAsFixed(6);
      longitudeController.text = lng.toStringAsFixed(6);
    });
  }

  void submitCoordinates() {
    final latitude = latitudeController.text;
    final longitude = longitudeController.text;

    if (latitude.isEmpty || longitude.isEmpty) {
      _showCustomSnackBar(
        "Please enter both latitude and longitude.",
        isError: true,
      );
      return;
    }

    try {
      final lat = double.parse(latitude);
      final lng = double.parse(longitude);
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        _showCustomSnackBar(
          "Please enter valid coordinates. Latitude: -90 to 90, Longitude: -180 to 180",
          isError: true,
        );
        return;
      }

      String geohash;
      try {
        logger.d("About to generate geohash for: lat=$lat, lng=$lng");
        geohash = geoHasher.encode(lat, lng, precision: 12);
        logger.d("Generated geohash: $geohash");
      } catch (geohashError) {
        logger.d("Geohash error: $geohashError");
        _showCustomSnackBar(
          "Error generating location code: $geohashError",
          isError: true,
        );
        return;
      }

      Provider.of<MintNftProvider>(context, listen: false).setLatitude(lat);
      Provider.of<MintNftProvider>(context, listen: false).setLongitude(lng);
      Provider.of<MintNftProvider>(context, listen: false).setGeoHash(geohash);

      latitudeController.clear();
      longitudeController.clear();

      _showCustomSnackBar("Coordinates submitted successfully!");
      context.push(RouteConstants.mintNftDetailsPath);
    } catch (e) {
      _showCustomSnackBar(
        "Please enter valid numeric coordinates. $latitude",
        isError: true,
      );
    }
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = "Refreshing location...";
      _userHasManuallySetCoordinates = false;
    });
    await _getCurrentLocation();
  }

  void _useCurrentLocation() {
    setState(() {
      _userHasManuallySetCoordinates = false;
      _isLoadingLocation = true;
      _locationStatus = "Getting current location...";
    });
    _getCurrentLocation();
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: getThemeColors(context)['primary'],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? Colors.red.shade400 : const Color(0xFF1CD381),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      title: "Mint NFT Coordinates",
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 20,
        ),
        child: Column(
          children: [
            _buildFormSection(screenWidth, screenHeight, context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(
      double screenWidth, double screenHeight, BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: screenWidth * 0.92),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: getThemeColors(context)['primary'],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tree Location',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: getThemeColors(context)['primary'],
                        ),
                      ),
                      Text(
                        'Mark where your tree is planted',
                        style: TextStyle(
                          fontSize: 14,
                          color: getThemeColors(context)['textPrimary'],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildMapSection(screenHeight),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryYellowColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getThemeColors(context)['secondary']!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: getThemeColors(context)['primary'],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap on the map or enter coordinates manually below',
                          style: TextStyle(
                            fontSize: 14,
                            color: getThemeColors(context)['textPrimary'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildCoordinateField(
                        controller: latitudeController,
                        label: 'Latitude',
                        icon: Icons.straighten,
                        hint: '-90 to 90',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCoordinateField(
                        controller: longitudeController,
                        label: 'Longitude',
                        icon: Icons.straighten,
                        hint: '-180 to 180',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: submitCoordinates,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getThemeColors(context)['primary'],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            color: getThemeColors(context)['textPrimary'],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: getThemeColors(context)['primary'],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 18,
                          ),
                        ),
                      ],
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

  // ignore: unused_element
  Widget _buildLocationStatus() {
    final isManual = _userHasManuallySetCoordinates;
    final isLoading = _isLoadingLocation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLoading ? primaryYellowColor : primaryGreenColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLoading
                  ? Colors.orange
                  : (isManual
                      ? const Color(0xFFFAEB96)
                      : const Color(0xFF1CD381)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isManual ? Icons.edit_location : Icons.my_location,
                    size: 20,
                    color: isManual
                        ? const Color(0xFFFAEB96)
                        : const Color(0xFF1CD381),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isManual ? "Manual Coordinates" : _locationStatus,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isLoading
                        ? Colors.orange.shade700
                        : (isManual
                            ? Colors.orange.shade700
                            : const Color(0xFF1CD381)),
                  ),
                ),
                if (isManual)
                  const Text(
                    "Using your entered coordinates",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _refreshLocation,
                icon: const Icon(Icons.refresh, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: getThemeColors(context)['background'],
                  foregroundColor: const Color(0xFF1CD381),
                ),
              ),
              if (isManual) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text("Auto"),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1CD381),
                    backgroundColor: const Color(0xFF1CD381),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(double screenHeight) {
    final mapHeight = (screenHeight * 0.35).clamp(250.0, 350.0);

    return Container(
      height: mapHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CoordinatesMap(
        onLocationSelected: _onMapLocationSelected,
        lat: Provider.of<MintNftProvider>(context).getLatitude().toDouble(),
        lng: Provider.of<MintNftProvider>(context).getLongitude().toDouble(),
      ),
    );
  }

  Widget _buildCoordinateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1CD381),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: getThemeColors(context)['textPrimary'],
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1CD381),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: getThemeColors(context)['secondary']!,
              width: 2,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.transparent,
            ),
            onTap: () {
              _userHasManuallySetCoordinates = true;
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }
}
