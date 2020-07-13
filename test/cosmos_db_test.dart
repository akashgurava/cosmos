import 'package:dotenv/dotenv.dart' show load, env;
import 'package:test/test.dart';

import 'package:cosmos/cosmos.dart';

import 'setup.dart';

void main() {
  // Load `.env` file into environment
  load();

  CosmosClient cosmos;

  final testDb1 = env['TEST_DB_1'];
  final testDb2 = env['TEST_DB_2'];

  setUpAll(() async {
    cosmos = setUpCosmos();
    // Create only first test Db the other will be created when required
    await cosmos.createDb(dbId: testDb1, softCreate: true);
  });

  tearDownAll(() async {
    // Delete dbs before exiting
    final testDb1 = env['TEST_DB_1'];
    final testDb2 = env['TEST_DB_2'];

    // Delete both test Dbs before exiting
    await cosmos.deleteDb(dbId: testDb1, softDelete: true);
    await cosmos.deleteDb(dbId: testDb2, softDelete: true);

    await tearDownCosmos(cosmos);
  });

  group('Test Database functionality', () {
    test('Test Client constructor', () async {
      expect(
        () => CosmosClient(hostUrl: null, key: ''),
        throwsA(const TypeMatcher<AssertionError>()),
        reason: 'Host URL cannot be null',
      );

      expect(
        () => CosmosClient(hostUrl: '', key: null),
        throwsA(const TypeMatcher<AssertionError>()),
        reason: 'Key cannot be null',
      );
    });

    test('List Databases for host', () async {
      final dbs = await cosmos.listDb();
      expect(dbs.length, equals(1), reason: 'Only 1 DB in the test host');
      expect(dbs[0].id, equals(testDb1), reason: 'dbId should match');
    });

    test('Get Database', () async {
      final db = await cosmos.getDb(dbId: testDb1);
      expect(db.id, equals(testDb1), reason: 'dbId should match');
      expect(
        () => cosmos.getDb(dbId: testDb2),
        throwsA(CosmosResourceNotFoundException('Database', testDb2)),
        reason: 'Raise an error when dbId is not present',
      );
    });

    test('Create Database', () async {
      final db = await cosmos.createDb(dbId: testDb2);
      expect(
        db.id,
        equals(testDb2),
        reason: 'dbId should match with the newly created dbId',
      );

      final dbs = await cosmos.listDb();
      expect(
        dbs.contains(db),
        equals(true),
        reason: 'dbId should be present when making a listDb call',
      );

      expect(
        () => cosmos.createDb(dbId: testDb2),
        throwsA(CosmosDuplicateResourceException('Database', testDb2)),
        reason: 'Raise an error when dbId is not present',
      );

      expect(
        await cosmos.createDb(dbId: testDb2, softCreate: true),
        equals(CosmosDatabase.empty()),
        reason: '`softCreate` should ignore the error and send a empty Db',
      );

      // this should not raise any error
      await cosmos.deleteDb(dbId: testDb2, softDelete: false);
    });

    test('Delete Database', () async {
      // Create testdb incase its not available
      await cosmos.createDb(dbId: testDb2, softCreate: true);
      final db = CosmosDatabase(id: testDb2);

      var dbs = await cosmos.listDb();
      expect(
        dbs.contains(db),
        equals(true),
        reason: 'dbId should be present before deleting the db',
      );

      // Delete DB
      await cosmos.deleteDb(dbId: testDb2);

      //
      dbs = await cosmos.listDb();
      expect(
        dbs.contains(db),
        equals(false),
        reason: 'dbId should not be present when making a list DB call',
      );

      expect(
        () => cosmos.deleteDb(dbId: testDb2),
        throwsA(CosmosResourceNotFoundException('Database', testDb2)),
        reason: 'Raise an error when trying to delete a non exitent database',
      );

      // softDelete should ignore the error and send a empty Db
      await cosmos.deleteDb(dbId: testDb2, softDelete: true);
    });
  });
}
