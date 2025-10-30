// #region List markers

/// Marker for list items
const listItemMarker = '-';
const listItemPrefix = '- ';

const comma = ',';
const colon = ':';
const space = ' ';
const pipe = '|';
const hash = '#';

const openBracket = '[';
const closeBracket = ']';
const openBrace = '{';
const closeBrace = '}';

const nullLiteral = 'null';
const trueLiteral = 'true';
const falseLiteral = 'false';

const backslash = '\\';
const doubleQuote = '"';
const newLine = '\n';
const carriageReturn = '\r';
const tab = '\t';

/// Map of delimiter keys to delimiter values
const delimiters = {
  'comma': comma,
  'tab': tab,
  'pipe': pipe,
};

/// Type alias for delimiter keys
typedef DelimiterKey = String;

/// Type alias for delimiter values
typedef Delimiter = String;

/// Default delimiter
const defaultDelimiters = comma;
