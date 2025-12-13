import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String apiToken = dotenv.get('WEB3_STORAGE_TOKEN', fallback: "");

Future<String?> uploadToIPFS(
    File imageFile, Function(bool) setUploadingState) async {
  setUploadingState(true);

  var url = Uri.parse("https://api.web3.storage/upload");
  var request = http.MultipartRequest("POST", url);
  request.headers.addAll({
    "Authorization": "Bearer $apiToken",
  });

  request.files.add(await http.MultipartFile.fromPath("file", imageFile.path));
  var response = await request.send();

  setUploadingState(false);

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(await response.stream.bytesToString());
    // Web3.Storage returns a CID in the response
    String cid = jsonResponse['cid'];
    return "https://w3s.link/ipfs/$cid";
  } else {
    return null;
  }
}
