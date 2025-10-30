import '../constants.dart';
import '../types.dart';

/// Result of scanning source text into parsed lines
class ScanResult {
  final List<ParsedLine> lines;
  final List<BlankLineInfo> blankLines;

  const ScanResult({
    required this.lines,
    required this.blankLines,
  });
}

/// Cursor for navigating through parsed lines
class LineCursor {
  final List<ParsedLine> lines;
  int index;
  final List<BlankLineInfo> blankLines;

  LineCursor(this.lines, this.blankLines) : index = 0;

  List<BlankLineInfo> getBlankLines() => blankLines;

  ParsedLine? peek() => index < lines.length ? lines[index] : null;

  ParsedLine? next() => index < lines.length ? lines[index++] : null;

  ParsedLine? current() => index > 0 ? lines[index - 1] : null;

  void advance() => index++;

  bool atEnd() => index >= lines.length;

  int get length => lines.length;

  ParsedLine? peekAtDepth(int targetDepth) {
    final line = peek();
    if (line == null || line.depth < targetDepth) {
      return null;
    }
    if (line.depth == targetDepth) {
      return line;
    }
    return null;
  }

  bool hasMoreAtDepth(int targetDepth) => peekAtDepth(targetDepth) != null;
}

/// Converts source text to parsed lines
ScanResult toParsedLines(String source, int indentSize, bool strict) {
  if (source.trim().isEmpty) {
    return const ScanResult(lines: [], blankLines: []);
  }

  final rawLines = source.split('\n');
  final parsed = <ParsedLine>[];
  final blankLines = <BlankLineInfo>[];

  for (int i = 0; i < rawLines.length; i++) {
    final raw = rawLines[i];
    final lineNumber = i + 1;
    int indent = 0;
    while (indent < raw.length && raw[indent] == space) {
      indent++;
    }

    final content = raw.substring(indent);

    // Track blank lines
    if (content.trim().isEmpty) {
      final depth = _computeDepthFromIndent(indent, indentSize);
      blankLines.add(BlankLineInfo(
        lineNumber: lineNumber,
        indent: indent,
        depth: depth,
      ));
      continue;
    }

    final depth = _computeDepthFromIndent(indent, indentSize);

    // Strict mode validation
    if (strict) {
      // Find the full leading whitespace region (spaces and tabs)
      int wsEnd = 0;
      while (wsEnd < raw.length && (raw[wsEnd] == space || raw[wsEnd] == tab)) {
        wsEnd++;
      }

      // Check for tabs in leading whitespace (before actual content)
      if (raw.substring(0, wsEnd).contains(tab)) {
        throw FormatException(
            'Line $lineNumber: Tabs are not allowed in indentation in strict mode');
      }

      // Check for exact multiples of indentSize
      if (indent > 0 && indent % indentSize != 0) {
        throw FormatException(
            'Line $lineNumber: Indentation must be exact multiple of $indentSize, but found $indent spaces');
      }
    }

    parsed.add(ParsedLine(
      raw: raw,
      indent: indent,
      content: content,
      depth: depth,
      lineNumber: lineNumber,
    ));
  }

  return ScanResult(lines: parsed, blankLines: blankLines);
}

int _computeDepthFromIndent(int indentSpaces, int indentSize) {
  return indentSpaces ~/ indentSize;
}
