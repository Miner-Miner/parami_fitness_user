import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/gym_models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class GymApi {
  GymApi({http.Client? client, String? baseUrl, String? database})
    : _client = client ?? http.Client(),
      _baseUrl = ApiConfig.normalizeBaseUrl(
        baseUrl ?? ApiConfig.defaultBaseUrl,
      ),
      _database = database ?? ApiConfig.defaultDatabase;

  final http.Client _client;
  final String _baseUrl;
  final String _database;

  Future<AuthSession> login({
    required String login,
    required String password,
  }) async {
    final data = await _request(
      method: 'POST',
      path: '/gym/api/login',
      body: <String, dynamic>{
        'login': login,
        'password': password,
        'user_role': 'customer',
      },
    );
    final session = AuthSession.fromJson(asJsonMap(data));
    if (session.sessionId.isEmpty || session.userId == 0) {
      throw const ApiException(
        'The server did not return a valid login session.',
      );
    }
    return session;
  }

  Future<MemberProfile> profile(AuthSession session) async {
    final data = await _request(
      method: 'GET',
      path: '/gym/api/profile',
      session: session,
      query: <String, String>{'user_id': '${session.userId}'},
    );
    return MemberProfile.fromJson(asJsonMap(data));
  }

  Future<List<FitnessClass>> freeClasses(AuthSession session) {
    return _classes(session, '/gym/api/classes/free');
  }

  Future<List<FitnessClass>> paidClasses(AuthSession session) {
    return _classes(session, '/gym/api/classes/paid');
  }

  Future<List<FitnessClass>> _classes(AuthSession session, String path) async {
    final data = await _request(method: 'GET', path: path, session: session);
    return asJsonList(
      data,
    ).map(asJsonMap).map(FitnessClass.fromJson).toList(growable: false);
  }

  Future<FreeBooking> bookFreeClass({
    required AuthSession session,
    required FitnessClass fitnessClass,
    required ClassSchedule schedule,
    required DateTime date,
  }) async {
    final data = await _request(
      method: 'POST',
      path: '/gym/api/classes/free/book',
      session: session,
      body: <String, dynamic>{
        'user_id': session.userId,
        'gym_class_id': fitnessClass.id,
        'schedule_id': schedule.id,
        'date': _apiDate(date),
      },
    );
    return FreeBooking.fromJson(asJsonMap(data));
  }

  Future<PackageRecord> checkInWithQr({
    required AuthSession session,
    required String qrCode,
    required double latitude,
    required double longitude,
  }) async {
    final data = await _request(
      method: 'POST',
      path: '/gym/api/checkin/qr',
      session: session,
      body: <String, dynamic>{
        'user_id': session.userId,
        'qr_code': qrCode,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return PackageRecord.fromJson(asJsonMap(data));
  }

  Future<List<PackageRecord>> packages(AuthSession session) async {
    final data = await _userData(session, '/gym/api/packages');
    return asJsonList(
      data,
    ).map(asJsonMap).map(PackageRecord.fromJson).toList(growable: false);
  }

  Future<PackageRecord?> nearestExpiry(AuthSession session) async {
    final data = await _userData(session, '/gym/api/packages/nearest_expiry');
    if (data == null || data == false) {
      return null;
    }
    return PackageRecord.fromJson(asJsonMap(data));
  }

  Future<List<EnrolledClass>> enrolledClasses(AuthSession session) async {
    final data = await _userData(session, '/gym/api/classes/enrolled');
    return asJsonList(
      data,
    ).map(asJsonMap).map(EnrolledClass.fromJson).toList(growable: false);
  }

  Future<List<FreeBooking>> bookedFreeClasses(AuthSession session) async {
    final data = await _userData(session, '/gym/api/classes/free/booked');
    return asJsonList(
      data,
    ).map(asJsonMap).map(FreeBooking.fromJson).toList(growable: false);
  }

  Future<Object?> _userData(AuthSession session, String path) {
    return _request(
      method: 'GET',
      path: path,
      session: session,
      query: <String, String>{'user_id': '${session.userId}'},
    );
  }

  Future<Object?> _request({
    required String method,
    required String path,
    AuthSession? session,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Odoo-Database': _database,
      if (body != null) 'Content-Type': 'application/json',
      if (session != null && session.sessionId.isNotEmpty)
        'Cookie': 'session_id=${session.sessionId}',
    };

    late http.Response response;
    try {
      response = await _send(
        method,
        uri,
        headers,
        body,
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on http.ClientException {
      throw const ApiException(
        'Unable to reach the gym server. Check your connection.',
      );
    }

    Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The gym server returned an unreadable response.',
        statusCode: response.statusCode,
      );
    }

    final envelope = asJsonMap(decoded);
    final hasError =
        envelope['status'] == 'error' ||
        response.statusCode < 200 ||
        response.statusCode >= 300;
    if (hasError) {
      throw ApiException(
        textValue(
          envelope['error'] ?? envelope['message'],
          'Request failed (${response.statusCode}).',
        ),
        statusCode: response.statusCode,
      );
    }
    return envelope['data'];
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(uri, headers: headers, body: jsonEncode(body));
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }
  }

  String _apiDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }
}
