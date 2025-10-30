import '../constants.dart';
import '../types.dart';
import 'scanner.dart';

/// Asserts that the actual count matches the expected count in strict mode.
///
/// @param actual The actual count
/// @param expected The expected count
/// @param itemType The type of items being counted (e.g., `list array items`, `tabular rows`)
/// @param options Decode options
/// @throws RangeError if counts don't match in strict mode
void assertExpectedCount(
    int actual, int expected, String itemType, ResolvedDecodeOptions options) {
  if (options.strict && actual != expected) {
    throw RangeError('Expected $expected $itemType, but got $actual');
  }
}

/// Validates that there are no extra list items beyond the expected count.
///
/// @param cursor The line cursor
/// @param itemDepth The expected depth of items
/// @param expectedCount The expected number of items
/// @throws RangeError if extra items are found
void validateNoExtraListItems(
    LineCursor cursor, int itemDepth, int expectedCount) {
  if (cursor.atEnd()) {
    return;
  }

  final nextLine = cursor.peek();
  if (nextLine != null &&
      nextLine.depth == itemDepth &&
      nextLine.content.startsWith(listItemPrefix)) {
    throw RangeError(
        'Expected $expectedCount list array items, but found more');
  }
}

/// Validates that there are no extra tabular rows beyond the expected count.
///
/// @param cursor The line cursor
/// @param rowDepth The expected depth of rows
/// @param header The array header info containing length and delimiter
/// @throws RangeError if extra rows are found
void validateNoExtraTabularRows(
    LineCursor cursor, int rowDepth, ArrayHeaderInfo header) {
  if (cursor.atEnd()) {
    return;
  }

  final nextLine = cursor.peek();
  if (nextLine != null &&
      nextLine.depth == rowDepth &&
      !nextLine.content.startsWith(listItemPrefix) &&
      _isDataRow(nextLine.content, header.delimiter)) {
    throw RangeError('Expected ${header.length} tabular rows, but found more');
  }
}

/// Validates that there are no blank lines within a specific line range and depth.
///
/// In strict mode, blank lines inside arrays/tabular rows are not allowed.
///
/// @param startLine The starting line number (inclusive)
/// @param endLine The ending line number (inclusive)
/// @param blankLines Array of blank line information
/// @param strict Whether strict mode is enabled
/// @param context Description of the context (e.g., "list array", "tabular array")
/// @throws SyntaxError if blank lines are found in strict mode
void validateNoBlankLinesInRange(
  int startLine,
  int endLine,
  List<BlankLineInfo> blankLines,
  bool strict,
  String context,
) {
  if (!strict) {
    return;
  }

  // Find blank lines within the range
  // Note: We don't filter by depth because ANY blank line between array items is an error,
  // regardless of its indentation level
  final blanksInRange = blankLines.where(
    (blank) => blank.lineNumber > startLine && blank.lineNumber < endLine,
  );

  if (blanksInRange.isNotEmpty) {
    throw FormatException(
      'Line ${blanksInRange.first.lineNumber}: Blank lines inside $context are not allowed in strict mode',
    );
  }
}

/// Checks if a line represents a data row (as opposed to a key-value pair) in a tabular array.
///
/// @param content The line content
/// @param delimiter The delimiter used in the table
/// @returns true if the line is a data row, false if it's a key-value pair
bool _isDataRow(String content, String delimiter) {
  final colonPos = content.indexOf(colon);
  final delimiterPos = content.indexOf(delimiter);

  // No colon = definitely a data row
  if (colonPos == -1) {
    return true;
  }

  // Has delimiter and it comes before colon = data row
  if (delimiterPos != -1 && delimiterPos < colonPos) {
    return true;
  }

  // Colon before delimiter or no delimiter = key-value pair
  return false;
}
