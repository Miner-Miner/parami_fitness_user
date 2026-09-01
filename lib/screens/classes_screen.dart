import 'package:flutter/material.dart';

import '../models/gym_models.dart';
import '../services/gym_api.dart';
import '../ui/app_theme.dart';
import '../ui/formatters.dart';
import '../ui/ui_parts.dart';
import 'class_detail_screen.dart';

enum _ClassFilter { free, paid }

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key, required this.api, required this.session});

  final GymApi api;
  final AuthSession session;

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  _ClassFilter _filter = _ClassFilter.free;
  late Future<List<FitnessClass>> _future = _load();

  Future<List<FitnessClass>> _load() {
    return _filter == _ClassFilter.free
        ? widget.api.freeClasses(widget.session)
        : widget.api.paidClasses(widget.session);
  }

  void _setFilter(_ClassFilter filter) {
    if (_filter == filter) {
      return;
    }
    setState(() {
      _filter = filter;
      _future = _load();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Text(
              'Classes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Switch between free and paid classes. Free class cards open a booking flow.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            SegmentedButton<_ClassFilter>(
              segments: const [
                ButtonSegment(
                  value: _ClassFilter.free,
                  icon: Icon(Icons.local_offer_rounded),
                  label: Text('Free'),
                ),
                ButtonSegment(
                  value: _ClassFilter.paid,
                  icon: Icon(Icons.workspace_premium_rounded),
                  label: Text('Paid'),
                ),
              ],
              selected: <_ClassFilter>{_filter},
              onSelectionChanged: (selection) => _setFilter(selection.first),
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<FitnessClass>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 54),
                    child: LoadingPane(),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 42),
                    child: ErrorPane(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    ),
                  );
                }
                final items = snapshot.data ?? const <FitnessClass>[];
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 42),
                    child: EmptyPane(
                      icon: _filter == _ClassFilter.free
                          ? Icons.sports_gymnastics_rounded
                          : Icons.workspace_premium_rounded,
                      title: _filter == _ClassFilter.free
                          ? 'No free classes right now'
                          : 'No paid classes right now',
                      message: 'Check again later or pull to refresh.',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final item in items) ...[
                      _ClassCard(
                        item: item,
                        isFree: _filter == _ClassFilter.free,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ClassDetailScreen(
                                api: widget.api,
                                session: widget.session,
                                fitnessClass: item,
                                isFree: _filter == _ClassFilter.free,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.item,
    required this.isFree,
    required this.onTap,
  });

  final FitnessClass item;
  final bool isFree;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                label: isFree ? 'Free' : 'Paid',
                color: isFree ? AppColors.mintDark : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.templateName.isEmpty ? item.classType : item.templateName,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.event_rounded,
                text: formatDateRange(item.startDate, item.endDate),
              ),
              _InfoChip(icon: Icons.person_rounded, text: item.instructorName),
              _InfoChip(
                icon: Icons.people_alt_rounded,
                text: '${item.sessionCount}/${item.capacity} sessions',
              ),
              _InfoChip(
                icon: Icons.payments_rounded,
                text: formatMoney(item.fee),
              ),
            ],
          ),
          if (item.schedules.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final schedule in item.schedules)
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    text: schedule.displayName.isEmpty
                        ? formatTimeRange(schedule.startTime, schedule.endTime)
                        : schedule.displayName,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

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
