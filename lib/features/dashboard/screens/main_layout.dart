import 'package:flutter/material.dart';
import 'package:nbts/core/localization/app_language.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/features/appointments/screens/appointments_screen.dart';
import 'package:nbts/features/dashboard/screens/dashboard_screen.dart';
import 'package:nbts/features/donate/screens/find_centers_screen.dart';
import 'package:nbts/features/history/screens/history_screen.dart';
import 'package:nbts/features/profile/screens/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;
  int _previousIndex = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    AppointmentsScreen(),
    FindCentersScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _ensureAuthorized();
  }

  Future<void> _ensureAuthorized() async {
    try {
      final user = await Services.instance.auth.validateSession();
      if (!mounted) return;
      if (user == null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome,
          (_) => false,
        );
        return;
      }
      if (!user.isDonorProfileComplete) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.completeProfile,
          (_) => false,
        );
      }
    } catch (_) {
      // Keep the current page during temporary network/server errors.
    }
  }

  void _selectDestination(int index) {
    if (index == _index) return;
    setState(() {
      _previousIndex = _index;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final forward = _index >= _previousIndex;
          final beginOffset = Offset(forward ? 0.08 : -0.08, 0);
          final slide = Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey<int>(_index), child: _pages[_index]),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _selectDestination,
          destinations: [
            NavigationDestination(
              icon: const _NavIcon('assets/nav/home.svg'),
              selectedIcon: const _NavIcon(
                'assets/nav/home.svg',
                selected: true,
              ),
              label: context.t('nav.home'),
            ),
            NavigationDestination(
              icon: const _NavIcon('assets/nav/calendar-clock.svg'),
              selectedIcon: const _NavIcon(
                'assets/nav/reminder-appointment.svg',
                selected: true,
              ),
              label: context.t('nav.book'),
            ),
            NavigationDestination(
              icon: const _NavIcon('assets/nav/hospital.svg'),
              selectedIcon: const _NavIcon(
                'assets/nav/hospital.svg',
                selected: true,
              ),
              label: context.t('nav.centers'),
            ),
            NavigationDestination(
              icon: const _NavIcon('assets/nav/rectangle-vertical-history.svg'),
              selectedIcon: const _NavIcon(
                'assets/nav/rectangle-vertical-history.svg',
                selected: true,
              ),
              label: context.t('nav.history'),
            ),
            NavigationDestination(
              icon: const _NavIcon('assets/nav/circle-user.svg'),
              selectedIcon: const _NavIcon(
                'assets/nav/circle-user.svg',
                selected: true,
              ),
              label: context.t('nav.profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon(this.asset, {this.selected = false});

  final String asset;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return SvgPicture.asset(
      asset,
      width: 18,
      height: 18,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
