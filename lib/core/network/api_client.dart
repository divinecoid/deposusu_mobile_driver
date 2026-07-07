import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/app_constants.dart';

class ApiClient {
  final http.Client _client;
  String? _token;
  VoidCallback? onUnauthorized;

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

  void _handleResponse(String endpoint, int statusCode) {
    if (statusCode == 401 && endpoint != '/login' && endpoint != '/driver/verify-otp') {
      clearToken();
      onUnauthorized?.call();
    }
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers);
    _handleResponse(endpoint, response.statusCode);
    return response;
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _handleResponse(endpoint, response.statusCode);
    return response;
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

    final response = await request.send();
    _handleResponse(endpoint, response.statusCode);
    return response;
  }
}
