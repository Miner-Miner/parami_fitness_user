import 'package:flutter/material.dart';

import '../models/gym_models.dart';
import '../services/gym_api.dart';
import '../ui/app_theme.dart';
import '../ui/formatters.dart';
import '../ui/ui_parts.dart';

enum MemberListKind { packages, enrolled, bookedFree }

class MemberRecordsScreen extends StatefulWidget {
  const MemberRecordsScreen({
    super.key,
    required this.api,
    required this.session,
    required this.kind,
  });

  final GymApi api;
  final AuthSession session;
  final MemberListKind kind;

  @override
  State<MemberRecordsScreen> createState() => _MemberRecordsScreenState();
}

class _MemberRecordsScreenState extends State<MemberRecordsScreen> {
  late Future<Object?> _future = _load();

  Future<Object?> _load() {
    switch (widget.kind) {
      case MemberListKind.packages:
        return widget.api.packages(widget.session);
      case MemberListKind.enrolled:
        return widget.api.enrolledClasses(widget.session);
      case MemberListKind.bookedFree:
        return widget.api.bookedFreeClasses(widget.session);
    }
  }

  String get _title {
    switch (widget.kind) {
      case MemberListKind.packages:
        return 'Packages';
      case MemberListKind.enrolled:
        return 'Enrolled classes';
      case MemberListKind.bookedFree:
        return 'Booked free classes';
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              FutureBuilder<Object?>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 44),
                      child: LoadingPane(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 44),
                      child: ErrorPane(
                        message: snapshot.error.toString(),
                        onRetry: _refresh,
                      ),
                    );
                  }
                  final data = snapshot.data;
                  if (data == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 44),
                      child: EmptyPane(
                        icon: Icons.inbox_rounded,
                        title: 'Nothing here yet',
                        message:
                            'The API returned no records for this section.',
                      ),
                    );
                  }
                  switch (widget.kind) {
                    case MemberListKind.packages:
                      return _PackagesList(items: data as List<PackageRecord>);
                    case MemberListKind.enrolled:
                      return _EnrolledList(items: data as List<EnrolledClass>);
                    case MemberListKind.bookedFree:
                      return _BookedFreeList(items: data as List<FreeBooking>);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackagesList extends StatelessWidget {
  const _PackagesList({required this.items});

  final List<PackageRecord> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 44),
        child: EmptyPane(
          icon: Icons.card_membership_rounded,
          title: 'No packages',
          message: 'There are no packages linked to this account.',
        ),
      );
    }
    return Column(
      children: [
        for (final item in items) ...[
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusPill(
                      label: item.state.isEmpty
                          ? 'Active'
                          : titleCase(item.state),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.productType,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                _RecordRow(label: 'Start', value: formatDate(item.startDate)),
                _RecordRow(
                  label: 'Expiry',
                  value: formatDate(item.expirationDate),
                ),
                _RecordRow(
                  label: 'Sessions',
                  value: '${item.remainingSessions}/${item.totalSessions}',
                ),
                if (item.trainerName.isNotEmpty)
                  _RecordRow(label: 'Trainer', value: item.trainerName),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _EnrolledList extends StatelessWidget {
  const _EnrolledList({required this.items});

  final List<EnrolledClass> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 44),
        child: EmptyPane(
          icon: Icons.event_available_rounded,
          title: 'No enrolled classes',
          message: 'Your paid class history is empty right now.',
        ),
      );
    }
    return Column(
      children: [
        for (final item in items) ...[
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.className,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusPill(
                      label: item.state.isEmpty
                          ? 'Enrolled'
                          : titleCase(item.state),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.templateName,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                _RecordRow(label: 'Start', value: formatDate(item.dateStart)),
                _RecordRow(label: 'Instructor', value: item.instructorName),
                _RecordRow(
                  label: 'Sessions',
                  value: '${item.sessionsDone}/${item.sessionTotal} used',
                ),
                _RecordRow(
                  label: 'Remaining',
                  value: '${item.sessionsRemaining}',
                ),
                if (item.timetable.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Timetable',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final session in item.timetable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${formatDate(session.date)} · ${formatTimeRange(session.startTime, session.endTime)} · ${session.instructorName}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BookedFreeList extends StatelessWidget {
  const _BookedFreeList({required this.items});

  final List<FreeBooking> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 44),
        child: EmptyPane(
          icon: Icons.event_note_rounded,
          title: 'No free bookings',
          message: 'Booked free-class records will appear here.',
        ),
      );
    }
    return Column(
      children: [
        for (final item in items) ...[
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.className,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusPill(
                      label: item.state.isEmpty
                          ? 'Booked'
                          : titleCase(item.state),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (item.templateName.isNotEmpty)
                  Text(
                    item.templateName,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                const SizedBox(height: 12),
                _RecordRow(label: 'Date', value: formatDate(item.date)),
                if (item.scheduleDisplay.isNotEmpty)
                  _RecordRow(label: 'Schedule', value: item.scheduleDisplay),
                if (item.notes.isNotEmpty)
                  _RecordRow(label: 'Notes', value: item.notes),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
