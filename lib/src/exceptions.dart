import 'package:meta/meta.dart';

import 'package:dio/dio.dart';

/// Umbrella Error class for errorsraised by CosmosDB
@immutable
class CosmosException implements Exception {
  /// Instantiate a Generalized CosmosDB error
  const CosmosException(this.message, {this.response});

  /// Message displayed when the exception is unhandled
  final String message;

  /// Response recieved which caused the error. Might be nuull.
  final Response response;

  @override
  int get hashCode => message.hashCode;

  @override
  // ignore: avoid_annotating_with_dynamic
  bool operator ==(dynamic other) => other.hashCode == hashCode;

  @override
  String toString() => message;
}

/// Error to raise when a CosmosDB resource could not be found
@immutable
class CosmosResourceNotFoundException extends CosmosException {
  /// Raise a [CosmosResourceNotFoundException] to show
  /// [resourceType] and [resourceId]
  const CosmosResourceNotFoundException(
    this.resourceType,
    this.resourceId, {
    Response response,
  }) : super(
          'Resource:$resourceType with ID:$resourceId is not found',
          response: response,
        );

  /// Type of resouce that raised the error
  final String resourceType;

  /// ID of resouce that raised the error
  final String resourceId;

  @override
  String toString() => message;

  @override
  int get hashCode => resourceType.hashCode ^ resourceId.hashCode;

  @override
  // ignore: avoid_annotating_with_dynamic
  bool operator ==(dynamic other) => other.hashCode == hashCode;
}

/// Error raised when trying to create a duplicate CosmosDB resouce.
@immutable
class CosmosDuplicateResourceException extends CosmosException {
  /// Raise a [CosmosDuplicateResourceException] to show
  /// [resourceType] and [resourceId]
  const CosmosDuplicateResourceException(
    this.resourceType,
    this.resourceId, {
    Response response,
  }) : super(
          '''Resource:$resourceType with ID:$resourceId is already present in the server''',
          response: response,
        );

  /// Type of resouce that raised the error
  final String resourceType;

  /// ID of resouce that raised the error
  final String resourceId;

  @override
  String toString() => message;

  @override
  int get hashCode => resourceType.hashCode ^ resourceId.hashCode;

  @override
  // ignore: avoid_annotating_with_dynamic
  bool operator ==(dynamic other) => other.hashCode == hashCode;
}
