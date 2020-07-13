import 'package:meta/meta.dart';

import 'package:cosmos/src/constants.dart';
import 'package:cosmos/src/helpers.dart';

/// A Parser for Cosmos DB router
@immutable
class CosmosRoute {
  /// Create a cosmos route manually
  CosmosRoute({
    this.name,
    this.initialPath,
    this.method,
    Map<String, String> headers,
  }) : headers = headers ?? <String, String>{};

  /// Name of the route.
  // TODO: Use this or remove
  final String name;

  /// PathSegement of route
  /// This might be a format string like 'dbs/{dbid}'
  final TemplateString initialPath;

  /// Method of request to send to CosmosDB
  final RequestMethod method;

  /// Additional headers for this route
  final Map<String, String> headers;

  /// Params to format the Template string
  final Map<String, String> params = <String, String>{};

  /// Get path after formatting initial path with params
  /// This throws an error if all the variables in [initialPath] are not
  /// present in [params]
  String get path {
    return initialPath.format(params);
  }
}

/// Router to
final Map<String, CosmosRoute> cosmosRoutes = {
  'listDb': CosmosRoute(
    name: 'list DB',
    initialPath: TemplateString('dbs'),
    method: RequestMethod.get,
  ),
  'getDb': CosmosRoute(
    name: 'list DB',
    initialPath: TemplateString('dbs/{dbId}'),
    method: RequestMethod.get,
  ),
  'createDb': CosmosRoute(
    name: 'Create DB',
    initialPath: TemplateString('dbs'),
    method: RequestMethod.post,
  ),
  'deleteDb': CosmosRoute(
    name: 'Delete DB',
    initialPath: TemplateString('dbs/{dbId}'),
    method: RequestMethod.delete,
  ),
};
