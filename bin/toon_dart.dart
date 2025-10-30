import 'dart:convert';
import 'dart:io';
import 'package:toon_dart/toon_dart.dart' as toon;

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Usage: toon <command> [file]');
    print('Commands:');
    print('  encode - Encode JSON from stdin to Toon format');
    print('  decode - Decode Toon format from stdin to JSON');
    print('  <file> - Process file (auto-detect format)');
    exit(1);
  }

  final command = arguments[0];

  try {
    if (command == 'encode') {
      final input = stdin.readLineSync();
      if (input == null) {
        print('Error: No input provided');
        exit(1);
      }
      final data = jsonDecode(input);
      final result = toon.toonEncode(data);
      print(result);
    } else if (command == 'decode') {
      final input = stdin.readLineSync();
      if (input == null) {
        print('Error: No input provided');
        exit(1);
      }
      final data = toon.toonDecode(input);
      final result = jsonEncode(data);
      print(result);
    } else {
      // Assume it's a file path
      final file = File(command);
      if (!file.existsSync()) {
        print('Error: File not found: $command');
        exit(1);
      }

      final content = file.readAsStringSync();

      // Try to detect format
      try {
        // Try parsing as JSON first
        final data = jsonDecode(content);
        final result = toon.toonEncode(data);
        print(result);
      } catch (_) {
        // If JSON parsing fails, try parsing as Toon
        try {
          final data = toon.toonDecode(content);
          final result = jsonEncode(data);
          print(result);
        } catch (e) {
          print('Error: Could not parse file as JSON or Toon format');
          exit(1);
        }
      }
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
