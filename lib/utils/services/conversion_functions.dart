int toInt(dynamic value) {
  if (value is BigInt) return value.toInt();
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}
