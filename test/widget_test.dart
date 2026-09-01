import 'package:flutter_test/flutter_test.dart';

import 'package:parami_fitness_user/models/gym_models.dart';
import 'package:parami_fitness_user/ui/formatters.dart';

void main() {
  test('session QR payload is stable', () {
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

    expect(session.qrPayload, '{"member_id":"MEM-00025","user_id":46}');
  });

  test('formatMoney inserts separators', () {
    expect(formatMoney(1234567), 'MMK 1,234,567');
  });
}
