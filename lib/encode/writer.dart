import '../constants.dart';

/// A writer that builds formatted text with proper indentation
class LineWriter {
  final List<String> _lines = [];
  final String _indentationString;

  LineWriter(int indentSize) : _indentationString = ' ' * indentSize;

  /// Adds a line at the specified depth
  void push(int depth, String content) {
    final indent = _indentationString * depth;
    _lines.add(indent + content);
  }

  /// Adds a list item line at the specified depth
  void pushListItem(int depth, String content) {
    push(depth, '${listItemPrefix}$content');
  }

  /// Returns the complete formatted text
  @override
  String toString() {
    return _lines.join('\n');
  }
}
