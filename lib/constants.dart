// #region List markers

/// Marker for list items
const LIST_ITEM_MARKER = '-';
const LIST_ITEM_PREFIX = '- ';

// #endregion

// #region Structural characters

const COMMA = ',';
const COLON = ':';
const SPACE = ' ';
const PIPE = '|';
const HASH = '#';

// #endregion

// #region Brackets and braces

const OPEN_BRACKET = '[';
const CLOSE_BRACKET = ']';
const OPEN_BRACE = '{';
const CLOSE_BRACE = '}';

// #endregion

// #region Literals

const NULL_LITERAL = 'null';
const TRUE_LITERAL = 'true';
const FALSE_LITERAL = 'false';

// #endregion

// #region Escape characters

const BACKSLASH = '\\';
const DOUBLE_QUOTE = '"';
const NEWLINE = '\n';
const CARRIAGE_RETURN = '\r';
const TAB = '\t';

// #endregion

// #region Delimiters

/// Map of delimiter keys to delimiter values
const DELIMITERS = {
  'comma': COMMA,
  'tab': TAB,
  'pipe': PIPE,
};

/// Type alias for delimiter keys
typedef DelimiterKey = String;

/// Type alias for delimiter values
typedef Delimiter = String;

/// Default delimiter
const DEFAULT_DELIMITER = COMMA;

// #endregion
