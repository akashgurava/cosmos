import 'package:test/test.dart';

import 'package:cosmos/cosmos.dart';

void main() {
  group('Test Helpers', () {
    final str = TemplateString('dbs/{dbId}/collection/{collId}');

    test('Test Varibale identification', () {
      expect(
        str.fixedComponents,
        equals(['dbs/', '/collection/']),
        reason: 'Fixed components should equal known fixed components',
      );

      expect(
        str.genericComponents,
        equals({1: 'dbId', 3: 'collId'}),
        reason: 'Variables should be properly identified along with position',
      );
    });
    test('Test String Interpolation', () {
      expect(
        str.format({'dbId': 'db', 'collId': 'coll'}),
        equals('dbs/db/collection/coll'),
        reason: 'Success test to see interpolation works correctly',
      );

      expect(
        () => str.format({'dbId': 'db'}),
        throwsA(const TypeMatcher<FormatException>()),
        reason: 'When Not all arguments are passed a error is thrown',
      );
    });
  });
}
