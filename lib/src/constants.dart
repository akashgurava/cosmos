/// Request methods sent to Cosmos server
enum RequestMethod {
  /// GET method
  get,

  /// POST method
  post,

  /// PUT method
  put,

  /// DELETE method to delete a resource or item
  delete,
}

/// Default headers used for all requests
const defaultHeaders = {
  'x-ms-version': '2018-12-31',
  'User-Agent': 'CosmicDart/1.0.0'
};
