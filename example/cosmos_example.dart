import 'package:dotenv/dotenv.dart' show load, env;

import 'package:cosmos/cosmos.dart';

Future<void> main() async {
  // Load `.env` file into environment
  load();

  final url = env['COSMOS_DB_HOST'];
  final masterkey = env['COSMOS_DB_KEY'];
  final testDb = env['TEST_DB_1'];
  final cosmos = CosmosClient(hostUrl: url, key: masterkey);

  // List all Dbs ifor this host
  var dbs = await cosmos.listDb();
  print(dbs);

  // Create a Db
  final db_1 = await cosmos.createDb(dbId: testDb, softCreate: true);

  // Check list of Dbs now. It should contain the
  dbs = await cosmos.listDb();
  print(dbs);

  await cosmos.deleteDb(dbId: testDb, softDelete: true);

  // Close the client before exiting. Otherwise the program waits for 4 5 secs
  cosmos.dispose();
}
