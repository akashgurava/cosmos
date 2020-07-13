import 'package:meta/meta.dart';

/// Object reprsentation of CosmosDB Database
@immutable
class CosmosDatabase {
  /// Create a CosmosDB manually.
  const CosmosDatabase({
    @required this.id,
    this.resourceId,
    this.ts,
  });

  /// Create a CosmosDatabase instance from API response
  CosmosDatabase.fromApi(Map<String, dynamic> response)
      : id = response['id'],
        resourceId = response['_rid'],
        ts = DateTime.fromMillisecondsSinceEpoch(response['_ts'] * 1000);

  /// An empty Database to return when a request errors out.
  CosmosDatabase.empty()
      : id = '',
        resourceId = '',
        ts = DateTime.now();

  /// Database ID
  final String id;

  /// System generated Resource ID
  final String resourceId;

  /// Last updated timestamp of the resource
  final DateTime ts;

  @override
  String toString() => '(CosmosDB Database id: $id)';

  /// Test if a database is empty
  bool isEmpty() => id == '';

  @override
  int get hashCode => id.hashCode;

  @override
  // ignore: avoid_annotating_with_dynamic
  bool operator ==(dynamic other) => hashCode == other.hashCode;
}
