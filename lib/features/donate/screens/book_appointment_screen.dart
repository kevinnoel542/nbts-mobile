import 'package:flutter/material.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/donation_center.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const _slots = [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 9, minute: 30),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 30),
    TimeOfDay(hour: 16, minute: 0),
  ];

  DonationCenter? _selectedCenter;
  DateTime? _selectedDate;
  int? _selectedSlot;
  bool _readArgs = false;
  bool _submitting = false;
  String? _formError;
  late Future<List<DonationCenter>> _centersFuture;

  @override
  void initState() {
    super.initState();
    _centersFuture = Services.instance.centers.fetchAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DonationCenter) {
      _selectedCenter = args;
    }
    _readArgs = true;
  }

  Future<void> _refreshCenters() async {
    setState(() {
      _centersFuture = Services.instance.centers.fetchAll();
    });
    await _centersFuture;
  }

  Future<void> _submit() async {
    final center = _selectedCenter;
    final date = _selectedDate;
    final slotIndex = _selectedSlot;
    if (center == null || date == null || slotIndex == null) {
      setState(() => _formError = 'Choose a center, date, and time.');
      return;
    }

    final slot = _slots[slotIndex];
    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      slot.hour,
      slot.minute,
    );

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      await Services.instance.appointments.book(
        centerId: center.id,
        scheduledAt: scheduledAt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked.')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.firstError());
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Could not book appointment.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canConfirm = _selectedCenter != null &&
        _selectedDate != null &&
        _selectedSlot != null &&
        !_submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Book donation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          const _Step(number: '1', title: 'Center'),
          const SizedBox(height: AppSpacing.sm),
          _CenterPicker(
            selectedCenter: _selectedCenter,
            centersFuture: _centersFuture,
            submitting: _submitting,
            onRefresh: _refreshCenters,
            onChanged: (center) => setState(() => _selectedCenter = center),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _Step(number: '2', title: 'Date'),
          const SizedBox(height: AppSpacing.sm),
          _DatePickerStrip(
            selectedDate: _selectedDate,
            submitting: _submitting,
            onChanged: (date) => setState(() => _selectedDate = date),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _Step(number: '3', title: 'Time'),
          const SizedBox(height: AppSpacing.sm),
          _SlotGrid(
            selectedSlot: _selectedSlot,
            submitting: _submitting,
            onChanged: (slot) => setState(() => _selectedSlot = slot),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Have a meal and water 2 hours before donating.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (_formError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: scheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formError!,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: canConfirm ? _submit : null,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Confirm appointment'),
          ),
        ],
      ),
    );
  }
}

class _CenterPicker extends StatelessWidget {
  const _CenterPicker({
    required this.selectedCenter,
    required this.centersFuture,
    required this.submitting,
    required this.onRefresh,
    required this.onChanged,
  });

  final DonationCenter? selectedCenter;
  final Future<List<DonationCenter>> centersFuture;
  final bool submitting;
  final RefreshCallback onRefresh;
  final ValueChanged<DonationCenter?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<DonationCenter>>(
      future: centersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            selectedCenter == null) {
          return const AppCard(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError && selectedCenter == null) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : 'Could not load donation centers.';
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Centers unavailable',
                  message: message,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: submitting ? null : () => onRefresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final centers = _mergeSelection(
          selectedCenter,
          snapshot.data ?? const <DonationCenter>[],
        );

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DropdownButtonFormField<DonationCenter>(
            initialValue: _selectedValue(selectedCenter, centers),
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Donation center',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            hint: const Text('Choose center'),
            items: [
              for (final center in centers)
                DropdownMenuItem(
                  value: center,
                  child: Text(
                    _centerLabel(center),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: submitting ? null : onChanged,
            selectedItemBuilder: (_) => [
              for (final center in centers)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    center.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static List<DonationCenter> _mergeSelection(
    DonationCenter? selected,
    List<DonationCenter> centers,
  ) {
    if (selected == null || centers.any((c) => c.id == selected.id)) {
      return centers;
    }
    return [selected, ...centers];
  }

  static DonationCenter? _selectedValue(
    DonationCenter? selected,
    List<DonationCenter> centers,
  ) {
    if (selected == null) return null;
    for (final center in centers) {
      if (center.id == selected.id) return center;
    }
    return null;
  }

  static String _centerLabel(DonationCenter center) {
    final address = center.address;
    if (address == null || address.isEmpty) return center.name;
    return '${center.name} - $address';
  }
}

class _DatePickerStrip extends StatelessWidget {
  const _DatePickerStrip({
    required this.selectedDate,
    required this.submitting,
    required this.onChanged,
  });

  final DateTime? selectedDate;
  final bool submitting;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day).add(
        Duration(days: i),
      ),
    );

    return Row(
      children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: submitting ? null : () => onChanged(days[i]),
              child: Container(
                margin: EdgeInsets.only(right: i == days.length - 1 ? 0 : 6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _sameDay(selectedDate, days[i])
                      ? scheme.primary
                      : scheme.surfaceContainer,
                  borderRadius: AppRadius.chip,
                  border: Border.all(
                    color: _sameDay(selectedDate, days[i])
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _weekday(days[i]),
                      style: TextStyle(
                        color: _sameDay(selectedDate, days[i])
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${days[i].day}',
                      style: TextStyle(
                        color: _sameDay(selectedDate, days[i])
                            ? scheme.onPrimary
                            : scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static bool _sameDay(DateTime? a, DateTime b) {
    return a?.year == b.year && a?.month == b.month && a?.day == b.day;
  }

  static String _weekday(DateTime d) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[d.weekday - 1];
  }
}

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.selectedSlot,
    required this.submitting,
    required this.onChanged,
  });

  final int? selectedSlot;
  final bool submitting;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: List.generate(_BookAppointmentScreenState._slots.length, (i) {
        final selected = selectedSlot == i;
        return GestureDetector(
          onTap: submitting ? null : () => onChanged(i),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? scheme.primary : scheme.surfaceContainer,
              borderRadius: AppRadius.chip,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Text(
              _formatTime(_BookAppointmentScreenState._slots[i]),
              style: TextStyle(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  static String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
