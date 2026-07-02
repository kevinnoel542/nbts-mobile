import 'package:flutter/material.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/appointment.dart';
import 'package:nbts/core/data/models/appointment_slot.dart';
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
  static const _fallbackSlots = [
    AppointmentSlot(time: TimeOfDay(hour: 8, minute: 0)),
    AppointmentSlot(time: TimeOfDay(hour: 9, minute: 30)),
    AppointmentSlot(time: TimeOfDay(hour: 11, minute: 0)),
    AppointmentSlot(time: TimeOfDay(hour: 13, minute: 0)),
    AppointmentSlot(time: TimeOfDay(hour: 14, minute: 30)),
    AppointmentSlot(time: TimeOfDay(hour: 16, minute: 0)),
  ];

  DonationCenter? _selectedCenter;
  DateTime? _selectedDate;
  AppointmentSlot? _selectedSlot;
  Future<_SlotOptions>? _slotsFuture;
  Appointment? _rescheduleAppointment;
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
    } else if (args is Appointment) {
      _rescheduleAppointment = args;
      if (args.centerId != null) {
        _selectedCenter = DonationCenter(
          id: args.centerId!,
          name: args.centerName ?? 'Selected center',
        );
      }
      final scheduledAt = args.scheduledAt;
      if (scheduledAt != null) {
        _selectedDate = DateTime(
          scheduledAt.year,
          scheduledAt.month,
          scheduledAt.day,
        );
        _selectedSlot = AppointmentSlot(
          time: TimeOfDay(hour: scheduledAt.hour, minute: scheduledAt.minute),
        );
      }
    }
    _readArgs = true;
    _reloadSlots();
  }

  Future<void> _refreshCenters() async {
    setState(() {
      _centersFuture = Services.instance.centers.fetchAll();
    });
    await _centersFuture;
  }

  void _handleCenterChanged(DonationCenter? center) {
    setState(() {
      _selectedCenter = center;
      _selectedSlot = null;
      _formError = null;
      _reloadSlots();
    });
  }

  void _handleDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
      _formError = null;
      _reloadSlots();
    });
  }

  void _reloadSlots() {
    final center = _selectedCenter;
    final date = _selectedDate;
    if (center == null || date == null) {
      _slotsFuture = null;
      return;
    }
    _slotsFuture = _fetchSlots(center: center, date: date);
  }

  Future<_SlotOptions> _fetchSlots({
    required DonationCenter center,
    required DateTime date,
  }) async {
    try {
      final slots = await Services.instance.appointments.fetchSlots(
        centerId: center.id,
        date: date,
      );
      if (slots.isEmpty) return const _SlotOptions.fallback();
      return _SlotOptions(slots: slots, usingFallback: false);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        return const _SlotOptions.fallback();
      }
      rethrow;
    }
  }

  Future<void> _submit() async {
    final center = _selectedCenter;
    final date = _selectedDate;
    final slot = _selectedSlot;
    if (center == null || date == null || slot == null) {
      setState(() => _formError = 'Choose a center, date, and time.');
      return;
    }
    if (!slot.available) {
      setState(() => _formError = slot.reason ?? 'This time is not available.');
      return;
    }

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      slot.time.hour,
      slot.time.minute,
    );

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      final reschedule = _rescheduleAppointment;
      if (reschedule == null) {
        final active = await Services.instance.appointments.fetchUpcoming();
        if (active != null) {
          if (!mounted) return;
          setState(
            () => _formError =
                'You already have an active appointment. Reschedule or cancel it first.',
          );
          return;
        }
        await Services.instance.appointments.book(
          centerId: center.id,
          scheduledAt: scheduledAt,
        );
      } else {
        await Services.instance.appointments.reschedule(
          appointmentId: reschedule.id,
          centerId: center.id,
          scheduledAt: scheduledAt,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _rescheduleAppointment == null
                ? 'Appointment booked.'
                : 'Appointment rescheduled.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.firstError());
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _formError = _rescheduleAppointment == null
            ? 'Could not book appointment.'
            : 'Could not reschedule appointment.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canConfirm =
        _selectedCenter != null &&
        _selectedDate != null &&
        _selectedSlot != null &&
        _selectedSlot!.available &&
        !_submitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _rescheduleAppointment == null
              ? 'Book donation'
              : 'Reschedule donation',
        ),
      ),
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
            onChanged: _handleCenterChanged,
          ),
          const SizedBox(height: AppSpacing.xl),
          const _Step(number: '2', title: 'Date'),
          const SizedBox(height: AppSpacing.sm),
          _DatePickerStrip(
            selectedDate: _selectedDate,
            submitting: _submitting,
            onChanged: _handleDateChanged,
          ),
          const SizedBox(height: AppSpacing.xl),
          const _Step(number: '3', title: 'Time'),
          const SizedBox(height: AppSpacing.sm),
          _SlotSection(
            slotsFuture: _slotsFuture,
            selectedSlot: _selectedSlot,
            submitting: _submitting,
            hasCenterAndDate: _selectedCenter != null && _selectedDate != null,
            onRetry: () => setState(_reloadSlots),
            onChanged: (slot) => setState(() => _selectedSlot = slot),
          ),
          const SizedBox(height: AppSpacing.xl),
          _AppointmentSummary(
            center: _selectedCenter,
            date: _selectedDate,
            slot: _selectedSlot,
          ),
          const SizedBox(height: AppSpacing.md),
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
                : Text(
                    _selectedSlot == null
                        ? 'Select a time'
                        : _rescheduleAppointment == null
                        ? 'Confirm appointment'
                        : 'Save appointment',
                  ),
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
      (i) =>
          DateTime(today.year, today.month, today.day).add(Duration(days: i)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            _monthLabel(days.first),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: submitting ? null : () => onChanged(days[i]),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: i == days.length - 1 ? 0 : 6,
                    ),
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

  static String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection({
    required this.slotsFuture,
    required this.selectedSlot,
    required this.submitting,
    required this.hasCenterAndDate,
    required this.onRetry,
    required this.onChanged,
  });

  final Future<_SlotOptions>? slotsFuture;
  final AppointmentSlot? selectedSlot;
  final bool submitting;
  final bool hasCenterAndDate;
  final VoidCallback onRetry;
  final ValueChanged<AppointmentSlot> onChanged;

  @override
  Widget build(BuildContext context) {
    final future = slotsFuture;
    if (!hasCenterAndDate || future == null) {
      return const _SlotMessage(
        icon: Icons.schedule_outlined,
        message: 'Choose a center and date to see available times.',
      );
    }

    return FutureBuilder<_SlotOptions>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : 'Could not load available times.';
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'Times unavailable',
                  message: message,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: submitting ? null : onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final options = snapshot.data ?? const _SlotOptions.fallback();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (options.usingFallback) ...[
              const _SlotMessage(
                icon: Icons.info_outline_rounded,
                message:
                    'Showing standard times until this center sends live availability.',
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _SlotGrid(
              slots: options.slots,
              selectedSlot: selectedSlot,
              submitting: submitting,
              onChanged: onChanged,
            ),
          ],
        );
      },
    );
  }
}

class _SlotMessage extends StatelessWidget {
  const _SlotMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.slots,
    required this.selectedSlot,
    required this.submitting,
    required this.onChanged,
  });

  final List<AppointmentSlot> slots;
  final AppointmentSlot? selectedSlot;
  final bool submitting;
  final ValueChanged<AppointmentSlot> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.05,
      children: [
        for (final slot in slots)
          _SlotButton(
            slot: slot,
            selected: selectedSlot?.value == slot.value,
            submitting: submitting,
            scheme: scheme,
            onTap: () => onChanged(slot),
          ),
      ],
    );
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.slot,
    required this.selected,
    required this.submitting,
    required this.scheme,
    required this.onTap,
  });

  final AppointmentSlot slot;
  final bool selected;
  final bool submitting;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = submitting || !slot.available;
    final foreground = selected
        ? scheme.onPrimary
        : disabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.55)
        : scheme.onSurface;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary
              : disabled
              ? scheme.surfaceContainer.withValues(alpha: 0.55)
              : scheme.surfaceContainer,
          borderRadius: AppRadius.chip,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.value,
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!slot.available && slot.reason != null) ...[
              const SizedBox(height: 2),
              Text(
                slot.reason!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppointmentSummary extends StatelessWidget {
  const _AppointmentSummary({
    required this.center,
    required this.date,
    required this.slot,
  });

  final DonationCenter? center;
  final DateTime? date;
  final AppointmentSlot? slot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment summary',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SummaryLine(
            icon: Icons.place_outlined,
            label: 'Center',
            value: center?.name ?? 'Choose center',
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryLine(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: _formatDate(date) ?? 'Choose date',
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryLine(
            icon: Icons.schedule_outlined,
            label: 'Time',
            value: slot?.value ?? 'Choose time',
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

class _SlotOptions {
  const _SlotOptions({required this.slots, required this.usingFallback});

  const _SlotOptions.fallback()
    : slots = _BookAppointmentScreenState._fallbackSlots,
      usingFallback = true;

  final List<AppointmentSlot> slots;
  final bool usingFallback;
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
