import 'package:toon_dart/toon_dart.dart';

void main() {
  final encoded = toonEncode({'hello': 'world'});
  print('Encoded: $encoded');
  final decoded = toonDecode(encoded);
  print('Decoded: $decoded');
}