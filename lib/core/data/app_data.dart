import 'package:flutter/material.dart';

enum EligibilityStatus { eligible, conditional, deferred }

class DonationCenter {
  const DonationCenter({
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.hours,
    required this.phone,
    required this.waitTime,
    required this.capacityLabel,
    required this.services,
    required this.isOpen,
  });

  final String name;
  final String address;
  final double distanceKm;
  final String hours;
  final String phone;
  final String waitTime;
  final String capacityLabel;
  final List<String> services;
  final bool isOpen;
}

class DonationRecord {
  const DonationRecord({
    required this.month,
    required this.day,
    required this.center,
    required this.time,
    required this.type,
    required this.volumeMl,
    required this.status,
  });

  final String month;
  final String day;
  final String center;
  final String time;
  final String type;
  final int volumeMl;
  final String status;
}

class EducationArticle {
  const EducationArticle({
    required this.title,
    required this.category,
    required this.summary,
    required this.icon,
  });

  final String title;
  final String category;
  final String summary;
  final IconData icon;
}

class AppData {
  static const donorName = 'Donor profile pending';
  static const donorId = 'Pending NBTS ID';
  static const bloodType = 'Pending';
  static const preferredCenter = 'No center selected';
  static const nextEligibleDate = 'Pending medical verification';
  static const String? nextAppointment = null;
  static const totalDonations = 0;
  static const totalVolumeMl = 0;
  static const loyaltyPoints = 0;
  static const loyaltyTier = 'Pending';

  static const centers = <DonationCenter>[];

  static const donations = <DonationRecord>[];

  static const articles = [
    EducationArticle(
      title: 'Before You Donate',
      category: 'Health Tip',
      summary:
          'Eat well, hydrate, carry ID, and avoid heavy exercise right after donating.',
      icon: Icons.restaurant,
    ),
    EducationArticle(
      title: 'Why 56 Days Matters',
      category: 'Eligibility',
      summary:
          'The waiting period protects donor health while red blood cells recover.',
      icon: Icons.calendar_month,
    ),
    EducationArticle(
      title: 'Urgent Blood Requests',
      category: 'Alert',
      summary:
          'Urgent blood type requests will appear here after NBTS publishes verified alerts.',
      icon: Icons.campaign,
    ),
  ];
}
