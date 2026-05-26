import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/app_constants.dart';

class ApiClient {
  final http.Client _client;
  String? _token;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint').replace(queryParameters: queryParams);
    return await _client.get(uri, headers: _headers);
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return await _client.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Sends a multipart POST request (used for uploading proof photo)
  Future<http.StreamedResponse> postMultipart({
    required String endpoint,
    required Map<String, String> fields,
    required File file,
    required String fileField,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Add normal headers (Token)
    request.headers.addAll({
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });

    // Add fields
    request.fields.addAll(fields);

    // Determine content type
    final mimeType = file.path.endsWith('.png') ? 'image/png' : 'image/jpeg';

    // Add file
    final multipartFile = await http.MultipartFile.fromPath(
      fileField,
      file.path,
      contentType: MediaType.parse(mimeType),
    );
    request.files.add(multipartFile);

    return await request.send();
  }
}
