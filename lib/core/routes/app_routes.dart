import 'package:flutter/material.dart';
import 'package:nbts/features/auth/screens/login_screen.dart';
import 'package:nbts/features/auth/screens/register_screen.dart';
import 'package:nbts/features/auth/screens/complete_profile_screen.dart';
import 'package:nbts/features/auth/screens/welcome_screen.dart';
import 'package:nbts/features/dashboard/screens/donor_card_screen.dart';
import 'package:nbts/features/dashboard/screens/main_layout.dart';
import 'package:nbts/features/donate/screens/book_appointment_screen.dart';
import 'package:nbts/features/donate/screens/find_centers_screen.dart';
import 'package:nbts/features/history/screens/history_screen.dart';
import 'package:nbts/features/notifications/screens/notifications_screen.dart';
import 'package:nbts/features/profile/screens/profile_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String completeProfile = '/complete-profile';
  static const String dashboard = '/dashboard';
  static const String donorCard = '/donor-card';
  static const String bookAppointment = '/book-appointment';
  static const String centers = '/centers';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> get routes => {
    welcome: (context) => const WelcomeScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    completeProfile: (context) => const CompleteProfileScreen(),
    dashboard: (context) => const MainLayout(),
    donorCard: (context) => const DonorCardScreen(),
    bookAppointment: (context) => const BookAppointmentScreen(),
    centers: (context) => const FindCentersScreen(),
    history: (context) => const HistoryScreen(),
    profile: (context) => const ProfileScreen(),
    notifications: (context) => const NotificationsScreen(),
  };
}
