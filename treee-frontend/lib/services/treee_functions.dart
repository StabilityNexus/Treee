import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:treee/utils/constants.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String owner_private_key = dotenv.get('OWNER_PRIVATE_KEY', fallback: "");
String API_SECRET = dotenv.get('API_SECRET', fallback: "");
Future<DeployedContract> loadContract() async {
  String abi = await rootBundle.loadString("assets/abi.json");
  String contractAddress = CONTRACT_ADDRESS;
  final contract = DeployedContract(ContractAbi.fromJson(abi, "TreeNft"),
      EthereumAddress.fromHex(contractAddress));
  return contract;
}

Future<String> callFunction(String funcName, List<dynamic> args,
    Web3Client ethClient, String privateKey) async {
  EthPrivateKey credentials = EthPrivateKey.fromHex(privateKey);
  DeployedContract contract = await loadContract();
  final ethFunction = contract.function(funcName);
  final result = await ethClient.sendTransaction(
    credentials,
    Transaction.callContract(
      contract: contract,
      function: ethFunction,
      parameters: args,
    ),
    chainId: null,
    fetchChainIdFromNetworkId: true,
  );
  return result;
}

Future<String> mintTreeNFT(int latitude, int longitude, String species,
    String imageUri, Web3Client ethClient) async {
  var response = await callFunction(
      "mintNft",
      [BigInt.from(latitude), BigInt.from(longitude), species, imageUri],
      ethClient,
      owner_private_key);
  print("Tree NFT minted successfully");
  return response;
}

Future<String> markTreeAsDead(int tokenId, Web3Client ethClient) async {
  var response = await callFunction(
      "markDead", [BigInt.from(tokenId)], ethClient, owner_private_key);
  print("Tree marked as dead successfully");
  return response;
}

Future<String> verifyTree(
    int tokenId, Web3Client ethClient, String verifierPrivateKey) async {
  var response = await callFunction(
      "verify", [BigInt.from(tokenId)], ethClient, owner_private_key);
  print("Tree verified successfully");
  return response;
}

Future<bool> isTreeVerified(
    int tokenId, String verifierAddress, Web3Client ethClient) async {
  List<dynamic> result = await ask(
      "isVerified",
      [BigInt.from(tokenId), EthereumAddress.fromHex(verifierAddress)],
      ethClient);
  return result[0] as bool;
}

Future<String> getTokenURI(int tokenId, Web3Client ethClient) async {
  List<dynamic> result =
      await ask("tokenURI", [BigInt.from(tokenId)], ethClient);
  return result[0] as String;
}

Future<List<Map<String, dynamic>>> getAllNFTs(Web3Client ethClient) async {
  try {
    List<dynamic> result = await ask("getAllNFTs", [], ethClient);
    print("Raw result: $result"); // Debugging

    if (result.isEmpty || result[0] is! List) {
      print("Unexpected result format");
      return [];
    }

    List<dynamic> nftDataList = result[0]; // Extract inner list
    List<Map<String, dynamic>> nftList = [];

    for (var item in nftDataList) {
      try {
        String sanitizedJson =
            item.toString().replaceAll('\n', '').trim(); // Remove newlines
        if (!sanitizedJson.endsWith("}")) {
          sanitizedJson += "}"; // Ensure it closes properly
        }
        // print("Sanitized JSON: $sanitizedJson");

        Map<String, dynamic> nft = json.decode(sanitizedJson);
        nftList.add(nft);
      } catch (e) {
        // print("JSON decoding error for item: $item - Error: $e");
      }
    }

    // print("Parsed NFTs: $nftList");
    return nftList;
  } catch (e) {
    // print("Error fetching NFTs: $e");
    return [];
  }
}

Future<List<Map<String, dynamic>>> getUsersNFTs(
    Web3Client ethClient, String address) async {
  List<dynamic> result =
      await ask("getNFTsByUser", [EthereumAddress.fromHex(address)], ethClient);
  List<Map<String, dynamic>> nftList = [];

  for (String jsonString in result[0]) {
    Map<String, dynamic> nftData = json.decode(jsonString);
    nftList.add(nftData);
  }
  return nftList;
}

Future<List<dynamic>> ask(
    String funcName, List<dynamic> args, Web3Client ethClient) async {
  print("args: $args");
  print("funcname: $funcName");
  final contract = await loadContract();
  final ethFunction = contract.function(funcName);
  final result = await ethClient.call(
    contract: contract,
    function: ethFunction,
    params: args,
  );
  return result;
}
