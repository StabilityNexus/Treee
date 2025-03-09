import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import '../services/treee_functions.dart';

String API_KEY = dotenv.get('API_KEY', fallback: "");
String API_SECRET = dotenv.get('API_SECRET', fallback: "");

class MintTreeNFTPage extends StatefulWidget {
  final Web3Client ethClient;

  MintTreeNFTPage({required this.ethClient});

  @override
  _MintTreeNFTPageState createState() => _MintTreeNFTPageState();
}

class _MintTreeNFTPageState extends State<MintTreeNFTPage> {
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  File? _image;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadToIPFS(File imageFile) async {
    setState(() {
      _isUploading = true;
    });

    var url = Uri.parse("https://api.pinata.cloud/pinning/pinFileToIPFS");
    var request = http.MultipartRequest("POST", url);
    request.headers.addAll({
      "pinata_api_key": API_KEY,
      "pinata_secret_api_key": API_SECRET,
    });

    request.files
        .add(await http.MultipartFile.fromPath("file", imageFile.path));
    var response = await request.send();

    setState(() {
      _isUploading = false;
    });

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(await response.stream.bytesToString());
      return "https://gateway.pinata.cloud/ipfs/${jsonResponse['IpfsHash']}";
    } else {
      return null;
    }
  }

  Future<void> _mintNFT() async {
    if (_image == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please select an image")));
      return;
    }

    String? imageUrl = await _uploadToIPFS(_image!);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Image upload failed")));
      return;
    }

    int latitude = int.tryParse(_latitudeController.text) ?? 0;
    int longitude = int.tryParse(_longitudeController.text) ?? 0;
    String species = _speciesController.text;

    try {
      await mintTreeNFT(
          latitude, longitude, species, imageUrl, widget.ethClient);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tree NFT Minted Successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Minting failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mint Tree NFT", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Tree Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    _buildTextField(_latitudeController, "Latitude", TextInputType.number),
                    _buildTextField(_longitudeController, "Longitude", TextInputType.number),
                    _buildTextField(_speciesController, "Species", TextInputType.text),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            _image == null
                ? Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text("No Image Selected")),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, height: 150, fit: BoxFit.cover),
                  ),
            SizedBox(height: 20),
            _buildButton("Pick Image", Icons.image, _pickImage, Colors.blueAccent),
            SizedBox(height: 10),
            _isUploading
                ? CircularProgressIndicator()
                : _buildButton("Mint NFT", Icons.token, _mintNFT, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType keyboardType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onPressed, Color color) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: color,
        elevation: 4,
      ),
    );
  }
}
