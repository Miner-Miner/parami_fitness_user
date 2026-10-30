import 'package:flutter/material.dart';

import '../models/gym_models.dart';
import '../services/gym_api.dart';
import '../ui/app_theme.dart';
import '../ui/formatters.dart';
import '../ui/ui_parts.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({
    super.key,
    required this.api,
    required this.session,
    required this.fitnessClass,
    required this.isFree,
  });

  final GymApi api;
  final AuthSession session;
  final FitnessClass fitnessClass;
  final bool isFree;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  ClassSchedule? _selectedSchedule;
  DateTime? _selectedDate;
  bool _booking = false;

  List<ClassSchedule> get _schedules => widget.fitnessClass.schedules;

  Future<void> _pickDate() async {
    final schedule = _selectedSchedule;
    if (schedule == null) {
      return;
    }

    final firstDate = DateUtils.dateOnly(
      widget.fitnessClass.startDate ?? DateTime.now(),
    );
    final lastDate = DateUtils.dateOnly(
      widget.fitnessClass.endDate ?? DateTime.now().add(Duration(days: 180)),
    );
    final initial =
        _selectedDate ?? _firstValidDateOrNull(schedule, firstDate, lastDate);
    if (initial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No valid date is available for this schedule.'),
        ),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (date) =>
          date.weekday == schedule.dartWeekday &&
          !date.isBefore(DateUtils.dateOnly(firstDate)) &&
          !date.isAfter(DateUtils.dateOnly(lastDate)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(picked);
      });
    }
  }

  DateTime? _firstValidDateOrNull(
    ClassSchedule schedule,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    var candidate = DateUtils.dateOnly(firstDate);
    while (candidate.weekday != schedule.dartWeekday) {
      candidate = candidate.add(Duration(days: 1));
    }
    if (candidate.isAfter(DateUtils.dateOnly(lastDate))) {
      return null;
    }
    return candidate;
  }

  Future<void> _book() async {
    final schedule = _selectedSchedule;
    final date = _selectedDate;
    if (schedule == null || date == null || _booking) {
      return;
    }

    setState(() {
      _booking = true;
    });

    try {
      await widget.api.bookFreeClass(
        session: widget.session,
        fitnessClass: widget.fitnessClass,
        schedule: schedule,
        date: date,
      );
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Booking confirmed'),
          content: Text('Your free class has been booked successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not book this class right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _booking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fitnessClass.name)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.fitnessClass.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.of(context).ink,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      StatusPill(
                        label: widget.isFree ? 'Free class' : 'Paid class',
                        color: widget.isFree
                            ? AppColors.of(context).mintDark
                            : AppColors.of(context).warning,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.fitnessClass.templateName.isEmpty
                        ? widget.fitnessClass.classType
                        : widget.fitnessClass.templateName,
                    style: TextStyle(color: AppColors.of(context).muted),
                  ),
                  SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DetailChip(
                        icon: Icons.event_rounded,
                        text: formatDateRange(
                          widget.fitnessClass.startDate,
                          widget.fitnessClass.endDate,
                        ),
                      ),
                      _DetailChip(
                        icon: Icons.person_rounded,
                        text: widget.fitnessClass.instructorName,
                      ),
                      _DetailChip(
                        icon: Icons.people_alt_rounded,
                        text:
                            '${widget.fitnessClass.sessionCount}/${widget.fitnessClass.capacity}',
                      ),
                      _DetailChip(
                        icon: Icons.payments_rounded,
                        text: formatMoney(widget.fitnessClass.fee),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            if (widget.isFree) ...[
              SectionLabel(title: 'Book this free class'),
              SizedBox(height: 12),
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a schedule and a matching date before booking.',
                      style: TextStyle(
                        color: AppColors.of(context).muted,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_schedules.isEmpty)
                      EmptyPane(
                        icon: Icons.event_busy_rounded,
                        title: 'No schedule found',
                        message: 'This class does not expose a schedule yet.',
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final schedule in _schedules)
                            ChoiceChip(
                              label: Text(
                                schedule.displayName.isEmpty
                                    ? formatTimeRange(
                                        schedule.startTime,
                                        schedule.endTime,
                                      )
                                    : schedule.displayName,
                              ),
                              selected: _selectedSchedule?.id == schedule.id,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSchedule = selected
                                      ? schedule
                                      : null;
                                  _selectedDate = null;
                                });
                              },
                            ),
                        ],
                      ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectedSchedule == null
                                ? null
                                : _pickDate,
                            icon: Icon(Icons.date_range_rounded),
                            label: Text(
                              _selectedDate == null
                                  ? 'Pick date'
                                  : formatDate(_selectedDate),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    FilledButton(
                      onPressed:
                          (_selectedSchedule == null ||
                              _selectedDate == null ||
                              _booking)
                          ? null
                          : _book,
                      child: _booking
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : Text('Book now'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SectionLabel(title: 'Paid class details'),
              SizedBox(height: 12),
              AppSurface(
                child: Text(
                  'Paid classes are shown for reference. The current API exposes enrollment history, not a paid booking endpoint.',
                  style: TextStyle(
                    color: AppColors.of(context).muted,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            if (_schedules.isNotEmpty) ...[
              SizedBox(height: 16),
              SectionLabel(title: 'Schedules'),
              SizedBox(height: 12),
              for (final schedule in _schedules) ...[
                AppSurface(
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: AppColors.of(context).mintDark,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          schedule.displayName.isEmpty
                              ? formatTimeRange(
                                  schedule.startTime,
                                  schedule.endTime,
                                )
                              : schedule.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.of(context).ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.of(context).canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.of(context).mintDark),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: AppColors.of(context).ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
