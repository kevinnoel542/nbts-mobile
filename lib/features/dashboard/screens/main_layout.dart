import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  static const _pages = <Widget>[
    DashboardScreen(),
    AppointmentsScreen(),
    FindCentersScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: _NavIcon('assets/nav/home.svg'),
              selectedIcon: _NavIcon('assets/nav/home.svg', selected: true),
              label: 'Home',
            ),
            NavigationDestination(
              icon: _NavIcon('assets/nav/calendar-clock.svg'),
              selectedIcon: _NavIcon(
                'assets/nav/reminder-appointment.svg',
                selected: true,
              ),
              label: 'Book',
            ),
            NavigationDestination(
              icon: _NavIcon('assets/nav/hospital.svg'),
              selectedIcon: _NavIcon('assets/nav/hospital.svg', selected: true),
              label: 'Centers',
            ),
            NavigationDestination(
              icon: _NavIcon('assets/nav/rectangle-vertical-history.svg'),
              selectedIcon: _NavIcon(
                'assets/nav/rectangle-vertical-history.svg',
                selected: true,
              ),
              label: 'History',
            ),
            NavigationDestination(
              icon: _NavIcon('assets/nav/circle-user.svg'),
              selectedIcon: _NavIcon(
                'assets/nav/circle-user.svg',
                selected: true,
              ),
              label: 'Profile',
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
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
