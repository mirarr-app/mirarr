import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client_stub.dart' if (dart.library.io) 'api_client_io.dart';

/// The single [http.Client] used by every network call in the app.
///
/// The top-level `http.get`/`http.post`/... helpers build a client, send one
/// request and close it, so no connection is ever reused. Going through this
/// wrapper keeps one pooled client alive for the whole process and applies
/// [defaultTimeout] to every request, so a stalled socket always produces a
/// [TimeoutException] instead of hanging a screen forever.
class ApiClient {
  ApiClient._([http.Client? client]) : _client = client ?? createSharedClient();

  static final ApiClient instance = ApiClient._();

  /// Creates an [ApiClient] wrapping a custom [http.Client], useful for testing.
  factory ApiClient.custom(http.Client client) => ApiClient._(client);

  /// Applied to any request that does not pass its own `timeout`.
  static const Duration defaultTimeout = Duration(seconds: 8);

  final http.Client _client;

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) =>
      _withTimeout(_client.get(url, headers: headers), timeout);

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) =>
      _withTimeout(
        _client.post(url, headers: headers, body: body, encoding: encoding),
        timeout,
      );

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) =>
      _withTimeout(
        _client.put(url, headers: headers, body: body, encoding: encoding),
        timeout,
      );

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) =>
      _withTimeout(
        _client.patch(url, headers: headers, body: body, encoding: encoding),
        timeout,
      );

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) =>
      _withTimeout(
        _client.delete(url, headers: headers, body: body, encoding: encoding),
        timeout,
      );

  Future<http.Response> head(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) =>
      _withTimeout(_client.head(url, headers: headers), timeout);

  Future<http.Response> _withTimeout(
    Future<http.Response> request,
    Duration? timeout,
  ) =>
      request.timeout(timeout ?? defaultTimeout);

  void close() => _client.close();
}

/// Shorthand for [ApiClient.instance].
final ApiClient apiClient = ApiClient.instance;
