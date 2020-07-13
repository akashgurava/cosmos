import 'package:dotenv/dotenv.dart' show load, env;

import 'package:cosmos/cosmos.dart';

CosmosClient setUpCosmos() {
  // Load `.env` file into environment
  load();

  final url = env['COSMOS_DB_HOST'];
  final masterkey = env['COSMOS_DB_KEY'];
  return CosmosClient(hostUrl: url, key: masterkey);
}

Future<void> tearDownCosmos(CosmosClient cosmos) async {
  cosmos.dispose();
}
