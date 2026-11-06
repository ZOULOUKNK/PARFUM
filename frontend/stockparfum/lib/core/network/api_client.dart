import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Exception métier levée lorsqu'une requête API échoue, avec un
/// message adapté à l'affichage direct à l'utilisateur.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Client HTTP centralisé : ajoute automatiquement le token JWT,
/// gère l'encodage JSON et uniformise la gestion des erreurs pour
/// tous les services de l'application.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _storage = const FlutterSecureStorage();
  final String baseUrl = AppConstants.baseUrl;

  Future<String?> get _token async => _storage.read(key: AppConstants.tokenKey);

  Future<Map<String, String>> get _headers async {
    final token = await _token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanQuery = query?.map((k, v) => MapEntry(k, v?.toString() ?? ''))
      ..removeWhere((k, v) => v.isEmpty);
    return Uri.parse('$baseUrl$path').replace(queryParameters: cleanQuery?.isEmpty ?? true ? null : cleanQuery);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await http.get(_uri(path, query), headers: await _headers);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Impossible de contacter le serveur. Vérifiez votre connexion.');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(_uri(path), headers: await _headers, body: jsonEncode(body));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Impossible de contacter le serveur. Vérifiez votre connexion.');
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.put(_uri(path), headers: await _headers, body: jsonEncode(body));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Impossible de contacter le serveur. Vérifiez votre connexion.');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await http.delete(_uri(path), headers: await _headers);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Impossible de contacter le serveur. Vérifiez votre connexion.');
    }
  }

  /// Envoi multipart pour la création/modification d'un produit avec image.
  Future<dynamic> multipartRequest(
    String method,
    String path,
    Map<String, String> fields, {
    String? imagePath,
    String imageFieldName = 'image',
  }) async {
    try {
      final request = http.MultipartRequest(method, _uri(path));
      final token = await _token;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);

      if (imagePath != null) {
        request.files.add(await http.MultipartFile.fromPath(imageFieldName, imagePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Impossible de contacter le serveur. Vérifiez votre connexion.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Réponse du serveur invalide.', statusCode: response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded['data'];
    }

    final message = decoded['message'] as String? ?? 'Une erreur est survenue.';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
