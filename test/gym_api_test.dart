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

  test('loyalty points returns the member card balance', () async {
    final api = GymApi(
      baseUrl: 'https://gym.example',
      database: 'parami_demo',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://gym.example/gym/api/loyalty/points?user_id=46',
        );
        expect(request.headers['cookie'], 'session_id=session-123');
        expect(request.headers['x-odoo-database'], 'parami_demo');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'success',
            'data': <String, dynamic>{
              'program_id': 8,
              'program_name': 'Gym Rewards',
              'points': 42.5,
              'code': 'CARD-123',
            },
          }),
          200,
        );
      }),
    );

    final loyaltyPoints = await api.loyaltyPoints(session);

    expect(loyaltyPoints, isNotNull);
    expect(loyaltyPoints!.programName, 'Gym Rewards');
    expect(loyaltyPoints.points, 42.5);
    expect(loyaltyPoints.displayValue, '42.5 pts · Gym Rewards');
  });

  test('loyalty points is absent when no program is configured', () async {
    final api = GymApi(
      baseUrl: 'https://gym.example',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, dynamic>{'status': 'success', 'data': false}),
          200,
        ),
      ),
    );

    expect(await api.loyaltyPoints(session), isNull);
  });

  test('change password posts the current and new password', () async {
    final api = GymApi(
      baseUrl: 'https://gym.example',
      database: 'parami_demo',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://gym.example/gym/api/user/change_password',
        );
        expect(request.headers['cookie'], 'session_id=session-123');
        expect(request.headers['x-odoo-database'], 'parami_demo');
        expect(jsonDecode(request.body), <String, dynamic>{
          'user_id': 46,
          'old_password': 'current-password',
          'new_password': 'new-password',
        });
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'success',
            'data': <String, dynamic>{'user_id': 46},
          }),
          200,
        );
      }),
    );

    await api.changePassword(
      session: session,
      oldPassword: 'current-password',
      newPassword: 'new-password',
    );
  });

  test('change password surfaces an incorrect current password', () async {
    final api = GymApi(
      baseUrl: 'https://gym.example',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'error',
            'error': 'Current password is incorrect',
          }),
          401,
        ),
      ),
    );

    expect(
      api.changePassword(
        session: session,
        oldPassword: 'wrong-password',
        newPassword: 'new-password',
      ),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.message,
              'message',
              'Current password is incorrect',
            )
            .having((error) => error.statusCode, 'statusCode', 401),
      ),
    );
  });
}
