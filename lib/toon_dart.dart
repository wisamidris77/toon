import 'decode/decoders.dart';
import 'decode/scanner.dart';
import 'encode/encoders.dart';
import 'encode/normalize.dart';
import 'types.dart';

// Export types and options
export 'types.dart' hide DelimiterKey, Delimiter;
export 'constants.dart';

/// Main Toon class providing encoding and decoding functionality.
class Toon {
  /// Encodes an object to Toon format.
  ///
  /// Same as [toonEncode] function.
  static String encode(Object? input, {EncodeOptions? options}) =>
      toonEncode(input, options: options);

  /// Decodes a Toon format string to an object.
  ///
  /// Same as [toonDecode] function.
  static Object? decode(String input, {DecodeOptions? options}) =>
      toonDecode(input, options: options);
}

/// Encodes an object to Toon format.
///
/// Similar to [jsonEncode] but produces Toon format instead of JSON.
///
/// Example:
/// ```dart
/// final data = {'name': 'Alice', 'age': 30};
/// final toon = toonEncode(data);
/// print(toon); // "name: Alice\nage: 30"
/// ```
String toonEncode(Object? input, {EncodeOptions? options}) {
  final resolvedOptions = options ?? const EncodeOptions();
  final normalizedValue = normalizeValue(input);
  return encodeValue(normalizedValue, resolvedOptions);
}

/// Decodes a Toon format string to an object.
///
/// Similar to [jsonDecode] but parses Toon format instead of JSON.
///
/// Example:
/// ```dart
/// final toon = "name: Alice\nage: 30";
/// final data = toonDecode(toon);
/// print(data); // {name: Alice, age: 30}
/// ```
Object? toonDecode(String input, {DecodeOptions? options}) {
  final resolvedOptions = options ?? const DecodeOptions();
  final scanResult =
      toParsedLines(input, resolvedOptions.indent, resolvedOptions.strict);

  if (scanResult.lines.isEmpty) {
    throw FormatException(
        'Cannot decode empty input: input must be a non-empty string');
  }

  final cursor = LineCursor(scanResult.lines, scanResult.blankLines);
  return decodeValueFromLines(cursor, resolvedOptions);
}

/// Convenience function for encoding, same as [toonEncode].
String encode(Object? input, {EncodeOptions? options}) =>
    toonEncode(input, options: options);

/// Convenience function for decoding, same as [toonDecode].
Object? decode(String input, {DecodeOptions? options}) =>
    toonDecode(input, options: options);
