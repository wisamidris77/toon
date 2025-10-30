import '../constants.dart';
import '../shared/string-utils.dart';
import '../shared/validation.dart';

/// Encodes a primitive value to its string representation
String encodePrimitive(Object? value, String delimiter) {
  if (value == null) {
    return NULL_LITERAL;
  }

  if (value is bool) {
    return value.toString();
  }

  if (value is num) {
    // Handle integer values to avoid .0 suffix
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    // For very large numbers, check if they are actually integers
    final str = value.toString();
    if (str.endsWith('.0')) {
      return str.substring(0, str.length - 2);
    }
    return str;
  }

  return encodeStringLiteral(value as String, delimiter);
}

/// Encodes a string literal, quoting if necessary
String encodeStringLiteral(String value, String delimiter) {
  if (isSafeUnquoted(value, delimiter)) {
    return value;
  }

  return '${DOUBLE_QUOTE}${escapeString(value)}${DOUBLE_QUOTE}';
}

// #endregion

// #region Key encoding

/// Encodes an object key, quoting if necessary
String encodeKey(String key) {
  if (isValidUnquotedKey(key)) {
    return key;
  }

  return '${DOUBLE_QUOTE}${escapeString(key)}${DOUBLE_QUOTE}';
}

// #endregion

// #region Value joining

/// Joins primitive values with a delimiter
String encodeAndJoinPrimitives(List<Object?> values, String delimiter) {
  return values.map((v) => encodePrimitive(v, delimiter)).join(delimiter);
}

// #endregion

// #region Header formatters

/// Formats an array header string
String formatHeader(
  int length, {
  String? key,
  List<String>? fields,
  String? delimiter,
  String? lengthMarker,
}) {
  final String actualDelimiter = delimiter ?? COMMA;
  final String actualLengthMarker = lengthMarker ?? '';

  String header = '';

  if (key != null) {
    header += encodeKey(key);
  }

  // Only include delimiter if it's not the default (comma)
  header += '[${actualLengthMarker}${length}${actualDelimiter != DEFAULT_DELIMITER ? actualDelimiter : ''}]';

  if (fields != null) {
    final quotedFields = fields.map(encodeKey);
    header += '{${quotedFields.join(actualDelimiter)}}';
  }

  header += ':';

  return header;
}

// #endregion
