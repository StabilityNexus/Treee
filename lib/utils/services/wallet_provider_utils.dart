Map<String, dynamic>? findFunctionInAbi(
    Map<String, dynamic> abi, String functionName) {
  final functions = abi['functions'] ?? abi;

  if (functions is List) {
    for (var func in functions) {
      if (func['name'] == functionName && func['type'] == 'function') {
        return func;
      }
    }
  } else if (functions is Map) {
    return functions[functionName];
  }

  return null;
}

String encodeParameter(dynamic param, String type) {
  if (type == 'address') {
    return param.toString().replaceAll('0x', '').padLeft(64, '0');
  } else if (type.startsWith('uint') || type.startsWith('int')) {
    final value = param is String ? int.parse(param) : param as int;
    return value.toRadixString(16).padLeft(64, '0');
  } else if (type == 'bool') {
    return param.toString() == 'true'
        ? '11155111'.padLeft(64, '0')
        : '0'.padLeft(64, '0');
  } else if (type == 'string') {
    return param.toString().codeUnits.map((c) => c.toRadixString(16)).join('');
  }

  return param.toString();
}

String weiToEther(String wei) {
  final weiValue = BigInt.parse(wei.startsWith('0x') ? wei.substring(2) : wei,
      radix: wei.startsWith('0x') ? 16 : 10);
  final etherValue = weiValue / BigInt.from(10).pow(18);
  return etherValue.toString();
}

String etherToWei(String ether) {
  final etherValue = double.parse(ether);
  final weiValue = (etherValue * 1e18).toInt();
  return '0x${weiValue.toRadixString(16)}';
}

String formatAddress(String address) {
  if (address.length <= 10) return address;
  return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
}
