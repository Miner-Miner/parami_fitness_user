import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parami_fitness_user/models/gym_models.dart';
import 'package:parami_fitness_user/services/gym_api.dart';

void main() {
  const session = AuthSession(
    sessionId: 'session-123',
    userId: 46,
    name: 'Member',
    login: 'member@example.com',
    userRole: 'customer',
    memberId: 'MEM-00025',
    partnerId: 12,
    isGymAdmin: false,
  );

  test('QR check-in posts the scan and current location', () async {
    final api = GymApi(
      baseUrl: 'https://gym.example',
      database: 'parami_demo',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://gym.example/gym/api/checkin/qr',
        );
        expect(request.headers['cookie'], 'session_id=session-123');
        expect(jsonDecode(request.body), <String, dynamic>{
          'user_id': 46,
          'qr_code': 'gym-fixed-qr',
          'latitude': 16.8409,
          'longitude': 96.1735,
        });
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'success',
            'data': <String, dynamic>{
              'id': 4,
              'product_name': 'Monthly Membership',
              'product_type': 'service',
              'start_date': '2026-08-31',
              'expiration_date': '2026-09-30',
              'total_sessions': 12,
              'remaining_sessions': 11,
              'trainer_name': false,
              'state': 'active',
            },
          }),
          200,
        );
      }),
    );

    final package = await api.checkInWithQr(
      session: session,
      qrCode: 'gym-fixed-qr',
      latitude: 16.8409,
      longitude: 96.1735,
    );

    expect(package.productName, 'Monthly Membership');
    expect(package.remainingSessions, 11);
  });

  test('QR check-in surfaces server errors', () async {
    final api = GymApi(
      baseUrl: 'https://gym.example',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'error',
            'error': 'Invalid QR code',
          }),
          400,
        ),
      ),
    );

    expect(
      api.checkInWithQr(
        session: session,
        qrCode: 'wrong-code',
        latitude: 16.8409,
        longitude: 96.1735,
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Invalid QR code',
        ),
      ),
    );
  });
}
