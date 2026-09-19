import 'dart:convert';

Map<String, dynamic> asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

List<Object?> asJsonList(Object? value) {
  return value is List ? List<Object?>.from(value) : const <Object?>[];
}

String textValue(Object? value, [String fallback = '']) {
  if (value == null || value == false) {
    return fallback;
  }
  return value.toString();
}

int intValue(Object? value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(textValue(value)) ?? fallback;
}

double doubleValue(Object? value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(textValue(value)) ?? fallback;
}

bool boolValue(Object? value, [bool fallback = false]) {
  if (value is bool) {
    return value;
  }
  return textValue(value).toLowerCase() == 'true' ? true : fallback;
}

DateTime? apiDate(Object? value) {
  final date = textValue(value);
  if (date.isEmpty) {
    return null;
  }
  return DateTime.tryParse(date);
}

class AuthSession {
  const AuthSession({
    required this.sessionId,
    required this.userId,
    required this.name,
    required this.login,
    required this.userRole,
    required this.memberId,
    required this.partnerId,
    required this.isGymAdmin,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      sessionId: textValue(json['session_id']),
      userId: intValue(json['user_id']),
      name: textValue(json['name'], 'Member'),
      login: textValue(json['login']),
      userRole: textValue(json['user_role'], 'customer'),
      memberId: textValue(json['member_id']),
      partnerId: intValue(json['partner_id']),
      isGymAdmin: boolValue(json['is_gym_admin']),
    );
  }

  final String sessionId;
  final int userId;
  final String name;
  final String login;
  final String userRole;
  final String memberId;
  final int partnerId;
  final bool isGymAdmin;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'session_id': sessionId,
    'user_id': userId,
    'name': name,
    'login': login,
    'user_role': userRole,
    'member_id': memberId,
    'partner_id': partnerId,
    'is_gym_admin': isGymAdmin,
  };

  String get qrPayload =>
      jsonEncode(<String, dynamic>{'member_id': memberId, 'user_id': userId});
}

class MemberProfile {
  const MemberProfile({
    required this.userId,
    required this.name,
    required this.login,
    required this.email,
    required this.phone,
    required this.street,
    required this.city,
    required this.memberId,
    required this.userRole,
  });

  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    return MemberProfile(
      userId: intValue(json['user_id']),
      name: textValue(json['name'], 'Member'),
      login: textValue(json['login']),
      email: textValue(json['email']),
      phone: textValue(json['phone']),
      street: textValue(json['street']),
      city: textValue(json['city']),
      memberId: textValue(json['member_id']),
      userRole: textValue(json['user_role'], 'customer'),
    );
  }

  final int userId;
  final String name;
  final String login;
  final String email;
  final String phone;
  final String street;
  final String city;
  final String memberId;
  final String userRole;
}

class LoyaltyPoints {
  const LoyaltyPoints({
    required this.programId,
    required this.programName,
    required this.points,
    required this.code,
  });

  factory LoyaltyPoints.fromJson(Map<String, dynamic> json) {
    return LoyaltyPoints(
      programId: intValue(json['program_id']),
      programName: textValue(json['program_name']),
      points: doubleValue(json['points']),
      code: textValue(json['code']),
    );
  }

  final int programId;
  final String programName;
  final double points;
  final String code;

  String get displayValue {
    final formattedPoints = points.truncateToDouble() == points
        ? points.toStringAsFixed(0)
        : points.toString();
    return programName.isEmpty
        ? '$formattedPoints pts'
        : '$formattedPoints pts · $programName';
  }
}

class ClassSchedule {
  const ClassSchedule({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.displayName,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: intValue(json['id']),
      dayOfWeek: intValue(json['day_of_week']),
      startTime: doubleValue(json['start_time']),
      endTime: doubleValue(json['end_time']),
      displayName: textValue(json['display_name']),
    );
  }

  final int id;

  /// The API numbers Monday as 0; Dart numbers Monday as 1.
  final int dayOfWeek;
  final double startTime;
  final double endTime;
  final String displayName;

  int get dartWeekday => dayOfWeek + 1;
}

class FitnessClass {
  const FitnessClass({
    required this.id,
    required this.name,
    required this.classType,
    required this.templateName,
    required this.startDate,
    required this.endDate,
    required this.capacity,
    required this.sessionCount,
    required this.fee,
    required this.instructorName,
    required this.schedules,
  });

  factory FitnessClass.fromJson(Map<String, dynamic> json) {
    return FitnessClass(
      id: intValue(json['id']),
      name: textValue(json['name'], 'Class'),
      classType: textValue(json['class_type']),
      templateName: textValue(json['template_name']),
      startDate: apiDate(json['start_date']),
      endDate: apiDate(json['end_date']),
      capacity: intValue(json['capacity']),
      sessionCount: intValue(json['session_count']),
      fee: doubleValue(json['fee']),
      instructorName: textValue(json['instructor_name'], 'Gym instructor'),
      schedules: asJsonList(
        json['schedule'],
      ).map(asJsonMap).map(ClassSchedule.fromJson).toList(growable: false),
    );
  }

  final int id;
  final String name;
  final String classType;
  final String templateName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int capacity;
  final int sessionCount;
  final double fee;
  final String instructorName;
  final List<ClassSchedule> schedules;

  bool get isFree => classType == 'free';
}

class PackageRecord {
  const PackageRecord({
    required this.id,
    required this.productName,
    required this.productType,
    required this.startDate,
    required this.expirationDate,
    required this.totalSessions,
    required this.remainingSessions,
    required this.trainerName,
    required this.state,
  });

  factory PackageRecord.fromJson(Map<String, dynamic> json) {
    return PackageRecord(
      id: intValue(json['id']),
      productName: textValue(json['product_name'], 'Package'),
      productType: textValue(json['product_type']),
      startDate: apiDate(json['start_date']),
      expirationDate: apiDate(json['expiration_date']),
      totalSessions: intValue(json['total_sessions']),
      remainingSessions: intValue(json['remaining_sessions']),
      trainerName: textValue(json['trainer_name']),
      state: textValue(json['state']),
    );
  }

  final int id;
  final String productName;
  final String productType;
  final DateTime? startDate;
  final DateTime? expirationDate;
  final int totalSessions;
  final int remainingSessions;
  final String trainerName;
  final String state;
}

class FreeBooking {
  const FreeBooking({
    required this.id,
    required this.className,
    required this.templateName,
    required this.scheduleDisplay,
    required this.date,
    required this.state,
    required this.notes,
  });

  factory FreeBooking.fromJson(Map<String, dynamic> json) {
    return FreeBooking(
      id: intValue(json['id']),
      className: textValue(json['class_name'], 'Free class'),
      templateName: textValue(json['template_name']),
      scheduleDisplay: textValue(json['schedule_display']),
      date: apiDate(json['date']),
      state: textValue(json['state']),
      notes: textValue(json['notes']),
    );
  }

  final int id;
  final String className;
  final String templateName;
  final String scheduleDisplay;
  final DateTime? date;
  final String state;
  final String notes;
}

class EnrolledClassSession {
  const EnrolledClassSession({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.instructorName,
    required this.state,
  });

  factory EnrolledClassSession.fromJson(Map<String, dynamic> json) {
    return EnrolledClassSession(
      date: apiDate(json['date']),
      startTime: doubleValue(json['start_time']),
      endTime: doubleValue(json['end_time']),
      instructorName: textValue(json['instructor_name']),
      state: textValue(json['state']),
    );
  }

  final DateTime? date;
  final double startTime;
  final double endTime;
  final String instructorName;
  final String state;
}

class EnrolledClass {
  const EnrolledClass({
    required this.id,
    required this.className,
    required this.templateName,
    required this.dateStart,
    required this.sessionTotal,
    required this.sessionsDone,
    required this.sessionsRemaining,
    required this.state,
    required this.instructorName,
    required this.timetable,
  });

  factory EnrolledClass.fromJson(Map<String, dynamic> json) {
    return EnrolledClass(
      id: intValue(json['id']),
      className: textValue(json['class_name'], 'Paid class'),
      templateName: textValue(json['template_name']),
      dateStart: apiDate(json['date_start']),
      sessionTotal: intValue(json['session_total']),
      sessionsDone: intValue(json['sessions_done']),
      sessionsRemaining: intValue(json['sessions_remaining']),
      state: textValue(json['state']),
      instructorName: textValue(json['instructor_name']),
      timetable: asJsonList(json['timetable'])
          .map(asJsonMap)
          .map(EnrolledClassSession.fromJson)
          .toList(growable: false),
    );
  }

  final int id;
  final String className;
  final String templateName;
  final DateTime? dateStart;
  final int sessionTotal;
  final int sessionsDone;
  final int sessionsRemaining;
  final String state;
  final String instructorName;
  final List<EnrolledClassSession> timetable;
}
