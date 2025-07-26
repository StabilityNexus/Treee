import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String API_KEY = dotenv.get('API_KEY', fallback: "");
String API_SECRET = dotenv.get('API_SECRET', fallback: "");

Future<String?> uploadToIPFS(File imageFile, Function(bool) setUploadingState) async {
  setUploadingState(true);

  var url = Uri.parse("https://api.pinata.cloud/pinning/pinFileToIPFS");
  var request = http.MultipartRequest("POST", url);
  request.headers.addAll({
    "pinata_api_key": API_KEY,
    "pinata_secret_api_key": API_SECRET,
  });

  request.files.add(await http.MultipartFile.fromPath("file", imageFile.path));
  var response = await request.send();

  setUploadingState(false);

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(await response.stream.bytesToString());
    return "https://gateway.pinata.cloud/ipfs/${jsonResponse['IpfsHash']}";
  } else {
    return null;
  }
}
