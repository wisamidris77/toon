import '../constants.dart';
import '../shared/literal-utils.dart';
import '../shared/string-utils.dart';
import '../types.dart';

/// Parses an array header line
({ArrayHeaderInfo header, String? inlineValues})? parseArrayHeaderLine(
    String content, String defaultDelimiter) {
  // Don't match if the line starts with a quote (it's a quoted key, not an array)
  if (content.trim().startsWith(doubleQuote)) {
    return null;
  }

  // Find the bracket segment first
  final bracketStart = content.indexOf(openBracket);
  if (bracketStart == -1) {
    return null;
  }

  final bracketEnd = content.indexOf(closeBracket, bracketStart);
  if (bracketEnd == -1) {
    return null;
  }

  // Find the colon that comes after all brackets and braces
  int colonIndex = bracketEnd + 1;
  int braceEnd = colonIndex;

  // Check for fields segment (braces come after bracket)
  final braceStart = content.indexOf(openBrace, bracketEnd);
  if (braceStart != -1 && braceStart < content.indexOf(colon, bracketEnd)) {
    final foundBraceEnd = content.indexOf(closeBrace, braceStart);
    if (foundBraceEnd != -1) {
      braceEnd = foundBraceEnd + 1;
    }
  }

  // Now find colon after brackets and braces
  colonIndex = content.indexOf(colon, braceEnd.clamp(0, content.length));
  if (colonIndex == -1) {
    return null;
  }

  final key = bracketStart > 0 ? content.substring(0, bracketStart) : null;
  final afterColon = content.substring(colonIndex + 1).trim();

  final bracketContent = content.substring(bracketStart + 1, bracketEnd);

  // Try to parse bracket segment
  final parsedBracket = _parseBracketSegment(bracketContent, defaultDelimiter);

  final length = parsedBracket.length;
  final delimiter = parsedBracket.delimiter;
  final hasLengthMarker = parsedBracket.hasLengthMarker;

  // Check for fields segment
  List<String>? fields;
  if (braceStart != -1 && braceStart < colonIndex) {
    final foundBraceEnd = content.indexOf(closeBrace, braceStart);
    if (foundBraceEnd != -1 && foundBraceEnd < colonIndex) {
      final fieldsContent = content.substring(braceStart + 1, foundBraceEnd);
      fields = parseDelimitedValues(fieldsContent, delimiter)
          .map(_parseStringLiteral)
          .toList();
    }
  }

  return (
    header: ArrayHeaderInfo(
      key: key,
      length: length,
      delimiter: delimiter,
      fields: fields,
      hasLengthMarker: hasLengthMarker,
    ),
    inlineValues: afterColon.isNotEmpty ? afterColon : null,
  );
}

/// Parses a bracket segment like "[#N,t]" or "[3]"
({int length, String delimiter, bool hasLengthMarker}) _parseBracketSegment(
    String seg, String defaultDelimiter) {
  bool hasLengthMarker = false;
  String content = seg;

  // Check for length marker
  if (content.startsWith(hash)) {
    hasLengthMarker = true;
    content = content.substring(1);
  }

  // Check for delimiter suffix
  String delimiter = defaultDelimiter;
  if (content.endsWith(tab)) {
    delimiter = delimiters['tab']!;
    content = content.substring(0, content.length - 1);
  } else if (content.endsWith(pipe)) {
    delimiter = delimiters['pipe']!;
    content = content.substring(0, content.length - 1);
  }

  final length = int.tryParse(content);
  if (length == null) {
    throw FormatException('Invalid array length: $seg');
  }

  return (
    length: length,
    delimiter: delimiter,
    hasLengthMarker: hasLengthMarker
  );
}

/// Parses comma/tab/pipe separated values
List<String> parseDelimitedValues(String input, String delimiter) {
  final values = <String>[];
  String current = '';
  bool inQuotes = false;
  int i = 0;

  while (i < input.length) {
    final char = input[i];

    if (char == backslash && i + 1 < input.length && inQuotes) {
      // Escape sequence in quoted string
      current += char + input[i + 1];
      i += 2;
      continue;
    }

    if (char == doubleQuote) {
      inQuotes = !inQuotes;
      current += char;
      i++;
      continue;
    }

    if (char == delimiter && !inQuotes) {
      values.add(current.trim());
      current = '';
      i++;
      continue;
    }

    current += char;
    i++;
  }

  // Add last value
  if (current.isNotEmpty || values.isNotEmpty) {
    values.add(current.trim());
  }

  return values;
}

/// Maps parsed values to primitives
List<Object?> mapRowValuesToPrimitives(List<String> values) {
  return values.map(parsePrimitiveToken).toList();
}

/// Parses a primitive token
Object? parsePrimitiveToken(String token) {
  final trimmed = token.trim();

  // Empty token
  if (trimmed.isEmpty) {
    return '';
  }

  // Quoted string (if starts with quote, it MUST be properly quoted)
  if (trimmed.startsWith(doubleQuote)) {
    return _parseStringLiteral(trimmed);
  }

  // Boolean or null literals
  if (isBooleanOrNullLiteral(trimmed)) {
    if (trimmed == trueLiteral) return true;
    if (trimmed == falseLiteral) return false;
    if (trimmed == nullLiteral) return null;
  }

  // Numeric literal
  if (isNumericLiteral(trimmed)) {
    return num.parse(trimmed);
  }

  // Unquoted string
  return trimmed;
}

/// Parses a quoted string literal
String _parseStringLiteral(String token) {
  final trimmed = token.trim();

  if (trimmed.startsWith(doubleQuote)) {
    // Find the closing quote, accounting for escaped quotes
    final closingQuoteIndex = findClosingQuote(trimmed, 0);

    if (closingQuoteIndex == -1) {
      // No closing quote was found
      throw FormatException('Unterminated string: missing closing quote');
    }

    if (closingQuoteIndex != trimmed.length - 1) {
      throw FormatException('Unexpected characters after closing quote');
    }

    final content = trimmed.substring(1, closingQuoteIndex);
    return unescapeString(content);
  }

  return trimmed;
}

/// Parses an unquoted key
({String key, int end}) _parseUnquotedKey(String content, int start) {
  int end = start;
  while (end < content.length && content[end] != colon) {
    end++;
  }

  // Validate that a colon was found
  if (end >= content.length || content[end] != colon) {
    throw FormatException('Missing colon after key');
  }

  final key = content.substring(start, end).trim();

  // Skip the colon
  end++;

  return (key: key, end: end);
}

/// Parses a quoted key
({String key, int end}) _parseQuotedKey(String content, int start) {
  // Find the closing quote, accounting for escaped quotes
  final closingQuoteIndex = findClosingQuote(content, start);

  if (closingQuoteIndex == -1) {
    throw FormatException('Unterminated quoted key');
  }

  // Extract and unescape the key content
  final keyContent = content.substring(start + 1, closingQuoteIndex);
  final key = unescapeString(keyContent);
  int end = closingQuoteIndex + 1;

  // Validate and skip colon after quoted key
  if (end >= content.length || content[end] != colon) {
    throw FormatException('Missing colon after key');
  }
  end++;

  return (key: key, end: end);
}

/// Parses a key token (quoted or unquoted)
({String key, int end}) parseKeyToken(String content, int start) {
  if (content[start] == doubleQuote) {
    return _parseQuotedKey(content, start);
  } else {
    return _parseUnquotedKey(content, start);
  }
}

/// Checks if content represents an array header after a hyphen
bool isArrayHeaderAfterHyphen(String content) {
  return content.trim().startsWith(openBracket) &&
      findUnquotedChar(content, colon) != -1;
}

/// Checks if content represents an object first field after a hyphen
bool isObjectFirstFieldAfterHyphen(String content) {
  return findUnquotedChar(content, colon) != -1;
}
