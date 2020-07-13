import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import 'package:cosmos/src/constants.dart';
import 'package:cosmos/src/exceptions.dart';
import 'package:cosmos/src/models/database.dart';
import 'package:cosmos/src/routes.dart';

/// Cosmos DB client
@immutable
class CosmosClient {
  /// Construct Cosmos DB client
  CosmosClient({@required this.hostUrl, @required this.key, Dio client})
      : assert(hostUrl != null, 'Host Url is required'),
        assert(key != null, 'key is required'),
        client = client ?? Dio(BaseOptions(baseUrl: hostUrl));

  /// Host URL of CosmosDB
  final String hostUrl;

  /// Any key with access to provided [hostUrl]
  final String key;

  /// A HttpClient to make requests to the server
  final Dio client;

  /// Clean up actions performed before exiting app
  @mustCallSuper
  void dispose() {
    client.close();
  }

  // TODO: convert to parameter args?
  /// Get autherization key to add to header before making a request
  String _auth(Uri url, RequestMethod method, DateTime date) {
    // Parse arguments
    final requestUrl = url;
    final requestMethod = method.toString().toLowerCase().split('.')[1];
    final requestDate = date;

    // Check if request is called on resource or item.
    // This is determined by number pathSegments in the URI.
    // Odd would mean a item, even would mean an resource.
    final pathSegments = requestUrl.pathSegments;
    final lastSegmentPos = pathSegments.length - 1;

    String resourceType;
    String resourceId;

    // It's even => Resource request
    if (lastSegmentPos % 2 == 0) {
      // assign resource type to the last segment
      resourceType = pathSegments[lastSegmentPos];

      // TODO: find a better way to do this
      // now pull out the resource id by searching for the last slash
      // and substringing to it
      // if (lastSegmentPos > 1) {
      //   final lastPart = url.lastIndexOf('/');
      //   resourceId = url.substring(1, lastPart);
      // }
    } else // It's odd => Item request on resource
    {
      resourceType = pathSegments[lastSegmentPos - 1];
      resourceId = '$resourceType/${pathSegments[lastSegmentPos]}';
    }

    // parse our master key out as base64 encoding
    const base64 = Base64Codec();
    final encryptedKey = base64.decode(key); //Base64Bits --> BITS
    // Get time in RFC1123time format
    final dateFormat = HttpDate.format(requestDate).toLowerCase();

    // ignore: prefer_interpolation_to_compose_strings
    final text = (requestMethod ?? '').toLowerCase() +
        '\n' +
        (resourceType ?? '').toLowerCase() +
        '\n' +
        (resourceId ?? '') +
        '\n' +
        (dateFormat ?? '').toLowerCase() +
        '\n' +
        '' +
        '\n';

    final hmacSha256 = Hmac(sha256, encryptedKey);
    final utf8Text = utf8.encode(text);
    final hashSignature = hmacSha256.convert(utf8Text);
    final base64Bits = base64.encode(hashSignature.bytes);

    //Format our authentication token and URI encode it.
    const masterToken = 'master';
    const tokenVersion = '1.0';
    final auth = Uri.encodeComponent(
      'type=$masterToken&ver=$tokenVersion&sig=$base64Bits',
    );

    return auth;
  }

  /// Query CosmosDB
  Future<Response> _query({
    @required CosmosRoute route,
    DateTime date,
    Map<String, String> data,
  }) async {
    // Parse arguments
    final requestDate = date ?? DateTime.now();

    // Prepare request headers
    final auth = _auth(
      Uri.parse(hostUrl + route.path),
      route.method,
      requestDate,
    );
    final utcString = HttpDate.format(requestDate);
    final requestHeaders = {
      // Add default headers to all requests
      ...defaultHeaders,
      'Authorization': auth,
      'x-ms-date': utcString,
    };

    Response response;
    try {
      switch (route.method) {
        case RequestMethod.get:
          response = await client.get(
            route.path,
            options: Options(
              headers: requestHeaders,
              responseType: ResponseType.json,
            ),
          );
          break;
        case RequestMethod.post:
          response = await client.post(
            route.path,
            data: data,
            options: Options(
              headers: requestHeaders,
              responseType: ResponseType.json,
            ),
          );
          break;
        case RequestMethod.delete:
          response = await client.delete(
            route.path,
            options: Options(
              headers: requestHeaders,
              responseType: ResponseType.json,
            ),
          );
          break;
        default:
      }
    } on DioError catch (e) {
      return e.response;
    }

    return response;
  }

  /// List Databases for this Cosmos DB host
  Future<List<CosmosDatabase>> listDb({DateTime date}) async {
    final response = await _query(route: cosmosRoutes['listDb'], date: date);

    final dbs = <CosmosDatabase>[];

    // If proper response => Parse it else raise an error
    if (response.statusCode == 200) {
      for (final response in response.data['Databases']) {
        dbs.add(CosmosDatabase.fromApi(response));
      }
      return dbs;
    } else {
      // Just a failsafe else block. which should not happen most of the time.
      throw CosmosException(
        'Bad request: ${response.statusCode}',
        response: response,
      );
    }
  }

  /// Get details of a Database for a given [dbId]
  Future<CosmosDatabase> getDb({@required String dbId, DateTime date}) async {
    /// Supply params to template string
    final route = cosmosRoutes['getDb'];
    route.params['dbId'] = dbId;

    final response = await _query(route: route, date: date);

    if (response.statusCode == 200) {
      return CosmosDatabase.fromApi(response.data);
    } else if (response.statusCode == 404) {
      throw CosmosResourceNotFoundException('Database', dbId);
    } else {
      // Just a failsafe else block. which should not happen most of the time.
      throw CosmosException(
        'Bad request: ${response.statusCode}',
        response: response,
      );
    }
  }

  /// Create a Database with [dbId]
  ///
  /// If [softCreate] is True then ignore a duplicate exception. And a empty
  ///   [CosmosDatabase] is returned. Emptiness can be checked
  ///   with [CosmosDatabase.empty()].
  /// Note: Other exceptions will still be thrown.
  Future<CosmosDatabase> createDb({
    @required String dbId,
    DateTime date,
    bool softCreate = false,
  }) async {
    final route = cosmosRoutes['createDb'];
    final data = {'id': dbId};

    final response = await _query(route: route, date: date, data: data);

    if (response.statusCode == 201) {
      return CosmosDatabase.fromApi(response.data);
    } else if (response.statusCode == 409) {
      if (!softCreate) {
        throw CosmosDuplicateResourceException(
          'Database',
          dbId,
          response: response,
        );
      }
      return CosmosDatabase.empty();
    } else {
      // Just a failsafe else block. which should not happen most of the time.
      throw CosmosException(
        'Bad request ${response.statusCode}',
        response: response,
      );
    }
  }

  /// Delete a Database with [dbId]
  ///
  /// If [softDelete] is True then ignore a resource not found exception.
  /// Note: Other exceptions will still be thrown.
  Future<void> deleteDb({
    @required String dbId,
    DateTime date,
    bool softDelete = false,
  }) async {
    final route = cosmosRoutes['deleteDb'];
    route.params['dbId'] = dbId;

    final response = await _query(route: route, date: date);

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 404) {
      if (!softDelete) {
        throw CosmosResourceNotFoundException(
          'Database',
          dbId,
          response: response,
        );
      }
      return;
    } else {
      // Just a failsafe else block. which should not happen most of the time.
      throw CosmosException(
        'Bad request ${response.statusCode}',
        response: response,
      );
    }
  }
}
