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
      widget.fitnessClass.endDate ??
          DateTime.now().add(const Duration(days: 180)),
    );
    final initial =
        _selectedDate ?? _firstValidDateOrNull(schedule, firstDate, lastDate);
    if (initial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
      candidate = candidate.add(const Duration(days: 1));
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
          title: const Text('Booking confirmed'),
          content: const Text('Your free class has been booked successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
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
        const SnackBar(content: Text('Could not book this class right now.')),
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
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      StatusPill(
                        label: widget.isFree ? 'Free class' : 'Paid class',
                        color: widget.isFree
                            ? AppColors.mintDark
                            : AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.fitnessClass.templateName.isEmpty
                        ? widget.fitnessClass.classType
                        : widget.fitnessClass.templateName,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
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
            const SizedBox(height: 16),
            if (widget.isFree) ...[
              const SectionLabel(title: 'Book this free class'),
              const SizedBox(height: 12),
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a schedule and a matching date before booking.',
                      style: TextStyle(color: AppColors.muted, height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    if (_schedules.isEmpty)
                      const EmptyPane(
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectedSchedule == null
                                ? null
                                : _pickDate,
                            icon: const Icon(Icons.date_range_rounded),
                            label: Text(
                              _selectedDate == null
                                  ? 'Pick date'
                                  : formatDate(_selectedDate),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed:
                          (_selectedSchedule == null ||
                              _selectedDate == null ||
                              _booking)
                          ? null
                          : _book,
                      child: _booking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text('Book now'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SectionLabel(title: 'Paid class details'),
              const SizedBox(height: 12),
              const AppSurface(
                child: Text(
                  'Paid classes are shown for reference. The current API exposes enrollment history, not a paid booking endpoint.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ),
            ],
            if (_schedules.isNotEmpty) ...[
              const SizedBox(height: 16),
              const SectionLabel(title: 'Schedules'),
              const SizedBox(height: 12),
              for (final schedule in _schedules) ...[
                AppSurface(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: AppColors.mintDark,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          schedule.displayName.isEmpty
                              ? formatTimeRange(
                                  schedule.startTime,
                                  schedule.endTime,
                                )
                              : schedule.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.mintDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
