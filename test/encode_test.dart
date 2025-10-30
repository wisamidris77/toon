import 'package:test/test.dart';
import 'package:toon/toon.dart';

void main() {
  group('primitives', () {
    test('encodes safe strings without quotes', () {
      expect(toonEncode('hello'), equals('hello'));
      expect(toonEncode('Ada_99'), equals('Ada_99'));
    });

    test('quotes empty string', () {
      expect(toonEncode(''), equals('""'));
    });

    test('quotes strings that look like booleans or numbers', () {
      expect(toonEncode('true'), equals('"true"'));
      expect(toonEncode('false'), equals('"false"'));
      expect(toonEncode('null'), equals('"null"'));
      expect(toonEncode('42'), equals('"42"'));
      expect(toonEncode('-3.14'), equals('"-3.14"'));
      expect(toonEncode('1e-6'), equals('"1e-6"'));
      expect(toonEncode('05'), equals('"05"'));
    });

    test('escapes control characters in strings', () {
      expect(toonEncode('line1\nline2'), equals('"line1\\nline2"'));
      expect(toonEncode('tab\there'), equals('"tab\\there"'));
      expect(toonEncode('return\rcarriage'), equals('"return\\rcarriage"'));
      expect(toonEncode('C:\\Users\\path'), equals('"C:\\\\Users\\\\path"'));
    });

    test('quotes strings with structural characters', () {
      expect(toonEncode('[3]: x,y'), equals('"[3]: x,y"'));
      expect(toonEncode('- item'), equals('"- item"'));
      expect(toonEncode('[test]'), equals('"[test]"'));
      expect(toonEncode('{key}'), equals('"{key}"'));
    });

    test('handles Unicode and emoji', () {
      expect(toonEncode('café'), equals('café'));
      expect(toonEncode('你好'), equals('你好'));
      expect(toonEncode('🚀'), equals('🚀'));
      expect(toonEncode('hello 👋 world'), equals('hello 👋 world'));
    });

    test('encodes numbers', () {
      expect(toonEncode(42), equals('42'));
      expect(toonEncode(3.14), equals('3.14'));
      expect(toonEncode(-7), equals('-7'));
      expect(toonEncode(0), equals('0'));
    });

    test('handles special numeric values', () {
      expect(toonEncode(-0.0), equals('0'));
      expect(toonEncode(1e6), equals('1000000'));
      expect(toonEncode(1e-6), equals('0.000001'));
      expect(toonEncode(1e20), equals('100000000000000000000'));
      expect(toonEncode(9007199254740991), equals('9007199254740991'));
    });

    test('encodes booleans', () {
      expect(toonEncode(true), equals('true'));
      expect(toonEncode(false), equals('false'));
    });

    test('encodes null', () {
      expect(toonEncode(null), equals('null'));
    });
  });

  group('objects (simple)', () {
    test('preserves key order in objects', () {
      final obj = {'id': 123, 'name': 'Ada', 'active': true};
      expect(toonEncode(obj), equals('id: 123\nname: Ada\nactive: true'));
    });

    test('encodes null values in objects', () {
      final obj = {'id': 123, 'value': null};
      expect(toonEncode(obj), equals('id: 123\nvalue: null'));
    });

    test('encodes empty objects as empty string', () {
      expect(toonEncode({}), equals(''));
    });

    test('quotes string values with special characters', () {
      expect(toonEncode({'note': 'a:b'}), equals('note: "a:b"'));
      expect(toonEncode({'note': 'a,b'}), equals('note: "a,b"'));
      expect(toonEncode({'text': 'line1\nline2'}),
          equals('text: "line1\\nline2"'));
      expect(toonEncode({'text': 'say "hello"'}),
          equals('text: "say \\"hello\\""'));
    });

    test('quotes string values with leading/trailing spaces', () {
      expect(toonEncode({'text': ' padded '}), equals('text: " padded "'));
      expect(toonEncode({'text': '  '}), equals('text: "  "'));
    });
  });

  group('objects (keys)', () {
    test('quotes keys with special characters', () {
      expect(toonEncode({'order:id': 7}), equals('"order:id": 7'));
      expect(toonEncode({'[index]': 5}), equals('"[index]": 5'));
      expect(toonEncode({'{key}': 5}), equals('"{key}": 5'));
      expect(toonEncode({'a,b': 1}), equals('"a,b": 1'));
      expect(toonEncode({'full name': 'Ada'}), equals('"full name": Ada'));
      expect(toonEncode({'-lead': 1}), equals('"-lead": 1'));
      expect(toonEncode({' a ': 1}), equals('" a ": 1'));
      expect(toonEncode({'123': 'x'}), equals('"123": x'));
      expect(toonEncode({'': 1}), equals('"": 1'));
    });

    test('handles dotted keys', () {
      expect(toonEncode({'user.name': 'Ada'}), equals('user.name: Ada'));
      expect(toonEncode({'_private': 1}), equals('_private: 1'));
      expect(toonEncode({'user_name': 1}), equals('user_name: 1'));
    });
  });

  group('objects (nested)', () {
    test('encodes nested objects', () {
      final obj = {
        'user': {'name': 'Alice', 'age': 30, 'active': true}
      };
      const expected = 'user:\n  name: Alice\n  age: 30\n  active: true';
      expect(toonEncode(obj), equals(expected));
    });

    test('encodes deeply nested objects', () {
      final obj = {
        'a': {
          'b': {
            'c': {'d': 42}
          }
        }
      };
      const expected = 'a:\n  b:\n    c:\n      d: 42';
      expect(toonEncode(obj), equals(expected));
    });

    test('encodes mixed nested structures', () {
      final obj = {
        'config': {
          'database': {'host': 'localhost', 'port': 5432},
          'features': ['logging', 'auth']
        }
      };
      const expected =
          'config:\n  database:\n    host: localhost\n    port: 5432\n  features[2]: logging,auth';
      expect(toonEncode(obj), equals(expected));
    });
  });

  group('arrays (primitive)', () {
    test('encodes primitive arrays inline', () {
      expect(
          toonEncode({
            'nums': [1, 2, 3]
          }),
          equals('nums[3]: 1,2,3'));
      expect(
          toonEncode({
            'flags': [true, false]
          }),
          equals('flags[2]: true,false'));
      expect(
          toonEncode({
            'data': ['hello', 'world', 'test']
          }),
          equals('data[3]: hello,world,test'));
    });

    test('encodes empty arrays', () {
      expect(toonEncode({'empty': []}), equals('empty[0]:'));
    });

    test('encodes arrays with length marker', () {
      final options = EncodeOptions(lengthMarker: '#');
      expect(
          toonEncode({
            'nums': [1, 2, 3]
          }, options: options),
          equals('nums[#3]: 1,2,3'));
    });
  });

  group('arrays (tabular)', () {
    test('encodes arrays of objects as tabular', () {
      final obj = {
        'users': [
          {'name': 'Alice', 'age': 30},
          {'name': 'Bob', 'age': 25}
        ]
      };
      const expected = 'users[2]{name,age}:\n  Alice,30\n  Bob,25';
      expect(toonEncode(obj), equals(expected));
    });

    test('encodes tabular arrays with mixed types', () {
      final obj = {
        'data': [
          {'name': 'Alice', 'count': 42, 'active': true},
          {'name': 'Bob', 'count': 17, 'active': false}
        ]
      };
      const expected =
          'data[2]{name,count,active}:\n  Alice,42,true\n  Bob,17,false';
      expect(toonEncode(obj), equals(expected));
    });

    test('encodes tabular arrays with quoted values', () {
      final obj = {
        'items': [
          {'name': 'Item 1', 'desc': 'A "special" item'},
          {'name': 'Item 2', 'desc': 'Normal item'}
        ]
      };
      const expected =
          'items[2]{name,desc}:\n  Item 1,"A \\"special\\" item"\n  Item 2,Normal item';
      expect(toonEncode(obj), equals(expected));
    });
  });

  group('arrays (list)', () {
    test('encodes mixed arrays as lists', () {
      final obj = {
        'items': [
          'hello',
          {'count': 42},
          {
            'nested': {'value': true}
          }
        ]
      };
      const expected =
          'items[3]:\n  - hello\n  - count: 42\n  - nested:\n      value: true';
      expect(toonEncode(obj), equals(expected));
    });

    test('encodes arrays of objects as lists when not uniform', () {
      final obj = {
        'users': [
          {'name': 'Alice', 'age': 30},
          {'name': 'Bob', 'email': 'bob@example.com'}
        ]
      };
      const expected =
          'users[2]:\n  - name: Alice\n    age: 30\n  - name: Bob\n    email: bob@example.com';
      expect(toonEncode(obj), equals(expected));
    });
  });

  group('root arrays', () {
    test('encodes root primitive arrays', () {
      expect(toonEncode([1, 2, 3]), equals('[3]: 1,2,3'));
    });

    test('encodes root tabular arrays', () {
      final arr = [
        {'name': 'Alice', 'age': 30},
        {'name': 'Bob', 'age': 25}
      ];
      const expected = '[2]{name,age}:\n  Alice,30\n  Bob,25';
      expect(toonEncode(arr), equals(expected));
    });

    test('encodes root primitive arrays', () {
      expect(toonEncode(['Alice', 'Bob']), equals('[2]: Alice,Bob'));
    });
  });

  group('delimiters', () {
    test('uses tab delimiter when specified', () {
      final options = EncodeOptions(delimiter: '\t');
      expect(
          toonEncode({
            'data': ['a', 'b', 'c']
          }, options: options),
          equals('data[3\t]: a\tb\tc'));
    });

    test('uses pipe delimiter when specified', () {
      final options = EncodeOptions(delimiter: '|');
      expect(
          toonEncode({
            'data': ['a', 'b', 'c']
          }, options: options),
          equals('data[3|]: a|b|c'));
    });
  });

  group('indentation', () {
    test('uses custom indentation', () {
      final obj = {
        'user': {
          'name': 'Alice',
          'profile': {'age': 30}
        }
      };
      final options = EncodeOptions(indent: 4);
      const expected = 'user:\n    name: Alice\n    profile:\n        age: 30';
      expect(toonEncode(obj, options: options), equals(expected));
    });
  });

  group('complex structures', () {
    test('encodes complex nested structure', () {
      final obj = {
        'config': {
          'app': {'name': 'MyApp', 'version': '1.0.0'},
          'database': {
            'host': 'localhost',
            'port': 5432,
            'credentials': {'username': 'admin', 'password': 'secret'}
          },
          'features': ['auth', 'logging', 'cache'],
          'users': [
            {
              'name': 'Alice',
              'email': 'alice@example.com',
              'roles': ['admin', 'user']
            },
            {
              'name': 'Bob',
              'email': 'bob@example.com',
              'roles': ['user']
            }
          ]
        }
      };

      const expected = '''config:
  app:
    name: MyApp
    version: 1.0.0
  database:
    host: localhost
    port: 5432
    credentials:
      username: admin
      password: secret
  features[3]: auth,logging,cache
  users[2]:\n    - name: Alice\n      email: alice@example.com\n      roles[2]: admin,user\n    - name: Bob\n      email: bob@example.com\n      roles[1]: user''';

      expect(toonEncode(obj), equals(expected));
    });
  });
}
