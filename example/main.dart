import 'package:toon_dart/toon_dart.dart';

void main() {
  final toon = Toon();
  final encoded = toon.encode({'hello': 'world'});
  print('Encoded: $encoded');
  final decoded = toon.decode(encoded);
  print('Decoded: $decoded');
}