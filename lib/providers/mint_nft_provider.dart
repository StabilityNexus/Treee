import 'package:flutter/material.dart';

class MintNftProvider extends ChangeNotifier {
  double _latitude = 0;
  double _longitude = 0;
  String _species = "";
  String _description = "";
  String _imageUri = "";
  String _qrIpfsHash = "";
  String _geoHash = "";
  List<String> _initialPhotos = [];

  double getLatitude() => _latitude;
  double getLongitude() => _longitude;
  String getSpecies() => _species;
  String getImageUri() => _imageUri;
  String getQrIpfsHash() => _qrIpfsHash;
  String getGeoHash() => _geoHash;
  String getDescription() => _description;
  List<String> getInitialPhotos() => _initialPhotos;

  void setLatitude(double latitude) {
    _latitude = latitude;
    notifyListeners();
  }
  void setLongitude(double longitude) {
    _longitude = longitude;
    notifyListeners();
  }

  void setSpecies(String species) {
    _species = species;
    notifyListeners();
  }

  void setDescription(String description) {
    _description = description;
    notifyListeners();
  }

  void setImageUri(String imageUri) {
    _imageUri = imageUri;
    notifyListeners();
  }
  void setQrIpfsHash(String qrIpfsHash) {
    _qrIpfsHash = qrIpfsHash;
    notifyListeners();
  }
  void setGeoHash(String geoHash) {
    _geoHash = geoHash;
    notifyListeners();
  }
  void setInitialPhotos(List<String> initialPhotos) {
    _initialPhotos = initialPhotos;
    notifyListeners();
  }
  void clearData() {
    _latitude = 0;
    _longitude = 0;
    _species = "";
    _imageUri = "";
    _qrIpfsHash = "";
    _geoHash = "";
    _initialPhotos.clear();
    notifyListeners();
  }
}
