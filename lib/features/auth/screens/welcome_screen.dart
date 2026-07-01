import 'package:flutter/material.dart';
import 'package:nbts/core/routes/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop_rounded, color: scheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'NBTS',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              Text(
                'Donate blood.',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 40,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'Save lives.',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 40,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Book donation appointments, track your donor profile, and carry your secure NBTS donor card.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 34),
              const _Feature(
                icon: Icons.person_outline_rounded,
                text: 'Create and manage your donor profile',
              ),
              const _Feature(
                icon: Icons.event_available_outlined,
                text: 'Book and view donation appointments',
              ),
              const _Feature(
                icon: Icons.qr_code_rounded,
                text: 'Carry your secure digital donor card',
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text('Create an account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

