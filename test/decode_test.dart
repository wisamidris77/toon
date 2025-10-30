import 'package:test/test.dart';
import 'package:toon/toon.dart';

void main() {
  group('primitives', () {
    test('decodes safe unquoted strings', () {
      expect(toonDecode('hello'), equals('hello'));
      expect(toonDecode('Ada_99'), equals('Ada_99'));
    });

    test('decodes quoted strings and unescapes control characters', () {
      expect(toonDecode('""'), equals(''));
      expect(toonDecode('"line1\\nline2"'), equals('line1\nline2'));
      expect(toonDecode('"tab\\there"'), equals('tab\there'));
      expect(toonDecode('"return\\rcarriage"'), equals('return\rcarriage'));
      expect(toonDecode('"C:\\\\Users\\\\path"'), equals('C:\\Users\\path'));
      expect(toonDecode('"say \\"hello\\""'), equals('say "hello"'));
    });

    test('decodes unicode and emoji', () {
      expect(toonDecode('café'), equals('café'));
      expect(toonDecode('你好'), equals('你好'));
      expect(toonDecode('🚀'), equals('🚀'));
      expect(toonDecode('hello 👋 world'), equals('hello 👋 world'));
    });

    test('decodes numbers, booleans and null', () {
      expect(toonDecode('42'), equals(42));
      expect(toonDecode('3.14'), equals(3.14));
      expect(toonDecode('-7'), equals(-7));
      expect(toonDecode('true'), equals(true));
      expect(toonDecode('false'), equals(false));
      expect(toonDecode('null'), equals(null));
    });

    test('treats unquoted invalid numeric formats as strings', () {
      expect(toonDecode('05'), equals('05'));
      expect(toonDecode('007'), equals('007'));
      expect(toonDecode('0123'), equals('0123'));
      expect(toonDecode('a: 05'), equals({'a': '05'}));
      expect(
          toonDecode('nums[3]: 05,007,0123'),
          equals({
            'nums': ['05', '007', '0123']
          }));
    });

    test('respects ambiguity quoting (quoted primitives remain strings)', () {
      expect(toonDecode('"true"'), equals('true'));
      expect(toonDecode('"false"'), equals('false'));
      expect(toonDecode('"null"'), equals('null'));
      expect(toonDecode('"42"'), equals('42'));
      expect(toonDecode('"-3.14"'), equals('-3.14'));
      expect(toonDecode('"1e-6"'), equals('1e-6'));
      expect(toonDecode('"05"'), equals('05'));
    });
  });

  group('objects (simple)', () {
    test('parses objects with primitive values', () {
      const toon = 'id: 123\nname: Ada\nactive: true';
      expect(
          toonDecode(toon), equals({'id': 123, 'name': 'Ada', 'active': true}));
    });

    test('parses null values in objects', () {
      const toon = 'id: 123\nvalue: null';
      expect(toonDecode(toon), equals({'id': 123, 'value': null}));
    });

    test('parses empty nested object header', () {
      expect(toonDecode('user:'), equals({'user': {}}));
    });

    test('parses quoted object values with special characters and escapes', () {
      expect(toonDecode('note: "a:b"'), equals({'note': 'a:b'}));
      expect(toonDecode('note: "a,b"'), equals({'note': 'a,b'}));
      expect(toonDecode('text: "line1\\nline2"'),
          equals({'text': 'line1\nline2'}));
      expect(toonDecode('text: "say \\"hello\\""'),
          equals({'text': 'say "hello"'}));
      expect(toonDecode('text: " padded "'), equals({'text': ' padded '}));
      expect(toonDecode('text: "  "'), equals({'text': '  '}));
      expect(toonDecode('v: "true"'), equals({'v': 'true'}));
      expect(toonDecode('v: "42"'), equals({'v': '42'}));
      expect(toonDecode('v: "-7.5"'), equals({'v': '-7.5'}));
    });
  });

  group('objects (keys)', () {
    test('parses quoted keys with special characters and escapes', () {
      expect(toonDecode('"order:id": 7'), equals({'order:id': 7}));
      expect(toonDecode('"[index]": 5'), equals({'[index]': 5}));
      expect(toonDecode('"{key}": 5'), equals({'{key}': 5}));
      expect(toonDecode('"a,b": 1'), equals({'a,b': 1}));
      expect(toonDecode('"full name": Ada'), equals({'full name': 'Ada'}));
      expect(toonDecode('"-lead": 1'), equals({'-lead': 1}));
      expect(toonDecode('" a ": 1'), equals({' a ': 1}));
      expect(toonDecode('"123": x'), equals({'123': 'x'}));
      expect(toonDecode('"": 1'), equals({'': 1}));
    });

    test('parses dotted keys as identifiers', () {
      expect(toonDecode('user.name: Ada'), equals({'user.name': 'Ada'}));
      expect(toonDecode('_private: 1'), equals({'_private': 1}));
      expect(toonDecode('user_name: 1'), equals({'user_name': 1}));
    });
  });

  group('objects (nested)', () {
    test('parses nested objects with indentation', () {
      const toon = 'user:\n  name: Alice\n  age: 30\n  active: true';
      expect(
          toonDecode(toon),
          equals({
            'user': {'name': 'Alice', 'age': 30, 'active': true}
          }));
    });

    test('parses deeply nested objects', () {
      const toon = 'a:\n  b:\n    c:\n      d: 42';
      expect(
          toonDecode(toon),
          equals({
            'a': {
              'b': {
                'c': {'d': 42}
              }
            }
          }));
    });

    test('parses mixed nested structures', () {
      const toon =
          'config:\n  database:\n    host: localhost\n    port: 5432\n  features[2]: logging,auth';
      expect(
          toonDecode(toon),
          equals({
            'config': {
              'database': {'host': 'localhost', 'port': 5432},
              'features': ['logging', 'auth']
            }
          }));
    });
  });

  group('arrays (primitive)', () {
    test('parses inline primitive arrays', () {
      expect(
          toonDecode('nums[3]: 1,2,3'),
          equals({
            'nums': [1, 2, 3]
          }));
      expect(
          toonDecode('flags[2]: true,false'),
          equals({
            'flags': [true, false]
          }));
      expect(
          toonDecode('data[3]: hello,world,test'),
          equals({
            'data': ['hello', 'world', 'test']
          }));
    });

    test('parses empty arrays', () {
      expect(toonDecode('empty[0]:'), equals({'empty': []}));
    });

    test('parses primitive arrays with length marker', () {
      expect(
          toonDecode('nums[#3]: 1,2,3'),
          equals({
            'nums': [1, 2, 3]
          }));
    });
  });

  group('arrays (tabular)', () {
    test('parses tabular arrays with primitive columns', () {
      const toon = 'users[2]{name,age}:\n  Alice,30\n  Bob,25';
      expect(
          toonDecode(toon),
          equals({
            'users': [
              {'name': 'Alice', 'age': 30},
              {'name': 'Bob', 'age': 25}
            ]
          }));
    });

    test('parses tabular arrays with mixed types', () {
      const toon =
          'data[2]{name,count,active}:\n  Alice,42,true\n  Bob,17,false';
      expect(
          toonDecode(toon),
          equals({
            'data': [
              {'name': 'Alice', 'count': 42, 'active': true},
              {'name': 'Bob', 'count': 17, 'active': false}
            ]
          }));
    });

    test('parses tabular arrays with quoted values', () {
      const toon =
          'items[2]{name,desc}:\n  "Item 1","A \\"special\\" item"\n  "Item 2",Normal item';
      expect(
          toonDecode(toon),
          equals({
            'items': [
              {'name': 'Item 1', 'desc': 'A "special" item'},
              {'name': 'Item 2', 'desc': 'Normal item'}
            ]
          }));
    });
  });

  group('arrays (list)', () {
    test('parses list arrays of primitives', () {
      const toon = 'numbers[3]:\n  - 1\n  - 2\n  - 3';
      expect(
          toonDecode(toon),
          equals({
            'numbers': [1, 2, 3]
          }));
    });

    test('parses list arrays of objects', () {
      const toon =
          'users[2]:\n  - name: Alice\n    age: 30\n  - name: Bob\n    age: 25';
      expect(
          toonDecode(toon),
          equals({
            'users': [
              {'name': 'Alice', 'age': 30},
              {'name': 'Bob', 'age': 25}
            ]
          }));
    });

    test('parses mixed list arrays', () {
      const toon =
          'items[3]:\n  - hello\n  - count: 42\n  - id: 1\n    nested:\n      value: true';
      expect(
          toonDecode(toon),
          equals({
            'items': [
              'hello',
              {'count': 42},
              {
                'id': 1,
                'nested': {'value': true}
              }
            ]
          }));
    });
  });

  group('root arrays', () {
    test('parses root primitive array', () {
      const toon = '[3]: 1,2,3';
      expect(toonDecode(toon), equals([1, 2, 3]));
    });

    test('parses root tabular array', () {
      const toon = '[2]{name,age}:\n  Alice,30\n  Bob,25';
      expect(
          toonDecode(toon),
          equals([
            {'name': 'Alice', 'age': 30},
            {'name': 'Bob', 'age': 25}
          ]));
    });

    test('parses root list array', () {
      const toon = '[2]:\n  - Alice\n  - Bob';
      expect(toonDecode(toon), equals(['Alice', 'Bob']));
    });
  });

  group('complex structures', () {
    test('parses complex nested structure', () {
      const toon = '''config:
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
  users[2]{name,email}:
    Alice,alice@example.com
    Bob,bob@example.com''';

      expect(
          toonDecode(toon),
          equals({
            'config': {
              'app': {'name': 'MyApp', 'version': '1.0.0'},
              'database': {
                'host': 'localhost',
                'port': 5432,
                'credentials': {'username': 'admin', 'password': 'secret'}
              },
              'features': ['auth', 'logging', 'cache'],
              'users': [
                {'name': 'Alice', 'email': 'alice@example.com'},
                {'name': 'Bob', 'email': 'bob@example.com'}
              ]
            }
          }));
    });
  });

  group('error cases', () {
    test('throws on empty input', () {
      expect(() => toonDecode(''), throwsFormatException);
      expect(() => toonDecode('   '), throwsFormatException);
    });

    test('throws on invalid syntax', () {
      expect(() => toonDecode('"unclosed quote'), throwsFormatException);
    });
  });
}
